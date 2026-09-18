import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/core/utils/rider_location_cache.dart';

enum RiderLocationUiStatus {
  initial,
  locating,
  ready,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

class RiderLocationState extends Equatable {
  final RiderLocationUiStatus status;
  final double? latitude;
  final double? longitude;
  final String? address;

  /// True while the address on screen came from the disk cache and a fresh
  /// fix is still in flight. The chip dims rather than shimmers, so a rider
  /// who already has a location never sees it flash away on relaunch.
  final bool isStale;

  const RiderLocationState({
    this.status = RiderLocationUiStatus.initial,
    this.latitude,
    this.longitude,
    this.address,
    this.isStale = false,
  });

  bool get hasAddress => address != null && address!.isNotEmpty;

  RiderLocationState copyWith({
    RiderLocationUiStatus? status,
    double? latitude,
    double? longitude,
    String? address,
    bool? isStale,
  }) =>
      RiderLocationState(
        status: status ?? this.status,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        address: address ?? this.address,
        isStale: isStale ?? this.isStale,
      );

  @override
  List<Object?> get props => [status, latitude, longitude, address, isStale];
}

class RiderLocationNotifier extends Notifier<RiderLocationState> {
  @override
  RiderLocationState build() {
    // Synchronous on purpose: the home header paints the last known address
    // on its very first frame after a cold start, with no network call.
    final cached = RiderLocationCache.read();
    if (cached == null) return const RiderLocationState();

    return RiderLocationState(
      status: RiderLocationUiStatus.ready,
      latitude: cached.latitude,
      longitude: cached.longitude,
      address: cached.address,
      isStale: true,
    );
  }

  /// Acquires a fresh fix and resolves it to a street address.
  ///
  /// Set [promptService] false for a silent background refresh — it then
  /// won't raise Android's "Turn on location" dialog.
  Future<void> refresh({bool promptService = true}) async {
    if (state.status == RiderLocationUiStatus.locating) return;

    state = state.copyWith(
      status: RiderLocationUiStatus.locating,
      isStale: state.hasAddress,
    );

    final fix = await RiderLocationService.getCurrentFix(
      promptService: promptService,
    );

    if (!fix.isSuccess) {
      // A failed refresh must never wipe an address already on screen — that
      // is what stops the header flickering to "Location unavailable" every
      // time a fix times out indoors. Only the status changes.
      appLogger.w('[Location] refresh failed: ${fix.status.name}');
      state = state.copyWith(
        status: _uiStatusFor(fix.status),
        isStale: false,
      );
      return;
    }

    state = RiderLocationState(
      status: RiderLocationUiStatus.ready,
      latitude: fix.latitude,
      longitude: fix.longitude,
      address: fix.address,
      isStale: false,
    );

    await RiderLocationCache.write(
      latitude: fix.latitude!,
      longitude: fix.longitude!,
      address: fix.address,
    );
  }

  /// Sends the rider to the OS app-settings page — the only recovery once
  /// permission has been denied permanently.
  Future<void> openSettings() => RiderLocationService.openAppSettings();

  static RiderLocationUiStatus _uiStatusFor(RiderLocationStatus status) =>
      switch (status) {
        RiderLocationStatus.permissionDenied => RiderLocationUiStatus.denied,
        RiderLocationStatus.permissionDeniedForever =>
          RiderLocationUiStatus.deniedForever,
        RiderLocationStatus.serviceDisabled =>
          RiderLocationUiStatus.serviceDisabled,
        _ => RiderLocationUiStatus.error,
      };
}

final riderLocationProvider =
    NotifierProvider<RiderLocationNotifier, RiderLocationState>(
        RiderLocationNotifier.new);
