import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';

/// Plain lat/lng rather than `google_maps_flutter`'s `LatLng` — no map UI
/// consumes this state (the legacy per-order map screen was retired along
/// with the dead `/orders/location/update` endpoint this used to call).
class RiderTrackingState {
  final double? latitude;
  final double? longitude;
  final bool isTracking;

  const RiderTrackingState({
    this.latitude,
    this.longitude,
    this.isTracking = false,
  });

  RiderTrackingState copyWith({
    double? latitude,
    double? longitude,
    bool? isTracking,
  }) =>
      RiderTrackingState(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isTracking: isTracking ?? this.isTracking,
      );
}

/// GPS-streaming engine for an in-progress delivery. Rider-scoped, not
/// order-scoped: pings go to `POST rider/me/location` via
/// `RiderMeProfileRepository` (see rider_me_profile_providers.dart), which
/// has no notion of "which order" — start/stop is instead gated on whether
/// *any* order is currently past pickup (see `shouldTrackLocationProvider`
/// in rider_me_order_providers.dart).
class RiderTrackingNotifier extends Notifier<RiderTrackingState> {
  /// Chunk size for `POST /rider/me/location/batch`, per
  /// [RiderMeProfileNotifier.updateLocationBatch].
  static const _batchChunkSize = 60;

  /// Caps memory use if the rider stays offline for a long stretch — oldest
  /// pings are dropped first, since a stale fix is less useful than a recent
  /// one once catch-up finally lands.
  static const _maxBufferedPings = 300;

  StreamSubscription<loc.LocationData>? _locationSub;

  /// Pings a failed [RiderMeProfileNotifier.updateLocation] call couldn't
  /// deliver — held here for catch-up via [RiderMeProfileNotifier.updateLocationBatch]
  /// once the connection recovers.
  final List<RiderMeLocationPing> _pendingPings = [];

  @override
  RiderTrackingState build() {
    ref.onDispose(() => _locationSub?.cancel());
    return const RiderTrackingState();
  }

  Future<void> startTracking() async {
    if (state.isTracking) return;

    final location = loc.Location();

    // Routed through RiderLocationService rather than calling the plugin
    // directly: it de-dupes in-flight permission/service requests. Android
    // and iOS track only one at a time, and a second concurrent request
    // never resolves — so a rider accepting an order while the launch
    // bootstrap is still awaiting its own prompt would otherwise hang here
    // and tracking would silently never start.
    if (!await RiderLocationService.ensureServiceEnabled()) return;

    final permission = await RiderLocationService.ensurePermission();
    if (!RiderLocationService.isGranted(permission)) return;

    await location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      distanceFilter: 10,
    );
    await location.enableBackgroundMode(enable: true);

    _locationSub =
        location.onLocationChanged.listen((loc.LocationData data) {
      if (data.latitude == null || data.longitude == null) return;

      state = state.copyWith(
        latitude: data.latitude,
        longitude: data.longitude,
      );

      unawaited(_reportFix(data));
    });

    state = state.copyWith(isTracking: true);
  }

  /// Sends one live fix; buffers it for catch-up if the send fails instead
  /// of dropping it, then tries to drain anything already buffered.
  Future<void> _reportFix(loc.LocationData data) async {
    // Platform location APIs return -1/NaN for an unknown heading — sending
    // that literally 422s against the backend's `between:0,360` rule, so
    // omit it rather than pass it through. Same guard
    // RiderMeLocationPing.toJson already documents for the batch path.
    final rawHeading = data.heading;
    final heading =
        (rawHeading != null && rawHeading >= 0 && rawHeading <= 360)
            ? rawHeading
            : null;

    // The backend wants km/h; `location` reports speed in m/s.
    final rawSpeed = data.speed;
    final speedKph =
        (rawSpeed != null && rawSpeed >= 0) ? rawSpeed * 3.6 : null;

    final notifier = ref.read(riderMeProfileProvider.notifier);
    final sent = await notifier.updateLocation(
      latitude: data.latitude!,
      longitude: data.longitude!,
      heading: heading,
      speedKph: speedKph,
      accuracyM: data.accuracy?.round(),
    );

    if (!sent) {
      _bufferPing(RiderMeLocationPing(
        latitude: data.latitude!,
        longitude: data.longitude!,
        heading: heading,
        speedKph: speedKph,
        accuracyM: data.accuracy,
        recordedAt: DateTime.now(),
      ));
      return;
    }

    if (_pendingPings.isNotEmpty) await _flushPending(notifier);
  }

  void _bufferPing(RiderMeLocationPing ping) {
    _pendingPings.add(ping);
    if (_pendingPings.length > _maxBufferedPings) {
      _pendingPings.removeRange(0, _pendingPings.length - _maxBufferedPings);
    }
  }

  /// Drains [_pendingPings] in chunks of [_batchChunkSize], stopping at the
  /// first failed chunk so a still-down connection doesn't spin through the
  /// whole backlog on every fix.
  Future<void> _flushPending(RiderMeProfileNotifier notifier) async {
    while (_pendingPings.isNotEmpty) {
      final chunk = _pendingPings.take(_batchChunkSize).toList();
      final sent = await notifier.updateLocationBatch(chunk);
      if (!sent) return;
      _pendingPings.removeRange(0, chunk.length);
    }
  }

  void stopTracking() {
    _locationSub?.cancel();
    _locationSub = null;
    state = state.copyWith(isTracking: false);
  }
}

final riderTrackingProvider =
    NotifierProvider<RiderTrackingNotifier, RiderTrackingState>(
        RiderTrackingNotifier.new);
