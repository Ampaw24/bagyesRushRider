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
    // On Android 13+ this raises the POST_NOTIFICATIONS dialog — but only
    // because that permission is declared in AndroidManifest.xml. Without
    // the declaration it returns silently with no prompt at all.
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    appLogger.i(
      '[FCM] notification permission: ${settings.authorizationStatus.name}',
    );

    // ── Store token ──────────────────────────────────────────────────────────
    // Isolated: on the iOS Simulator there is no APNs, so getToken() throws.
    // That must not skip the listener setup below, or foreground display and
    // tap routing would be untestable there.
    try {
      final token = await getToken();
      if (token != null) {
        appLogger.i('[FCM] token: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
      } else {
        appLogger.w('[FCM] getToken() returned null');
      }
    } catch (e) {
      appLogger.w('[FCM] token unavailable: $e');
    }

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

    // Foreground messages → show as local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

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

  /// The current FCM registration token, or null if one can't be issued.
  static Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // On iOS an FCM token is only issued once APNs has assigned one.
      // Returns null on the Simulator (no APNs), which makes the getToken()
      // below throw — callers treat that as "no token yet" and move on.
      await FirebaseMessaging.instance.getAPNSToken();
    }
    return FirebaseMessaging.instance.getToken();
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
      'payment' => '/dashboard/wallet',
      'document' => '/dashboard/kyc',
      _ => '/dashboard/notifications',
    };
  }
}
