import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';

/// How tightly [RiderTrackingNotifier] samples GPS. Two tiers, not one —
/// mirrors Uber/Bolt: riders who are just online-and-waiting still need a
/// fresh-enough fix for nearest-rider matching, but don't need the same
/// battery cost as someone actively en route on a delivery.
enum RiderTrackingMode { idle, active }

/// Drives [RiderTrackingNotifier] centrally: `null` means "don't track".
/// Delivery-stage tracking (picked up / arrived-at-dropoff) takes priority
/// over idle tracking, which itself only applies once the rider is online —
/// going offline stops tracking outright rather than falling back to idle.
final riderTrackingModeProvider = Provider<RiderTrackingMode?>((ref) {
  if (ref.watch(shouldTrackLocationProvider)) return RiderTrackingMode.active;
  final isOnline = ref.watch(
    riderMeProfileProvider.select((s) => s.profile?.isOnline ?? false),
  );
  return isOnline ? RiderTrackingMode.idle : null;
});

/// Plain lat/lng rather than `google_maps_flutter`'s `LatLng` — no map UI
/// consumes this state. `RiderOrderMapScreen` shows the rider's own
/// position via `GoogleMap(myLocationEnabled: true)` straight from the
/// device GPS instead, so this stays a headless ping source.
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

/// GPS-streaming engine, rider-scoped not order-scoped: pings go to
/// `POST rider/me/location` via `RiderMeProfileRepository` (see
/// rider_me_profile_providers.dart), which has no notion of "which order".
/// Start/stop and accuracy tier are driven centrally by
/// [riderTrackingModeProvider].
class RiderTrackingNotifier extends Notifier<RiderTrackingState> {
  /// Chunk size for `POST /rider/me/location/batch`, per
  /// [RiderMeProfileNotifier.updateLocationBatch].
  static const _batchChunkSize = 60;

  /// Caps memory use if the rider stays offline for a long stretch — oldest
  /// pings are dropped first, since a stale fix is less useful than a recent
  /// one once catch-up finally lands.
  static const _maxBufferedPings = 300;

  /// `onLocationChanged` is displacement-gated (see [_applySettings]) — a
  /// stationary rider never re-fires it, so their `updated_at` on the
  /// backend goes stale and they'd silently drop out of nearest-rider
  /// matching despite still being online. This timer forces a fix on a
  /// fixed cadence independent of movement, alongside the stream above.
  static const _activeHeartbeat = Duration(seconds: 20);
  static const _idleHeartbeat = Duration(seconds: 45);

  StreamSubscription<loc.LocationData>? _locationSub;
  loc.Location? _location;
  RiderTrackingMode? _mode;
  Timer? _heartbeat;

  /// Pings a failed [RiderMeProfileNotifier.updateLocation] call couldn't
  /// deliver — held here for catch-up via [RiderMeProfileNotifier.updateLocationBatch]
  /// once the connection recovers.
  final List<RiderMeLocationPing> _pendingPings = [];

  /// Bumped by [stopTracking]. A [startTracking] call spends a long time
  /// awaiting permission prompts; if a stop lands meanwhile (e.g. logout),
  /// the stale start sees the bumped value and bails instead of attaching
  /// a stream nobody will ever cancel.
  int _generation = 0;
  bool _starting = false;

  /// The most recently asked-for tier — a mode change that arrives while a
  /// start is still in flight is applied once that start completes.
  RiderTrackingMode? _requestedMode;

  @override
  RiderTrackingState build() {
    // Riverpod 2 keeps this Notifier instance across `invalidate` and only
    // re-runs build(), so instance fields must be reset here explicitly —
    // otherwise one rider's buffered pings would be flushed under the next
    // rider's token.
    ref.onDispose(() {
      stopTracking(notify: false);
      _pendingPings.clear();
    });
    return const RiderTrackingState();
  }

  Future<void> startTracking(RiderTrackingMode mode) async {
    _requestedMode = mode;
    if (state.isTracking) {
      if (_mode != mode) await _applySettings(mode);
      return;
    }
    if (_starting) return;

    _starting = true;
    final generation = _generation;
    try {
      await _start(generation);
    } finally {
      _starting = false;
    }
  }

  Future<void> _start(int generation) async {
    bool stale() => generation != _generation;

    final location = loc.Location();

    // Routed through RiderLocationService rather than calling the plugin
    // directly: it de-dupes in-flight permission/service requests. Android
    // and iOS track only one at a time, and a second concurrent request
    // never resolves — so a rider accepting an order while the launch
    // bootstrap is still awaiting its own prompt would otherwise hang here
    // and tracking would silently never start.
    if (!await RiderLocationService.ensureServiceEnabled()) return;

    final permission = await RiderLocationService.ensurePermission();
    if (!RiderLocationService.isGranted(permission) || stale()) return;

    _location = location;
    await _applySettings(_requestedMode!);

    // Android's "Allow all the time" grant, separate from the foreground
    // permission just checked above — RiderLocationService.ensurePermission
    // never requests it (see that method's doc). Declining it must not
    // block tracking altogether: the stream still runs fine while the app
    // is in the foreground, which covers the idle-online case most of the
    // time anyway. enableBackgroundMode itself is also wrapped rather than
    // trusted on the strength of the permission check alone — some OEMs
    // report the grant before it's actually usable by the location
    // service, and this call previously crashed the whole notifier as an
    // uncaught Zone error when it threw (PERMISSION_DENIED, seen live).
    if (await RiderLocationService.ensureBackgroundPermission()) {
      try {
        await location.enableBackgroundMode(enable: true);
      } on PlatformException catch (e, s) {
        appLogger.w('[Tracking] enableBackgroundMode failed', error: e, stackTrace: s);
      }
    }

    // stopTracking() already cancelled the heartbeat and cleared _location;
    // switch off the background service this start may just have enabled.
    if (stale()) {
      _disableBackgroundMode(location);
      return;
    }

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

    // The tier was re-requested while permission prompts were up.
    final requested = _requestedMode;
    if (requested != null && requested != _mode) await _applySettings(requested);
  }

  /// Applies the accuracy/distance-filter tier for [mode]. Safe to call
  /// while already streaming — `location` package settings changes apply to
  /// the live stream without needing to tear it down and resubscribe.
  Future<void> _applySettings(RiderTrackingMode mode) async {
    _mode = mode;
    switch (mode) {
      case RiderTrackingMode.active:
        // Tight enough to be useful on the in-app delivery map.
        await _location?.changeSettings(
          accuracy: loc.LocationAccuracy.high,
          distanceFilter: 10,
        );
      case RiderTrackingMode.idle:
        // Block-level accuracy is plenty for nearest-rider matching while
        // just online-and-waiting, at a fraction of the battery cost.
        await _location?.changeSettings(
          accuracy: loc.LocationAccuracy.balanced,
          distanceFilter: 75,
        );
    }

    _heartbeat?.cancel();
    final interval =
        mode == RiderTrackingMode.active ? _activeHeartbeat : _idleHeartbeat;
    _heartbeat = Timer.periodic(interval, (_) => unawaited(_sendHeartbeat()));
  }

  /// Forces one fix on the heartbeat cadence, bypassing the stream's
  /// distance filter — see [_heartbeat]'s doc for why a stationary rider
  /// still needs this.
  Future<void> _sendHeartbeat() async {
    final location = _location;
    if (location == null) return;
    try {
      final data = await location.getLocation();
      if (data.latitude == null || data.longitude == null) return;
      state = state.copyWith(latitude: data.latitude, longitude: data.longitude);
      await _reportFix(data);
    } catch (e, s) {
      appLogger.w('[Tracking] heartbeat fix failed', error: e, stackTrace: s);
    }
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

  /// Also cancels a [startTracking] still awaiting permission prompts.
  /// [notify] is false only from onDispose, where setting state is illegal.
  void stopTracking({bool notify = true}) {
    _generation++;
    _requestedMode = null;
    _locationSub?.cancel();
    _locationSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    final location = _location;
    if (location != null) _disableBackgroundMode(location);
    _location = null;
    _mode = null;
    if (notify) state = state.copyWith(isTracking: false);
  }

  /// Without this, Android keeps the location foreground service (and its
  /// persistent notification) alive after tracking stops.
  void _disableBackgroundMode(loc.Location location) {
    location.enableBackgroundMode(enable: false).catchError((Object e) {
      appLogger.w('[Tracking] disableBackgroundMode failed', error: e);
      return false;
    });
  }
}

final riderTrackingProvider =
    NotifierProvider<RiderTrackingNotifier, RiderTrackingState>(
        RiderTrackingNotifier.new);
