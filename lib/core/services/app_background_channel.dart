import 'package:flutter/services.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';

/// Android-only: sends the app to the background the way the Home button
/// does, rather than finishing it.
///
/// `SystemNavigator.pop()` finishes the Activity, which destroys the Flutter
/// engine and with it the rider's location stream — an online rider who
/// "closed" the app with Back would silently fall off the map.
class AppBackgroundChannel {
  AppBackgroundChannel._();

  static const _channel = MethodChannel('bagyesrush/app');

  /// Returns false where unsupported (iOS has no exit gesture to begin with).
  static Future<bool> moveToBackground() async {
    try {
      return await _channel.invokeMethod<bool>('moveToBackground') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      appLogger.w('[App] moveToBackground failed: $e');
      return false;
    }
  }
}
