import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
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
  /// How far the rider must move before a tracking fix re-names the header
  /// address. Every rename is a paid Google reverse-geocode call, and the
  /// tracking stream fires every 10–75 m, so it is throttled to movement
  /// the rider would actually notice.
  static const _addressRefreshDistanceM = 150.0;

  /// Set by the first successful fix of this app session. Until then an
  /// address on screen came from the disk cache and is shown dimmed, even
  /// if the first fresh fix fails.
  bool _hasFreshFix = false;
  bool _renaming = false;

  @override
  RiderLocationState build() {
    // The address was otherwise only refreshed on a cold start. iOS rarely
    // kills a backgrounded app, so a rider who left at A and reopened at B
    // kept seeing A. Silent: never raises the "Turn on location" dialog.
    final lifecycle = AppLifecycleListener(
      onResume: () => unawaited(refresh(promptService: false)),
    );
    ref.onDispose(lifecycle.dispose);

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
  /// Set [promptService] false for a silent refresh (app resume, pull to
  /// refresh) — it then raises neither Android's "Turn on location" dialog
  /// nor the permission prompt.
  Future<void> refresh({bool promptService = true}) async {
    if (state.status == RiderLocationUiStatus.locating) return;

    state = state.copyWith(
      status: RiderLocationUiStatus.locating,
      isStale: state.hasAddress,
    );

    final fix = await RiderLocationService.getCurrentFix(
      promptService: promptService,
      promptPermission: promptService,
    );

    if (!fix.isSuccess) {
      // A failed refresh must never wipe an address already on screen — that
      // is what stops the header flickering to "Location unavailable" every
      // time a fix times out indoors. Only the status changes.
      appLogger.w('[Location] refresh failed: ${fix.status.name}');
      state = state.copyWith(
        status: _uiStatusFor(fix.status),
        // A cached address that was never confirmed this session stays
        // dimmed rather than passing for the rider's current location.
        isStale: state.hasAddress && !_hasFreshFix,
      );
      return;
    }

    _hasFreshFix = true;
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

  /// Feeds a position from the online tracking stream into the header, so
  /// the address follows the rider while they're online instead of only
  /// changing on app launch or resume. Re-names it only after a move of
  /// [_addressRefreshDistanceM], and never while a full refresh is running.
  Future<void> updateFromTracking(double latitude, double longitude) async {
    if (_renaming || state.status == RiderLocationUiStatus.locating) return;

    final lastLat = state.latitude;
    final lastLng = state.longitude;
    if (_hasFreshFix &&
        lastLat != null &&
        lastLng != null &&
        _distanceM(lastLat, lastLng, latitude, longitude) <
            _addressRefreshDistanceM) {
      return;
    }

    _renaming = true;
    try {
      final address = await RiderLocationService.addressFor(latitude, longitude);
      // A full refresh that started meanwhile owns the result.
      if (state.status == RiderLocationUiStatus.locating) return;
      _hasFreshFix = true;
      state = RiderLocationState(
        status: RiderLocationUiStatus.ready,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      await RiderLocationCache.write(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } finally {
      _renaming = false;
    }
  }

  /// Great-circle distance in metres (haversine) — ample precision for a
  /// "has the rider moved a block or two" check.
  static double _distanceM(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusM = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
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
