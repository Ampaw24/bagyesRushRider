import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Handles Firebase Cloud Messaging integration.
/// Call [initialize] once at app startup (after Firebase.initializeApp()).
/// Call [registerToken] after a successful login/signup.
class FcmService {
  static const _tokenKey = 'fcm_token';

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'bagyes_rush_high_importance',
    'BagyesRUSH Notifications',
    description: 'Delivery updates and new order alerts',
    importance: Importance.high,
  );

  /// Initialize FCM: request permission, configure local notifications,
  /// and set up foreground / background / tap listeners.
  ///
  /// [onNotificationTap] receives the route to navigate to when the user
  /// taps a notification (pass in a callback that calls context.push/go).
  static Future<void> initialize({
    void Function(String route)? onNotificationTap,
  }) async {
    // ── Permission ───────────────────────────────────────────────────────────
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── Store token ──────────────────────────────────────────────────────────
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
    });

    // ── Local notifications setup (for foreground display) ───────────────────
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Cold-start tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final route = _routeFromMessage(initial);
      onNotificationTap?.call(route);
    }
  }

  /// Registers the stored FCM token with the backend for [userId].
  /// Call this right after a successful login or signup.
  static Future<void> registerToken(Dio dio, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return;
      await dio.put(
        ApiEndpoints.updateCourier,
        data: {'id': userId, 'fcmToken': token},
      );
    } catch (_) {
      // Non-critical — silently ignore token registration failures
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
          icon: '@mipmap/ic_launcher',
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
      'document' => '/dashboard/profile/edit',
      _ => '/dashboard/notifications',
    };
  }
}
