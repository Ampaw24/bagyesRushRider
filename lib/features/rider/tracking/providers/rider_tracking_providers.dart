import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/tracking/repositories/rider_tracking_repository.dart';

class RiderTrackingState {
  final LatLng position;
  final bool isTracking;

  const RiderTrackingState({
    this.position = const LatLng(0, 0),
    this.isTracking = false,
  });

  RiderTrackingState copyWith({LatLng? position, bool? isTracking}) =>
      RiderTrackingState(
        position: position ?? this.position,
        isTracking: isTracking ?? this.isTracking,
      );
}

class RiderTrackingNotifier extends Notifier<RiderTrackingState> {
  StreamSubscription<loc.LocationData>? _locationSub;

  @override
  RiderTrackingState build() {
    ref.onDispose(() => _locationSub?.cancel());
    return const RiderTrackingState();
  }

  RiderTrackingRepository get _repo => sl<RiderTrackingRepository>();

  Future<void> startTracking({required String orderId}) async {
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
      if (data.latitude != null && data.longitude != null) {
        final pos = LatLng(data.latitude!, data.longitude!);
        state = state.copyWith(position: pos);
        _repo.updateLocation({
          'orderId': orderId,
          'coords': {
            'latitude': data.latitude,
            'longitude': data.longitude,
          },
        });
      }
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
