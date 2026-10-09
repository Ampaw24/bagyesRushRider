import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/core/services/rider_location_service.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/location/providers/rider_location_providers.dart';
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
/// [riderTrackingModeProvider]; [ensureRunning] is the idempotent backstop
/// the presence coordinator calls on app resume.
///
/// Staying alive in the background is the whole point of this class:
/// - **Android** runs the stream inside geolocator's foreground service, which
///   shows an ongoing "You're online" notification. That is what stops the OS
///   throttling or freezing a minimized app.
/// - **iOS** runs with background location updates on and auto-pause off.
///   Auto-pause is what used to suspend a stationary rider, taking the
///   heartbeat timer down with it.
class RiderTrackingNotifier extends Notifier<RiderTrackingState> {
  /// Chunk size for `POST /rider/me/location/batch`, per
  /// [RiderMeProfileNotifier.updateLocationBatch].
  static const _batchChunkSize = 60;

  /// Caps memory use if the rider stays offline for a long stretch — oldest
  /// pings are dropped first, since a stale fix is less useful than a recent
  /// one once catch-up finally lands.
  static const _maxBufferedPings = 300;

  static const _pendingPingsKey = 'rider_pending_location_pings';

  /// The stream is displacement-gated (see [_settingsFor]) — a stationary
  /// rider never re-fires it, so their `updated_at` on the backend goes stale
  /// and they'd silently drop out of nearest-rider matching despite still
  /// being online. This timer forces a ping on a fixed cadence independent of
  /// movement, alongside the stream.
  static const _activeHeartbeat = Duration(seconds: 20);
  static const _idleHeartbeat = Duration(seconds: 45);

  /// A heartbeat that can't get a fresh fix inside this falls back to the
  /// last known position rather than reporting nothing.
  static const _heartbeatFixLimit = Duration(seconds: 15);

  static const _watchdogInterval = Duration(seconds: 30);

  /// Stream restart delays after an error; the last value repeats.
  static const _restartBackoff = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  StreamSubscription<Position>? _positionSub;
  RiderTrackingMode? _mode;

  /// The tier the live stream was actually built with. Differs from [_mode]
  /// only while a tier change is deferred until the app is in the foreground
  /// (see [_applyMode]).
  RiderTrackingMode? _streamMode;
  Timer? _heartbeat;
  Timer? _watchdog;
  Timer? _restartTimer;
  int _restartAttempts = 0;
  bool _heartbeatInFlight = false;

  /// When the stream or the heartbeat last produced a genuine fix — not the
  /// last-known fallback. Drives [_watchdog].
  DateTime? _lastFixAt;
  Position? _lastPosition;

  /// Pings a failed [RiderMeProfileNotifier.updateLocation] call couldn't
  /// deliver — held here (and mirrored to disk) for catch-up via
  /// [RiderMeProfileNotifier.updateLocationBatch] once the connection
  /// recovers.
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
    // rider's token. The disk copy goes too: dispose runs on logout.
    ref.onDispose(() {
      stopTracking(notify: false);
      _pendingPings.clear();
      unawaited(_persistPending());
    });
    unawaited(_restorePendingPings());
    return const RiderTrackingState();
  }

  Future<void> startTracking(RiderTrackingMode mode) async {
    _requestedMode = mode;
    if (state.isTracking) {
      if (_mode != mode) await _applyMode(mode);
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

  /// Idempotent: makes sure tracking matches what the rider should be doing
  /// right now, and sends a ping straight away. Safe to call on every app
  /// resume — it does nothing expensive when all is well.
  ///
  /// This exists because the start/stop listener only fires when the mode
  /// *changes*. A stream that died quietly while the app was dormant left the
  /// mode unchanged, so nothing restarted it and the rider fell off the map
  /// until they toggled offline and back online.
  Future<void> ensureRunning() async {
    final mode = ref.read(riderTrackingModeProvider);
    if (mode == null) return;

    if (!state.isTracking) {
      await startTracking(mode);
    } else if (_mode != mode) {
      await _applyMode(mode);
    } else if (_streamMode != _mode || _isStale()) {
      _subscribe(mode);
    }
    unawaited(_sendHeartbeat());
  }

  bool get _inForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  bool _isStale() {
    final last = _lastFixAt;
    if (last == null) return false;
    final interval =
        _mode == RiderTrackingMode.active ? _activeHeartbeat : _idleHeartbeat;
    return DateTime.now().difference(last) > interval * 2 + _heartbeatFixLimit;
  }

  Future<void> _start(int generation) async {
    bool stale() => generation != _generation;

    // Routed through RiderLocationService rather than calling the plugin
    // directly: it de-dupes in-flight permission requests. Android and iOS
    // track only one at a time, and a second concurrent request never
    // resolves — so a rider accepting an order while the launch bootstrap is
    // still awaiting its own prompt would otherwise hang here and tracking
    // would silently never start.
    if (!await RiderLocationService.ensureServiceEnabled()) {
      _scheduleRestart();
      return;
    }

    // Prompting needs a foreground Activity; from the background only look.
    final permission = _inForeground
        ? await RiderLocationService.ensurePermission()
        : await RiderLocationService.currentPermission();
    if (stale()) return;
    if (!RiderLocationService.isGranted(permission)) {
      // Denied for good is the presence coordinator's to surface; a plain
      // denial may still be answered, so keep trying quietly.
      if (permission != RiderLocationPermission.deniedForever) {
        _scheduleRestart();
      }
      return;
    }

    _mode = _requestedMode;
    if (_mode == null) return;
    try {
      _subscribe(_mode!);
    } catch (e, s) {
      appLogger.e('[Tracking] could not start stream', error: e, stackTrace: s);
      _scheduleRestart();
      return;
    }

    state = state.copyWith(isTracking: true);
    _restartHeartbeat();
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogInterval, (_) => _checkWatchdog());

    // The tier was re-requested while permission prompts were up.
    final requested = _requestedMode;
    if (requested != null && requested != _mode) await _applyMode(requested);

    // Don't wait for the first stream event or heartbeat tick: a rider who
    // has just gone online should be visible immediately.
    unawaited(_sendHeartbeat());
  }

  /// Switches accuracy tier. The stream's settings are fixed when it is
  /// subscribed, so a new tier means a new subscription — which on Android
  /// restarts the foreground service. Android 12+ may refuse to start one
  /// while the app is in the background, so a tier change that arrives then
  /// only retunes the heartbeat and the stream follows on the next resume.
  Future<void> _applyMode(RiderTrackingMode mode) async {
    _mode = mode;
    _restartHeartbeat();
    if (_inForeground) _subscribe(mode);
  }

  /// (Re)builds the position stream for [mode]. Always cancels the previous
  /// subscription first: geolocator's Android service keeps a single client,
  /// so two overlapping subscriptions would stop the newer one.
  void _subscribe(RiderTrackingMode mode) {
    _positionSub?.cancel();
    _restartTimer?.cancel();
    _restartTimer = null;
    _streamMode = mode;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _settingsFor(mode),
    ).listen(
      _onPosition,
      onError: _onStreamError,
      onDone: _onStreamDone,
    );
  }

  LocationSettings _settingsFor(RiderTrackingMode mode) {
    final active = mode == RiderTrackingMode.active;
    // Tight enough to be useful on the in-app delivery map when active;
    // block-level accuracy is plenty for nearest-rider matching while just
    // online-and-waiting, at a fraction of the battery cost.
    final accuracy = active ? LocationAccuracy.high : LocationAccuracy.medium;
    final distanceFilter = active ? 10 : 75;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          intervalDuration: active
              ? const Duration(seconds: 5)
              : const Duration(seconds: 15),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'BagyesRIDER',
            notificationText: "You're online and visible to customers",
            notificationChannelName: 'Online status',
            notificationIcon: AndroidResource(
              name: 'ic_notification',
              defType: 'drawable',
            ),
            setOngoing: true,
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          activityType: ActivityType.otherNavigation,
          // Auto-pause suspends updates for a stationary rider, and with them
          // the whole app — the heartbeat timer included.
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        );
    }
  }

  void _onPosition(Position data) {
    _restartAttempts = 0;
    _lastFixAt = DateTime.now();
    _lastPosition = data;
    state = state.copyWith(
      latitude: data.latitude,
      longitude: data.longitude,
    );

    unawaited(_reportFix(data));
    _updateHeaderAddress(data);
  }

  void _onStreamError(Object error, StackTrace stack) {
    appLogger.w('[Tracking] stream error', error: error, stackTrace: stack);
    _scheduleRestart();
  }

  void _onStreamDone() {
    appLogger.w('[Tracking] stream closed unexpectedly');
    _scheduleRestart();
  }

  /// Retries a dead or never-started stream with backoff. Runs in the
  /// background too: a stream that is already dead has nothing left to lose.
  void _scheduleRestart() {
    if (_restartTimer?.isActive ?? false) return;
    final mode = _requestedMode ?? _mode;
    if (mode == null) return;

    final delay = _restartBackoff[
        _restartAttempts.clamp(0, _restartBackoff.length - 1)];
    _restartAttempts++;
    final generation = _generation;
    _restartTimer = Timer(delay, () async {
      if (generation != _generation) return;
      if (state.isTracking) {
        try {
          _subscribe(mode);
        } catch (e, s) {
          appLogger.e('[Tracking] restart failed', error: e, stackTrace: s);
          _scheduleRestart();
        }
      } else {
        await startTracking(mode);
      }
    });
  }

  /// If neither the stream nor the heartbeat has produced a real fix for
  /// long enough, rebuild the stream. Foreground only, for the same
  /// foreground-service reason as [_applyMode].
  void _checkWatchdog() {
    if (!state.isTracking || !_isStale() || !_inForeground) return;
    final mode = _mode;
    if (mode == null) return;
    appLogger.w('[Tracking] no fix for a while — restarting stream');
    _lastFixAt = DateTime.now();
    _subscribe(mode);
  }

  void _restartHeartbeat() {
    _heartbeat?.cancel();
    final interval =
        _mode == RiderTrackingMode.active ? _activeHeartbeat : _idleHeartbeat;
    _heartbeat = Timer.periodic(interval, (_) => unawaited(_sendHeartbeat()));
  }

  /// Forces one ping on the heartbeat cadence, bypassing the stream's
  /// distance filter — see [_idleHeartbeat] for why a stationary rider
  /// still needs this. A single in-flight call at a time: ticks that arrive
  /// while one is hung would otherwise pile up.
  Future<void> _sendHeartbeat() async {
    if (_heartbeatInFlight || !state.isTracking) return;
    _heartbeatInFlight = true;
    try {
      Position? data;
      try {
        data = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: _heartbeatFixLimit,
          ),
        ).timeout(_heartbeatFixLimit + const Duration(seconds: 2));
        _lastFixAt = DateTime.now();
        _lastPosition = data;
      } catch (e) {
        // No fresh fix (indoors, GPS cold) — a stationary rider is still
        // online at the spot they were last seen, so report that instead of
        // going silent. _lastFixAt stays put, so the watchdog still sees it.
        appLogger.w('[Tracking] heartbeat fix failed, using last position: $e');
        data = _lastPosition;
      }
      if (data == null) return;

      state = state.copyWith(latitude: data.latitude, longitude: data.longitude);
      _updateHeaderAddress(data);
      await _reportFix(data);
    } catch (e, s) {
      appLogger.w('[Tracking] heartbeat failed', error: e, stackTrace: s);
    } finally {
      _heartbeatInFlight = false;
    }
  }

  /// Keeps the home header's address in step with the rider while online;
  /// [RiderLocationNotifier.updateFromTracking] throttles by distance.
  void _updateHeaderAddress(Position data) {
    unawaited(ref
        .read(riderLocationProvider.notifier)
        .updateFromTracking(data.latitude, data.longitude));
  }

  /// Sends one live fix; buffers it for catch-up if the send fails instead
  /// of dropping it, then tries to drain anything already buffered.
  Future<void> _reportFix(Position data) async {
    // Platform location APIs return -1/NaN for an unknown heading — sending
    // that literally 422s against the backend's `between:0,360` rule, so
    // omit it rather than pass it through. Same guard
    // RiderMeLocationPing.toJson already documents for the batch path.
    final rawHeading = data.heading;
    final heading = (rawHeading >= 0 && rawHeading <= 360) ? rawHeading : null;

    // The backend wants km/h; geolocator reports speed in m/s.
    final rawSpeed = data.speed;
    final speedKph = rawSpeed >= 0 ? rawSpeed * 3.6 : null;

    final notifier = ref.read(riderMeProfileProvider.notifier);
    final sent = await notifier.updateLocation(
      latitude: data.latitude,
      longitude: data.longitude,
      heading: heading,
      speedKph: speedKph,
      accuracyM: data.accuracy.round(),
    );

    if (!sent) {
      _bufferPing(RiderMeLocationPing(
        latitude: data.latitude,
        longitude: data.longitude,
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
    unawaited(_persistPending());
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
    await _persistPending();
  }

  /// Mirrors the buffer to disk so pings recorded while the rider was
  /// offline-from-the-network survive the process being killed.
  Future<void> _persistPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_pendingPings.isEmpty) {
        await prefs.remove(_pendingPingsKey);
      } else {
        await prefs.setString(
          _pendingPingsKey,
          jsonEncode(_pendingPings.map((p) => p.toJson()).toList()),
        );
      }
    } catch (e) {
      appLogger.w('[Tracking] could not persist pending pings: $e');
    }
  }

  Future<void> _restorePendingPings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingPingsKey);
      if (raw == null) return;
      final restored = (jsonDecode(raw) as List)
          .map((e) => RiderMeLocationPing.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      // Restored pings are older than anything buffered this session.
      _pendingPings.insertAll(0, restored);
      if (_pendingPings.length > _maxBufferedPings) {
        _pendingPings.removeRange(0, _pendingPings.length - _maxBufferedPings);
      }
    } catch (e) {
      appLogger.w('[Tracking] could not restore pending pings: $e');
    }
  }

  /// Also cancels a [startTracking] still awaiting permission prompts.
  /// [notify] is false only from onDispose, where setting state is illegal.
  /// Cancelling the stream is what stops geolocator's Android foreground
  /// service and its persistent notification.
  void stopTracking({bool notify = true}) {
    _generation++;
    _requestedMode = null;
    _positionSub?.cancel();
    _positionSub = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _watchdog?.cancel();
    _watchdog = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    _restartAttempts = 0;
    _lastFixAt = null;
    _lastPosition = null;
    _mode = null;
    _streamMode = null;
    if (notify) state = state.copyWith(isTracking: false);
  }
}

final riderTrackingProvider =
    NotifierProvider<RiderTrackingNotifier, RiderTrackingState>(
        RiderTrackingNotifier.new);
