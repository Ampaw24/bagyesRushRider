import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';

/// Whether the rider last *chose* to be online.
///
/// The server's `is_online` can flip to false on its own (stale pings after
/// the app was dormant), and from the server's answer alone the app can't
/// tell that from a rider who deliberately went offline. This records the
/// rider's own choice so the presence coordinator can restore it without ever
/// overriding a deliberate "offline". `null` means the rider has never
/// chosen — nothing is restored.
class RiderOnlineIntent {
  RiderOnlineIntent._();

  static const _key = 'rider_wants_online';

  static Future<bool?> read() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key);
    } catch (e) {
      appLogger.w('[Presence] could not read online intent: $e');
      return null;
    }
  }

  static Future<void> write(bool wantsOnline) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, wantsOnline);
    } catch (e) {
      appLogger.w('[Presence] could not save online intent: $e');
    }
  }

  /// On logout / session end — the next rider on this device starts clean.
  static Future<void> clear() async {
    try {
      await (await SharedPreferences.getInstance()).remove(_key);
    } catch (e) {
      appLogger.w('[Presence] could not clear online intent: $e');
    }
  }
}
