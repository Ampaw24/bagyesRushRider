import 'package:flutter/services.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';

/// Thin wrapper over the Android-only platform channel that posts a real
/// Bubbles-API (API 30+) notification — see `NavigationBubbleHandler.kt`.
///
/// Every call is defensive: a device below API 30, a channel error, or
/// running on iOS (where this channel has no native handler at all) all
/// just resolve to "no bubble" rather than throwing, so the caller
/// ([NavigationReturnNotifier]) can fall back to an ordinary notification
/// without special-casing the failure.
class NavigationBubbleChannel {
  NavigationBubbleChannel._();

  static const _channel = MethodChannel('bagyesrush/navigation_bubble');

  /// Returns true only once the native side actually posted a notification
  /// (bubble-capable or, on an older API, none — see the Kotlin side for
  /// the exact cutoff). False means the Dart side must post its own
  /// fallback notification instead.
  static Future<bool> show({
    required String title,
    required String text,
    required Uint8List logo,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('show', {
        'title': title,
        'text': text,
        'logo': logo,
      });
      return result ?? false;
    } catch (e, s) {
      appLogger.w('[NavBubble] show failed', error: e, stackTrace: s);
      return false;
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (e, s) {
      appLogger.w('[NavBubble] cancel failed', error: e, stackTrace: s);
    }
  }

  /// Deep-links to the OS setting that lets the rider opt into bubbles for
  /// this app. There is no in-app permission prompt for this the way there
  /// is for plain notifications, so a rider who wants the floating bubble
  /// has to be sent here manually.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openBubbleSettings');
    } catch (e, s) {
      appLogger.w('[NavBubble] openSettings failed', error: e, stackTrace: s);
    }
  }
}
