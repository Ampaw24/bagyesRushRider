import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
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
  StreamSubscription<loc.LocationData>? _locationSub;

  @override
  RiderTrackingState build() {
    ref.onDispose(() => _locationSub?.cancel());
    return const RiderTrackingState();
  }

  Future<void> startTracking() async {
    if (state.isTracking) return;

    final location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }

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

      // Platform location APIs return -1/NaN for an unknown heading —
      // sending that literally 422s against the backend's `between:0,360`
      // rule, so omit it rather than pass it through. Same guard
      // RiderMeLocationPing.toJson already documents for the batch path.
      final rawHeading = data.heading;
      final heading = (rawHeading != null &&
              rawHeading >= 0 &&
              rawHeading <= 360)
          ? rawHeading
          : null;

      // The backend wants km/h; `location` reports speed in m/s.
      final rawSpeed = data.speed;
      final speedKph =
          (rawSpeed != null && rawSpeed >= 0) ? rawSpeed * 3.6 : null;

      ref.read(riderMeProfileProvider.notifier).updateLocation(
            latitude: data.latitude!,
            longitude: data.longitude!,
            heading: heading,
            speedKph: speedKph,
            accuracyM: data.accuracy?.round(),
          );
    });

    state = state.copyWith(isTracking: true);
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
