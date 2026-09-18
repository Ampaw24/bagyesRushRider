import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

/// Last known good fix, persisted across launches.
class CachedRiderLocation {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime resolvedAt;

  const CachedRiderLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.resolvedAt,
  });
}

/// Disk cache for the rider's last resolved location.
///
/// `package:location` has no `getLastKnownPosition()` equivalent, so rather
/// than ask the OS for a stale fix and pay a Geocoding round-trip to name it,
/// we persist the coordinates *and the resolved address* ourselves. The home
/// header can then paint a real address on its very first frame after a cold
/// start, with no network call at all.
///
/// Backed by SharedPreferences (a GetIt singleton with synchronous reads) —
/// [read] must stay sync so a Riverpod `build()` can call it directly.
class RiderLocationCache {
  RiderLocationCache._();

  static const _latKey = 'rider_loc_lat';
  static const _lngKey = 'rider_loc_lng';
  static const _addressKey = 'rider_loc_address';
  static const _atKey = 'rider_loc_at';

  static CachedRiderLocation? read() {
    try {
      final prefs = sl<SharedPreferences>();
      final lat = prefs.getDouble(_latKey);
      final lng = prefs.getDouble(_lngKey);
      final address = prefs.getString(_addressKey);
      final at = prefs.getInt(_atKey);

      if (lat == null || lng == null || address == null || address.isEmpty) {
        return null;
      }

      return CachedRiderLocation(
        latitude: lat,
        longitude: lng,
        address: address,
        resolvedAt: DateTime.fromMillisecondsSinceEpoch(at ?? 0),
      );
    } catch (e) {
      // Reached before initServiceLocator() in a test or an early crash path.
      appLogger.w('[LocationCache] read failed: $e');
      return null;
    }
  }

  static Future<void> write({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final prefs = sl<SharedPreferences>();
      await prefs.setDouble(_latKey, latitude);
      await prefs.setDouble(_lngKey, longitude);
      await prefs.setString(_addressKey, address);
      await prefs.setInt(_atKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      appLogger.w('[LocationCache] write failed: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = sl<SharedPreferences>();
      await prefs.remove(_latKey);
      await prefs.remove(_lngKey);
      await prefs.remove(_addressKey);
      await prefs.remove(_atKey);
    } catch (e) {
      appLogger.w('[LocationCache] clear failed: $e');
    }
  }
}
