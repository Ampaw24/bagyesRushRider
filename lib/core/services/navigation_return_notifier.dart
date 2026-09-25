import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:delivery_boy/core/services/fcm_service.dart';
import 'package:delivery_boy/core/services/navigation_bubble_channel.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

/// The "tap to return" affordance for a rider who left the app to get
/// turn-by-turn directions in an external Maps app.
///
/// On Android this is a real floating bubble via the official Bubbles API
/// (API 30+, see `NavigationBubbleHandler.kt`) — deliberately not
/// `SYSTEM_ALERT_WINDOW`, the pre-Bubbles overlay mechanism: that special
/// permission is a known tap-jacking/phishing vector and is heavily
/// scrutinised by Play Store review, whereas Bubbles need nothing beyond
/// the ordinary notification permission this app already requests.
///
/// A true floating bubble has no equivalent on iOS at all — Apple's
/// sandboxing gives no app a way to draw over another app's UI — and
/// Android itself only renders a bubble once the *rider* has separately
/// opted in via system settings (there's no API to grant this
/// programmatically). So [show] always tries the native bubble first on
/// Android and falls back to a plain ongoing notification — the only thing
/// iOS ever gets — whenever the bubble can't be shown.
class NavigationReturnNotifier {
  NavigationReturnNotifier._();

  /// Fixed id: at most one of these is ever relevant at a time, so a second
  /// [show] call replaces the first rather than stacking notifications.
  static const _id = 90201;

  static const _logoAsset = 'assets/images/splash_logo.png';

  /// Cached after the first [show] — the asset never changes at runtime, so
  /// re-reading it from the bundle on every navigate would just be wasted
  /// I/O on a hot path.
  static Uint8List? _logoBytes;

  static Future<Uint8List> _loadLogo() async {
    final cached = _logoBytes;
    if (cached != null) return cached;
    final bytes = (await rootBundle.load(_logoAsset)).buffer.asUint8List();
    _logoBytes = bytes;
    return bytes;
  }

  static const _title = 'Delivery in progress';

  static String _text(String destinationLabel) =>
      'Navigating to $destinationLabel — tap to return to BagyesRUSH';

  /// Shows (or replaces) the return prompt. Call once
  /// [ExternalNavigationLauncher] confirms Maps actually opened.
  static Future<void> show({required String destinationLabel}) async {
    // Android's status-bar icon must stay the small monochrome silhouette
    // (`ic_notification`) — the OS strips all colour from it on API 21+,
    // so the full-colour app logo goes on the large-icon/bubble-face slot
    // instead, where it actually renders recognisably. iOS has no
    // equivalent per-notification icon slot; it already shows the app's
    // own icon automatically.
    final logo = await _loadLogo();

    if (Platform.isAndroid) {
      final usedBubble = await NavigationBubbleChannel.show(
        title: _title,
        text: _text(destinationLabel),
        logo: logo,
      );
      // The native side already posted something (bubble or, on an older
      // API within its own check, nothing) — either way it owns this
      // notification now, so the plain fallback below must not also fire
      // and produce a second, competing one.
      if (usedBubble) return;
    }

    try {
      await FcmService.localNotifications.show(
        _id,
        _title,
        _text(destinationLabel),
        NotificationDetails(
          android: AndroidNotificationDetails(
            FcmService.androidChannel.id,
            FcmService.androidChannel.name,
            channelDescription: FcmService.androidChannel.description,
            icon: '@drawable/ic_notification',
            largeIcon: ByteArrayAndroidBitmap(logo),
            color: const Color(0xFFE91D25),
            importance: Importance.high,
            priority: Priority.high,
            // Ongoing: can't be swiped away mid-trip by accident — mirrors
            // how a navigation/call notification behaves on Android. Always
            // cleared explicitly via [cancel], never relies on autoCancel.
            ongoing: true,
            autoCancel: false,
            category: AndroidNotificationCategory.navigation,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: '/dashboard',
      );
    } catch (e, s) {
      // A missing return-prompt is a minor UX regression, not a failure
      // worth surfacing — the external navigation itself already succeeded.
      appLogger.w('[NavReturn] show failed', error: e, stackTrace: s);
    }
  }

  /// Clears the prompt. Called on every app resume (see
  /// `RiderDashboardScreen`), not just a tap on the notification itself, so
  /// it disappears however the rider actually came back — switching apps
  /// manually, tapping the notification, or Maps closing on its own.
  ///
  /// Clears both possible notifications unconditionally rather than
  /// tracking which one [show] actually used — cancelling one that was
  /// never posted is a harmless no-op on both platforms.
  static Future<void> cancel() async {
    if (Platform.isAndroid) await NavigationBubbleChannel.cancel();
    try {
      await FcmService.localNotifications.cancel(_id);
    } catch (e, s) {
      appLogger.w('[NavReturn] cancel failed', error: e, stackTrace: s);
    }
  }
}
