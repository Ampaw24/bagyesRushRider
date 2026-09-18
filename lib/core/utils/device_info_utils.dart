import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';

/// Resolves the platform label and human-readable device name sent when
/// registering this device's push token with the backend.
///
/// Kept format-identical to the customer app's equivalent so a rider's row in
/// the backend's device-token table reads the same as a customer's
/// (`"samsung SM-A515F"`, `"Kwame's iPhone"`).
class DeviceInfoUtils {
  DeviceInfoUtils._();

  static final _deviceInfo = DeviceInfoPlugin();

  static Future<({String platform, String deviceName})> getDetails() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfo.androidInfo;
          return (
            platform: 'android',
            deviceName: '${info.manufacturer} ${info.model}',
          );
        case TargetPlatform.iOS:
          final info = await _deviceInfo.iosInfo;
          return (platform: 'ios', deviceName: info.name);
        default:
          return (platform: defaultTargetPlatform.name, deviceName: 'unknown');
      }
    } catch (e, s) {
      // Never block token registration over a cosmetic label.
      appLogger.w('[DeviceInfo] lookup failed, using fallback: $e');
      appLogger.d('$s');
      return (platform: defaultTargetPlatform.name, deviceName: 'unknown');
    }
  }
}
