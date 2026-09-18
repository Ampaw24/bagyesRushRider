import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as ph;

import 'package:delivery_boy/core/services/rider_places_service.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';

enum RiderLocationStatus {
  success,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  error,
}

/// A single point-in-time location reading.
///
/// [address] is always populated — it falls back to a coordinate string — so
/// UI can render it without a null check.
class RiderLocationFix {
  final RiderLocationStatus status;
  final double? latitude;
  final double? longitude;
  final String address;

  const RiderLocationFix({
    required this.status,
    this.latitude,
    this.longitude,
    required this.address,
  });

  bool get isSuccess => status == RiderLocationStatus.success;
}

/// One-shot location acquisition + reverse geocoding.
///
/// Deliberately plugin-only: no Riverpod, no BuildContext, no widgets. State
/// lives in `riderLocationProvider`; this class just answers "where are we".
///
/// Built on `package:location` rather than `geolocator` because
/// [ensureServiceEnabled] can raise Android's in-app "Turn on location"
/// dialog, letting the rider enable GPS without leaving the app — and because
/// `RiderTrackingNotifier` already owns a `Location` instance, and two
/// location plugins each holding their own CLLocationManager on iOS is a
/// reliable way to get a permission callback that never fires.
class RiderLocationService {
  RiderLocationService._();

  static const String unavailableAddress = 'Location unavailable';

  static final loc.Location _location = loc.Location();

  // Android and iOS each track exactly ONE in-flight permission request. A
  // second concurrent requestPermission() does not error — it simply never
  // resolves. The launch bootstrap, the home chip's retry tap and
  // RiderTrackingNotifier.startTracking can all fire at once, so they share
  // these futures instead of racing.
  static Future<loc.PermissionStatus>? _pendingPermission;
  static Future<bool>? _pendingService;

  static Future<loc.PermissionStatus> ensurePermission() {
    return _pendingPermission ??= _requestPermission()
        .whenComplete(() => _pendingPermission = null);
  }

  /// Checks whether location services (GPS) are on, and on Android offers the
  /// in-app system dialog to switch them on when [prompt] is true.
  static Future<bool> ensureServiceEnabled({bool prompt = true}) {
    return _pendingService ??= _ensureService(prompt)
        .whenComplete(() => _pendingService = null);
  }

  /// `package:location` has no settings deep-link; permission_handler (already
  /// a dependency — the selfie capture screen uses it) supplies one.
  static Future<bool> openAppSettings() => ph.openAppSettings();

  static bool isGranted(loc.PermissionStatus status) =>
      status == loc.PermissionStatus.granted ||
      status == loc.PermissionStatus.grantedLimited;

  /// Acquires a fix and, unless [resolveAddress] is false, names it.
  ///
  /// Never throws — every failure mode maps onto a [RiderLocationStatus].
  static Future<RiderLocationFix> getCurrentFix({
    bool resolveAddress = true,
    bool promptService = true,
    Duration timeLimit = const Duration(seconds: 20),
  }) async {
    if (!await ensureServiceEnabled(prompt: promptService)) {
      return const RiderLocationFix(
        status: RiderLocationStatus.serviceDisabled,
        address: unavailableAddress,
      );
    }

    final permission = await ensurePermission();
    if (permission == loc.PermissionStatus.deniedForever) {
      return const RiderLocationFix(
        status: RiderLocationStatus.permissionDeniedForever,
        address: unavailableAddress,
      );
    }
    if (!isGranted(permission)) {
      return const RiderLocationFix(
        status: RiderLocationStatus.permissionDenied,
        address: unavailableAddress,
      );
    }

    final loc.LocationData data;
    try {
      // getLocation() takes no timeout of its own. Future.timeout does NOT
      // cancel the underlying platform call — it only bounds how long we
      // wait, which is the intent: a cold GPS start can outlast any UI
      // budget, and a late result is simply discarded.
      data = await _location.getLocation().timeout(timeLimit);
    } on TimeoutException {
      appLogger.w('[Location] fix timed out after ${timeLimit.inSeconds}s');
      return const RiderLocationFix(
        status: RiderLocationStatus.timeout,
        address: unavailableAddress,
      );
    } on PlatformException catch (e, s) {
      // Thrown when permission is revoked from Settings mid-call.
      appLogger.e('[Location] platform error', error: e, stackTrace: s);
      return const RiderLocationFix(
        status: RiderLocationStatus.error,
        address: unavailableAddress,
      );
    } catch (e, s) {
      appLogger.e('[Location] unexpected error', error: e, stackTrace: s);
      return const RiderLocationFix(
        status: RiderLocationStatus.error,
        address: unavailableAddress,
      );
    }

    final lat = data.latitude;
    final lng = data.longitude;
    if (lat == null || lng == null) {
      return const RiderLocationFix(
        status: RiderLocationStatus.error,
        address: unavailableAddress,
      );
    }

    // Null Island. Some devices report (0,0) as a "successful" no-fix;
    // surfacing it as a real position is worse than reporting an error.
    if (lat == 0.0 && lng == 0.0) {
      appLogger.w('[Location] discarding bogus (0,0) fix');
      return const RiderLocationFix(
        status: RiderLocationStatus.error,
        address: unavailableAddress,
      );
    }

    final coordinates = _coordinateString(lat, lng);
    if (!resolveAddress) {
      return RiderLocationFix(
        status: RiderLocationStatus.success,
        latitude: lat,
        longitude: lng,
        address: coordinates,
      );
    }

    // A geocode failure must never downgrade a good position fix: the status
    // stays `success` and the address degrades to coordinates.
    final address = await _resolveAddress(lat, lng) ?? coordinates;

    return RiderLocationFix(
      status: RiderLocationStatus.success,
      latitude: lat,
      longitude: lng,
      address: address,
    );
  }

  // ── Private ────────────────────────────────────────────────────────────────

  static Future<loc.PermissionStatus> _requestPermission() async {
    try {
      var permission = await _location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      return permission;
    } catch (e, s) {
      appLogger.e('[Location] permission request failed', error: e, stackTrace: s);
      return loc.PermissionStatus.denied;
    }
  }

  static Future<bool> _ensureService(bool prompt) async {
    try {
      if (await _location.serviceEnabled()) return true;
      if (!prompt) return false;
      // Android: raises the Play Services "Turn on location" dialog in-app.
      // iOS: has no such dialog, so this reports the current state and a
      // false result routes the UI to a Settings link instead.
      return await _location.requestService();
    } catch (e, s) {
      appLogger.e('[Location] service check failed', error: e, stackTrace: s);
      return false;
    }
  }

  /// Google Geocoding first: the platform geocoder resolves only coarse
  /// locality/district names in Ghana, which is too vague for a rider header.
  static Future<String?> _resolveAddress(double lat, double lng) async {
    final googleAddress = await RiderPlacesService.reverseGeocode(lat, lng);
    if (googleAddress != null && googleAddress.isNotEmpty) return googleAddress;

    try {
      final placemarks = await geo
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 8));
      if (placemarks.isNotEmpty) return _formatPlacemark(placemarks.first);
    } catch (e, s) {
      appLogger.e('[Location] platform geocode failed', error: e, stackTrace: s);
    }

    return null;
  }

  static String? _formatPlacemark(geo.Placemark p) {
    final parts = <String>[
      if ((p.street ?? '').isNotEmpty) p.street!,
      if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
      if ((p.locality ?? '').isNotEmpty)
        p.locality!
      else if ((p.subAdministrativeArea ?? '').isNotEmpty)
        p.subAdministrativeArea!
      else if ((p.administrativeArea ?? '').isNotEmpty)
        p.administrativeArea!,
    ];
    if (parts.isEmpty && (p.country ?? '').isNotEmpty) parts.add(p.country!);
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String _coordinateString(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
