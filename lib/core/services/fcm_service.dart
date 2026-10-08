import 'dart:async';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/firebase_options.dart';

/// Handles a push that arrives while the app is backgrounded or terminated.
///
/// Must be top-level (and `@pragma('vm:entry-point')`) because Flutter runs
/// it in a fresh isolate — one where `main()` never ran, so dotenv, GetIt and
/// the Riverpod graph do not exist. Keep it self-contained.
///
/// Android auto-displays any payload carrying a `notification` block before
/// this runs, so there is nothing to draw here for the common case.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // No usable Firebase config in this build — nothing to do.
    return;
  }
}

/// Handles Firebase Cloud Messaging integration.
/// Call [initialize] once at app startup (after Firebase.initializeApp()).
class FcmService {
  static const _tokenKey = 'fcm_token';

  /// Route carried by a notification that launched the app from a terminated
  /// state. `getInitialMessage()` resolves before the router has a navigator
  /// to push onto, so the route is parked here and the splash screen drains
  /// it once it has finished routing.
  static String? pendingRoute;

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'bagyes_rush_high_importance',
    'BagyesRIDER Notifications',
    description: 'Delivery updates and new order alerts',
    importance: Importance.high,
  );

  /// The single initialized plugin instance — exposed so other local
  /// notifications (e.g. [NavigationReturnNotifier]) reuse the same
  /// platform channel, tap-routing and Android channel setup this class
  /// already establishes in [initialize], rather than standing up a second,
  /// separately-initialized instance.
  static FlutterLocalNotificationsPlugin get localNotifications =>
      _localNotifications;

  static AndroidNotificationChannel get androidChannel => _androidChannel;

  /// Initialize FCM: request permission, configure local notifications,
  /// and set up foreground / background / tap listeners.
  ///
  /// [onNotificationTap] receives the route to navigate to when the user taps
  /// a notification. [onTokenRefresh] fires when FCM rotates the token, so the
  /// backend registration can be renewed.
  static Future<void> initialize({
    void Function(String route)? onNotificationTap,
    void Function(String token)? onTokenRefresh,
  }) async {
    // ── Permission ───────────────────────────────────────────────────────────
    await ensurePermission();

    // ── Store token ──────────────────────────────────────────────────────────
    // Not awaited: on iOS getToken() may wait several seconds for APNs, and
    // that must not hold up the listener setup below or the rest of the
    // bootstrap. The backend registration fetches its own token anyway.
    unawaited(_cacheToken());

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
      // A rotated token is useless to the backend until it is re-registered;
      // caching it locally alone would silently stop push for this device.
      onTokenRefresh?.call(newToken);
    });

    // ── Local notifications setup (for foreground display) ───────────────────
    // Must be a flat white-on-transparent silhouette (see ic_notification.png
    // under android/app/src/main/res/drawable-*) — Android strips color from
    // status bar icons on API 21+.
    const androidInit =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        final route = details.payload ?? '/dashboard/notifications';
        onNotificationTap?.call(route);
      },
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Foreground messages. iOS presents them natively, with the options set
    // here. They must be set: firebase_messaging registers before
    // flutter_local_notifications, so its willPresentNotification answers
    // first — with "present nothing" by default, which also hid the local
    // notification Android uses below. Android never shows a push while
    // the app is open, so there it's re-posted as a local notification.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      FirebaseMessaging.onMessage.listen(_showLocalNotification);
    }

    // Notification tap while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = _routeFromMessage(message);
      onNotificationTap?.call(route);
    });

    // Cold-start tap. Parked rather than navigated: this runs during app
    // bootstrap, before the splash has decided where to send the rider, so
    // pushing now would either be lost or land behind the splash's own
    // context.go. The splash drains `pendingRoute` once it has routed.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      pendingRoute = _routeFromMessage(initial);
    }
  }

  /// Latest known notification permission — null until first checked.
  /// Refreshed on every app resume, so turning notifications on in the
  /// Settings app is picked up without a relaunch.
  static final ValueNotifier<AuthorizationStatus?> permissionStatus =
      ValueNotifier(null);

  static bool isPermitted(AuthorizationStatus? status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  /// Shows the OS permission prompt if it can still be shown. Called at app
  /// launch (see `RiderAppBootstrap`), before sign-in. iOS allows that
  /// dialog exactly once per install, so after a "Don't Allow" the only way
  /// back is the Settings app (see `NotificationPermissionPrompt`); Android
  /// allows it until the rider blocks it permanently.
  ///
  /// On Android 13+ the request raises the POST_NOTIFICATIONS dialog — but
  /// only because that permission is declared in AndroidManifest.xml.
  static Future<AuthorizationStatus> ensurePermission() async {
    final messaging = FirebaseMessaging.instance;
    var settings = await messaging.getNotificationSettings();
    final status = settings.authorizationStatus;
    // Android never reports `notDetermined`: an unanswered POST_NOTIFICATIONS
    // (Android 13+) reads as `denied`. Gating on notDetermined alone meant
    // the launch prompt never appeared on Android, and riders first met the
    // "Open Settings" fallback on the home screen after login. Requesting on
    // `denied` is safe there — once permanently denied, the OS returns
    // immediately without showing anything.
    final shouldAsk = status == AuthorizationStatus.notDetermined ||
        (defaultTargetPlatform == TargetPlatform.android &&
            status == AuthorizationStatus.denied);
    if (shouldAsk) {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    permissionStatus.value = settings.authorizationStatus;
    appLogger.i(
      '[FCM] notification permission: ${settings.authorizationStatus.name}',
    );
    return settings.authorizationStatus;
  }

  /// Re-reads the current permission without prompting.
  static Future<AuthorizationStatus> refreshPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    permissionStatus.value = settings.authorizationStatus;
    return settings.authorizationStatus;
  }

  static const _apnsAttempts = 10;
  static const _apnsRetryDelay = Duration(seconds: 1);

  /// The current FCM registration token, or null if one can't be issued.
  ///
  /// On iOS an FCM token only exists once APNs has handed the device its
  /// own token, which arrives asynchronously — often a few seconds after
  /// the permission prompt is answered on first launch. Asking FCM before
  /// then throws `apns-token-not-set`, so this waits for the APNs token
  /// first. Still null after the retries (e.g. the Simulator, which has no
  /// APNs) → returns null rather than throwing.
  static Future<String?> getToken() async {
    final messaging = FirebaseMessaging.instance;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken;
      for (var i = 0; i < _apnsAttempts; i++) {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future<void>.delayed(_apnsRetryDelay);
      }
      if (apnsToken == null) {
        appLogger.w(
          '[FCM] no APNs token after ${_apnsAttempts}s — check the push '
          'entitlement, and that an APNs key is uploaded in Firebase',
        );
        return null;
      }
    }
    return messaging.getToken();
  }

  static Future<void> _cacheToken() async {
    try {
      final token = await getToken();
      if (token == null) return;
      appLogger.i('[FCM] token: $token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      appLogger.w('[FCM] token unavailable: $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@drawable/ic_notification',
          // Matches ic_launcher_background / the manifest's
          // default_notification_color, so a foreground-shown notification
          // looks the same as one the FCM SDK auto-displays in background.
          color: const Color(0xFFE91D25),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _routeFromMessage(message),
    );
  }

  static String _routeFromMessage(RemoteMessage message) {
    final type = message.data['type']?.toString();
    return switch (type) {
      'new_order' => '/dashboard',
      'order_accepted' => '/dashboard',
      // Wallet is a dashboard tab, not a route — the ledger is the
      // nearest routable screen, and it's where a payment lands anyway.
      'payment' => '/dashboard/wallet/transactions',
      'document' => '/dashboard/kyc',
      _ => '/dashboard/notifications',
    };
  }
}
