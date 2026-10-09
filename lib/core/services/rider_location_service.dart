import 'dart:async';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
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

/// The app's own view of location permission, so callers don't depend on the
/// location plugin's enums.
enum RiderLocationPermission { granted, denied, deniedForever }

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

/// One-shot location acquisition + reverse geocoding, and the permission
/// checks around it.
///
/// Deliberately plugin-only: no Riverpod, no BuildContext, no widgets. State
/// lives in `riderLocationProvider`; this class just answers "where are we".
///
/// Built on `geolocator` because tracking needs two things the previous
/// `location` plugin could not give: a real Android foreground service with a
/// visible notification, and iOS background settings (no auto-pause). Both
/// live in `RiderTrackingNotifier`'s stream settings. geolocator is the only
/// location plugin in the app — two plugins each holding their own
/// CLLocationManager on iOS is a reliable way to get a permission callback
/// that never fires. (`permission_handler` is used only for the separate
/// "Always" upgrade, which geolocator cannot request.)
class RiderLocationService {
  RiderLocationService._();

  static const String unavailableAddress = 'Location unavailable';

  /// Status reads normally answer instantly; if the platform channel never
  /// replies the caller must not hang with it (that pinned the home screen's
  /// pull-to-refresh spinner). Prompts are NOT bounded — a rider may take as
  /// long as they like to answer a dialog.
  static const Duration _checkTimeout = Duration(seconds: 5);

  // Android and iOS each track exactly ONE in-flight permission request. A
  // second concurrent requestPermission() does not error — it simply never
  // resolves. The launch bootstrap, the home chip's retry tap and
  // RiderTrackingNotifier.startTracking can all fire at once, so they share
  // these futures instead of racing.
  static Future<RiderLocationPermission>? _pendingPermission;
  static Future<RiderLocationPermission>? _pendingAlways;

  static Future<RiderLocationPermission> ensurePermission() {
    return _pendingPermission ??= _requestPermission()
        .whenComplete(() => _pendingPermission = null);
  }

  /// Silent check — never raises a prompt.
  static Future<RiderLocationPermission> currentPermission() async {
    try {
      final permission =
          await Geolocator.checkPermission().timeout(_checkTimeout);
      return _mapPermission(permission);
    } catch (e, s) {
      appLogger.e('[Location] permission check failed', error: e, stackTrace: s);
      return RiderLocationPermission.denied;
    }
  }

  /// Whether the rider has granted "Allow all the time" (Android) / "Always"
  /// (iOS). Silent. Background tracking needs it, so going online requires it.
  static Future<bool> hasAlwaysPermission() async {
    try {
      final permission =
          await Geolocator.checkPermission().timeout(_checkTimeout);
      return permission == LocationPermission.always;
    } catch (e, s) {
      appLogger.e('[Location] always check failed', error: e, stackTrace: s);
      return false;
    }
  }

  /// Walks the rider through foreground permission, then the separate
  /// "Allow all the time" grant that Android 11+ and iOS both treat as a
  /// second step. [RiderLocationPermission.granted] means *Always* here.
  ///
  /// Android offers the second step only as a Settings page, so the future
  /// resolves when the rider comes back from it.
  static Future<RiderLocationPermission> ensureAlwaysPermission() {
    return _pendingAlways ??=
        _requestAlways().whenComplete(() => _pendingAlways = null);
  }

  static Future<RiderLocationPermission> _requestAlways() async {
    final foreground = await ensurePermission();
    if (foreground != RiderLocationPermission.granted) return foreground;
    if (await hasAlwaysPermission()) return RiderLocationPermission.granted;

    try {
      final result = await ph.Permission.locationAlways.request();
      if (result.isPermanentlyDenied) {
        return RiderLocationPermission.deniedForever;
      }
    } catch (e, s) {
      appLogger.e('[Location] always request failed', error: e, stackTrace: s);
    }

    return await hasAlwaysPermission()
        ? RiderLocationPermission.granted
        : RiderLocationPermission.denied;
  }

  /// Whether location services (GPS) are switched on.
  ///
  /// geolocator has no in-app "turn on location" dialog (the old `location`
  /// plugin did, on Android only). With [prompt] true the rider is sent to the
  /// system location settings instead, and this still returns false — they
  /// come back and the next resume refresh picks the change up. Only an
  /// explicit rider tap should pass [prompt]; background callers must not
  /// throw the Settings app at them.
  static Future<bool> ensureServiceEnabled({bool prompt = false}) async {
    try {
      if (await Geolocator.isLocationServiceEnabled().timeout(_checkTimeout)) {
        return true;
      }
      if (prompt) await Geolocator.openLocationSettings();
      return false;
    } catch (e, s) {
      appLogger.e('[Location] service check failed', error: e, stackTrace: s);
      return false;
    }
  }

  static Future<bool> openAppSettings() => ph.openAppSettings();

  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static bool isGranted(RiderLocationPermission permission) =>
      permission == RiderLocationPermission.granted;

  /// Acquires a fix and, unless [resolveAddress] is false, names it.
  ///
  /// Never throws — every failure mode maps onto a [RiderLocationStatus].
  static Future<RiderLocationFix> getCurrentFix({
    bool resolveAddress = true,
    bool promptService = true,
    bool promptPermission = true,
    Duration timeLimit = const Duration(seconds: 20),
  }) async {
    if (!await ensureServiceEnabled(prompt: promptService)) {
      return const RiderLocationFix(
        status: RiderLocationStatus.serviceDisabled,
        address: unavailableAddress,
      );
    }

    // A silent refresh (e.g. on app resume) only checks: re-asking there
    // would pop the permission dialog every time the rider reopens the app.
    final permission =
        promptPermission ? await ensurePermission() : await currentPermission();
    if (permission == RiderLocationPermission.deniedForever) {
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

    final Position data;
    try {
      // `timeLimit` is enforced natively; the outer Future.timeout is a
      // backstop for a platform call that never answers at all.
      data = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      ).timeout(timeLimit + const Duration(seconds: 2));
    } on TimeoutException {
      appLogger.w('[Location] fix timed out after ${timeLimit.inSeconds}s');
      return const RiderLocationFix(
        status: RiderLocationStatus.timeout,
        address: unavailableAddress,
      );
    } on PermissionDeniedException {
      // Revoked from Settings mid-call.
      return const RiderLocationFix(
        status: RiderLocationStatus.permissionDenied,
        address: unavailableAddress,
      );
    } on LocationServiceDisabledException {
      return const RiderLocationFix(
        status: RiderLocationStatus.serviceDisabled,
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

  /// Names a position that was obtained elsewhere (e.g. the tracking
  /// stream), falling back to a coordinate string. Never throws.
  static Future<String> addressFor(double lat, double lng) async =>
      await _resolveAddress(lat, lng) ?? _coordinateString(lat, lng);

  // ── Private ────────────────────────────────────────────────────────────────

  static RiderLocationPermission _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always =>
          RiderLocationPermission.granted,
        LocationPermission.deniedForever =>
          RiderLocationPermission.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine =>
          RiderLocationPermission.denied,
      };

  static Future<RiderLocationPermission> _requestPermission() async {
    try {
      var permission =
          await Geolocator.checkPermission().timeout(_checkTimeout);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _mapPermission(permission);
    } catch (e, s) {
      appLogger.e('[Location] permission request failed', error: e, stackTrace: s);
      return RiderLocationPermission.denied;
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
