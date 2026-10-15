import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/realtime/models/realtime_events.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_me_order_repository.dart';

enum RiderMeOrdersStatus { initial, loading, loaded, error }

// ── Offers ───────────────────────────────────────────────────────────────

class RiderMeOffersState extends Equatable {
  final RiderMeOrdersStatus status;
  final List<RiderMeOfferModel> offers;
  final String? errorMessage;
  final RiderMeActionStatus actionStatus;
  final String? actionMessage;

  const RiderMeOffersState({
    this.status = RiderMeOrdersStatus.initial,
    this.offers = const [],
    this.errorMessage,
    this.actionStatus = RiderMeActionStatus.idle,
    this.actionMessage,
  });

  RiderMeOffersState copyWith({
    RiderMeOrdersStatus? status,
    List<RiderMeOfferModel>? offers,
    String? errorMessage,
    bool clearError = false,
    RiderMeActionStatus? actionStatus,
    String? actionMessage,
    bool clearActionMessage = false,
  }) =>
      RiderMeOffersState(
        status: status ?? this.status,
        offers: offers ?? this.offers,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        actionStatus: actionStatus ?? this.actionStatus,
        actionMessage: clearActionMessage
            ? null
            : (actionMessage ?? this.actionMessage),
      );

  @override
  List<Object?> get props =>
      [status, offers, errorMessage, actionStatus, actionMessage];
}

class RiderMeOffersNotifier extends Notifier<RiderMeOffersState> {
  StreamSubscription<Map<String, dynamic>>? _riderChannelSub;

  @override
  RiderMeOffersState build() {
    ref.onDispose(() => _riderChannelSub?.cancel());
    // New offers arrive on this rider's own private-rider.{id} channel (see
    // RealtimeService) — its payload shape isn't documented yet, so any
    // event there is treated as "something changed, refresh" rather than
    // parsed. The existing 25s poll in RiderNewOrdersScreen stays in place
    // as the reliability fallback for a dropped/reconnecting socket.
    _riderChannelSub = sl<RealtimeService>()
        .riderChannelEvents$
        .listen((_) => load(silent: true));
    return const RiderMeOffersState();
  }

  RiderMeOrderRepository get _repo => sl<RiderMeOrderRepository>();

  /// [silent] skips the `loading` transition — used by the background
  /// offer-list poll so it doesn't flash the shimmer placeholder every
  /// cycle. A normal (non-silent) load always shows it.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(
          status: RiderMeOrdersStatus.loading, clearError: true);
    }
    final result = await _repo.getOffers();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderMeOrdersStatus.error, errorMessage: f.message),
      (offers) => state = state.copyWith(
          status: RiderMeOrdersStatus.loaded, offers: offers),
    );
  }

  Future<bool> accept(int offerId) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.acceptOffer(offerId);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.success,
          offers: state.offers.where((o) => o.id != offerId).toList(),
        );
        return true;
      },
    );
  }

  Future<bool> decline(int offerId, {String? reason}) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.declineOffer(offerId, reason: reason);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.success,
          offers: state.offers.where((o) => o.id != offerId).toList(),
        );
        return true;
      },
    );
  }

  void clearActionStatus() =>
      state = state.copyWith(actionStatus: RiderMeActionStatus.idle);
}

final riderMeOffersProvider =
    NotifierProvider<RiderMeOffersNotifier, RiderMeOffersState>(
        RiderMeOffersNotifier.new);

// ── Orders (list + lifecycle) ───────────────────────────────────────────

class RiderMeOrdersState extends Equatable {
  final RiderMeOrdersStatus status;
  final List<RiderMeOrderModel> orders;
  final RiderMeOrderModel? selectedOrder;
  final String? errorMessage;
  final RiderMeActionStatus actionStatus;
  final String? actionMessage;
  final Map<String, List<String>>? actionFieldErrors;
  final Map<int, RiderDeliveryStage> stageByOrderId;
  final Map<int, Set<int>> arrivedStopIds;

  const RiderMeOrdersState({
    this.status = RiderMeOrdersStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.errorMessage,
    this.actionStatus = RiderMeActionStatus.idle,
    this.actionMessage,
    this.actionFieldErrors,
    this.stageByOrderId = const {},
    this.arrivedStopIds = const {},
  });

  RiderMeOrdersState copyWith({
    RiderMeOrdersStatus? status,
    List<RiderMeOrderModel>? orders,
    RiderMeOrderModel? selectedOrder,
    String? errorMessage,
    bool clearError = false,
    RiderMeActionStatus? actionStatus,
    String? actionMessage,
    bool clearActionMessage = false,
    Map<String, List<String>>? actionFieldErrors,
    bool clearActionFieldErrors = false,
    Map<int, RiderDeliveryStage>? stageByOrderId,
    Map<int, Set<int>>? arrivedStopIds,
  }) =>
      RiderMeOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        selectedOrder: selectedOrder ?? this.selectedOrder,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        actionStatus: actionStatus ?? this.actionStatus,
        actionMessage: clearActionMessage
            ? null
            : (actionMessage ?? this.actionMessage),
        actionFieldErrors: clearActionFieldErrors
            ? null
            : (actionFieldErrors ?? this.actionFieldErrors),
        stageByOrderId: stageByOrderId ?? this.stageByOrderId,
        arrivedStopIds: arrivedStopIds ?? this.arrivedStopIds,
      );

  /// Current delivery stage for [order] — whichever is further along of the
  /// stage this session advanced it to and the best-effort seed from its
  /// coarse `status`. Taking the furthest means a server-side `delivered`
  /// (e.g. after the last stop of a multi-stop order) always wins over a
  /// local `pickedUp`, while a local `arrivedAtDropoff` isn't knocked back
  /// to the `pickedUp` that `out_for_delivery` seeds. See
  /// rider_delivery_stage.dart for why this can't come straight from the
  /// server.
  ///
  /// A single-drop order whose payload says the rider already arrived
  /// (`timeline.arrived_at_dropoff` / `wait`) is lifted from `pickedUp` to
  /// `arrivedAtDropoff`, so the wait countdown survives an app restart.
  RiderDeliveryStage stageFor(RiderMeOrderModel order) {
    final seeded = seedDeliveryStageFrom(order.status);
    final local = stageByOrderId[order.id];
    final furthest =
        (local == null || seeded.index > local.index) ? seeded : local;
    return (furthest == RiderDeliveryStage.pickedUp &&
            order.hasArrivedAtDropoff)
        ? RiderDeliveryStage.arrivedAtDropoff
        : furthest;
  }

  /// Whether [order] is still being delivered: not finished on the server
  /// (delivered, cancelled, …) nor completed by this rider. Only then may
  /// the rider reach the customer.
  bool isInProgress(RiderMeOrderModel order) {
    final stage = stageFor(order);
    return order.isActive &&
        stage != RiderDeliveryStage.delivered &&
        stage != RiderDeliveryStage.closed;
  }

  /// The rider gave up on [order] — marked the customer unreachable, or
  /// failed every stop still open — and support hasn't reopened it yet.
  /// The server keeps such an order `out_for_delivery` with `can_deliver`
  /// false; an admin resolving it turns `can_deliver` back to true, which
  /// clears this on the next refresh. Derived, never stored, so there is
  /// nothing to reset by hand.
  bool isOnHold(RiderMeOrderModel order) {
    if (!order.isActive) return false;
    final stage = stageFor(order);
    if (order.usesStopFlow) {
      if (stage != RiderDeliveryStage.pickedUp) return false;
      final open = order.stops.where((s) => !s.isDelivered);
      return open.isNotEmpty && open.every((s) => s.isOnHold);
    }
    // Past pickup only: the flag means "gave up at the drop-off" there, and
    // an early false must never block the pickup steps.
    return order.canDeliver == false &&
        (stage == RiderDeliveryStage.pickedUp ||
            stage == RiderDeliveryStage.arrivedAtDropoff);
  }

  bool hasArrived(int orderId, int stopId) =>
      arrivedStopIds[orderId]?.contains(stopId) ?? false;

  @override
  List<Object?> get props => [
        status,
        orders,
        selectedOrder,
        errorMessage,
        actionStatus,
        actionMessage,
        actionFieldErrors,
        stageByOrderId,
        arrivedStopIds,
      ];
}

/// How often orders on hold are re-checked while the app is open (the offers
/// list polls every 25 s for the same reason: pushes and sockets can drop).
/// Support reopening an order surfaces within this.
const _kOnHoldPollInterval = Duration(seconds: 20);

class RiderMeOrdersNotifier extends Notifier<RiderMeOrdersState> {
  /// Order ids this notifier currently holds a `private-order.{id}` channel
  /// open for — kept in sync with the active orders in [state] by
  /// [_syncOrderChannels]. There's no dedicated order-tracking screen in
  /// this app to scope subscriptions to instead (see
  /// rider_tracking_providers.dart — it was retired), so "currently loaded
  /// as active" is the next best proxy for "relevant to this rider right
  /// now".
  final Set<int> _liveOrderChannels = {};
  StreamSubscription<RealtimeOrderStatusEvent>? _orderStatusSub;
  StreamSubscription<Map<String, dynamic>>? _riderChannelSub;

  /// Re-checks orders on hold until support reopens them. Reopening leaves
  /// the order's status as it was, so no `order.status` event announces it
  /// — this poll, the rider-channel listener and the refresh on app show
  /// are what notice `can_deliver` turning true. Runs only while something
  /// is on hold and the app is in the foreground.
  Timer? _onHoldPoll;
  bool _inForeground = true;
  bool _refreshingOnHold = false;

  @override
  RiderMeOrdersState build() {
    ref.onDispose(_teardownRealtime);
    final realtime = sl<RealtimeService>();
    _orderStatusSub = realtime.orderStatus$.listen(_onOrderStatusEvent);
    // The rider channel's payloads aren't documented, and support resolving
    // an order may be among them — cheap to follow, since only orders on
    // hold are re-fetched.
    _riderChannelSub = realtime.riderChannelEvents$
        .listen((_) => unawaited(_refreshOnHold()));

    // `onShow`/`onHide` rather than resume/pause, so pulling down the
    // notification shade (an `inactive` blip) doesn't trigger a refresh.
    final lifecycle = AppLifecycleListener(
      onShow: _onAppShown,
      onHide: _onAppHidden,
    );
    final appState = WidgetsBinding.instance.lifecycleState;
    _inForeground = appState == null ||
        appState == AppLifecycleState.resumed ||
        appState == AppLifecycleState.inactive;
    ref.onDispose(() {
      lifecycle.dispose();
      _stopOnHoldPoll();
    });
    listenSelf((_, next) => _syncOnHoldPoll(next));
    return const RiderMeOrdersState();
  }

  RiderMeOrderRepository get _repo => sl<RiderMeOrderRepository>();

  // ── Keeping orders on hold fresh ──────────────────────────────────────

  /// Back from the background: support may have reopened an order (or
  /// anything else may have moved) while the app was away.
  void _onAppShown() {
    _inForeground = true;
    if (state.status != RiderMeOrdersStatus.initial) {
      unawaited(() async {
        await load(filter: 'active', silent: true);
        await _refreshOnHold();
      }());
    }
    _syncOnHoldPoll(state);
  }

  void _onAppHidden() {
    _inForeground = false;
    _stopOnHoldPoll();
  }

  void _syncOnHoldPoll(RiderMeOrdersState current) {
    if (_inForeground && current.orders.any(current.isOnHold)) {
      _onHoldPoll ??= Timer.periodic(
        _kOnHoldPollInterval,
        (_) => unawaited(_refreshOnHold()),
      );
    } else {
      _stopOnHoldPoll();
    }
  }

  void _stopOnHoldPoll() {
    _onHoldPoll?.cancel();
    _onHoldPoll = null;
  }

  /// Re-fetches every order on hold, so one support has reopened is picked
  /// up. Overlapping triggers (poll, socket, app shown) share one pass.
  Future<void> _refreshOnHold() async {
    if (_refreshingOnHold) return;
    _refreshingOnHold = true;
    try {
      final ids = state.orders.where(state.isOnHold).map((o) => o.id).toList();
      for (final id in ids) {
        await refreshOrder(id);
      }
    } finally {
      _refreshingOnHold = false;
    }
  }

  /// Re-fetches one order in the background and patches it in — into the
  /// list, and into the open sheet if it shows this order. Unlike
  /// [loadOrder] it never takes over [RiderMeOrdersState.selectedOrder],
  /// and a failure is left quiet for the next refresh to retry.
  Future<void> refreshOrder(int orderId) async {
    final result = await _repo.getOrder(orderId);
    result.fold((_) {}, (order) => _applyOrder(order, select: false));
  }

  /// An admin (or any other actor) changed an order's status out of band —
  /// patch it in place rather than assuming which prior status it came
  /// from. An order that leaves the active set this way also drops its
  /// channel subscription, same as a rider-driven completion would. One that
  /// stays is re-fetched: the event carries only the status, not
  /// `can_deliver` or the stops.
  void _onOrderStatusEvent(RealtimeOrderStatusEvent event) {
    final orders = state.orders;
    final index = orders.indexWhere((o) => o.id == event.orderId);
    if (index == -1) return;

    final updated = orders[index].copyWith(status: event.status);
    final newOrders = [...orders];
    if (updated.isActive) {
      newOrders[index] = updated;
    } else {
      newOrders.removeAt(index);
    }

    state = state.copyWith(
      orders: newOrders,
      selectedOrder:
          state.selectedOrder?.id == event.orderId ? updated : state.selectedOrder,
    );

    if (updated.isActive) {
      unawaited(refreshOrder(event.orderId));
    } else {
      sl<RealtimeService>().unsubscribeFromOrder(event.orderId);
      _liveOrderChannels.remove(event.orderId);
    }
  }

  void _syncOrderChannels() {
    final activeIds =
        state.orders.where((o) => o.isActive).map((o) => o.id).toSet();
    final realtime = sl<RealtimeService>();

    for (final id in activeIds.difference(_liveOrderChannels)) {
      realtime.subscribeToOrder(id);
    }
    for (final id in _liveOrderChannels.difference(activeIds)) {
      realtime.unsubscribeFromOrder(id);
    }
    _liveOrderChannels
      ..clear()
      ..addAll(activeIds);
  }

  void _teardownRealtime() {
    _orderStatusSub?.cancel();
    _riderChannelSub?.cancel();
    final realtime = sl<RealtimeService>();
    for (final id in _liveOrderChannels) {
      realtime.unsubscribeFromOrder(id);
    }
    // Riverpod 2 reuses this Notifier instance across `invalidate` (only
    // build() re-runs), so a stale set would make _syncOrderChannels skip
    // re-subscribing for the next session.
    _liveOrderChannels.clear();
  }

  /// [filter] is `all` | `active` | `history` per the API contract.
  /// [silent] is for background refreshes: no `loading` state, and a
  /// failure leaves the list as it was — nothing for the Active tab to
  /// raise an error dialog over.
  Future<void> load({
    String? filter,
    String? status,
    int? perPage,
    bool silent = false,
  }) async {
    if (!silent) {
      state = state.copyWith(
          status: RiderMeOrdersStatus.loading, clearError: true);
    }
    final result =
        await _repo.getOrders(filter: filter, status: status, perPage: perPage);
    result.fold(
      (f) {
        if (silent) return;
        state = state.copyWith(
            status: RiderMeOrdersStatus.error, errorMessage: f.message);
      },
      (orders) {
        state = state.copyWith(
          status: RiderMeOrdersStatus.loaded,
          orders: _keepKnownCanDeliver(orders),
        );
        _syncOrderChannels();
      },
    );
  }

  /// A list payload that leaves `can_deliver` out says nothing about it —
  /// keep the value the order's own payload gave, rather than letting the
  /// list make an order on hold look deliverable (or stop its re-checks).
  List<RiderMeOrderModel> _keepKnownCanDeliver(
      List<RiderMeOrderModel> fresh) {
    final known = {for (final o in state.orders) o.id: o.canDeliver};
    return [
      for (final order in fresh)
        order.canDeliver == null && known[order.id] != null
            ? order.copyWith(canDeliver: known[order.id])
            : order,
    ];
  }

  /// Fetches one order into [RiderMeOrdersState.selectedOrder] and patches
  /// the same order in the active list, so the list, the location-tracking
  /// gate and any open detail sheet all agree. An order the server now
  /// reports as finished leaves the list (and its channel) here, same as
  /// a realtime status event would.
  Future<void> loadOrder(int orderId) async {
    final result = await _repo.getOrder(orderId);
    result.fold(
      (f) => state = state.copyWith(errorMessage: f.message),
      _applyOrder,
    );
  }

  /// Stores a freshly fetched [order] — see [loadOrder]. [select] makes it
  /// the [RiderMeOrdersState.selectedOrder]; otherwise that is only updated
  /// when it already is this order (see [refreshOrder]).
  void _applyOrder(RiderMeOrderModel order, {bool select = true}) {
    final selected = select || state.selectedOrder?.id == order.id
        ? order
        : state.selectedOrder;
    final index = state.orders.indexWhere((o) => o.id == order.id);
    if (index == -1) {
      state = state.copyWith(selectedOrder: selected);
      return;
    }
    final orders = [...state.orders];
    if (order.isActive) {
      orders[index] = order;
    } else {
      orders.removeAt(index);
    }
    state = state.copyWith(selectedOrder: selected, orders: orders);
    _syncOrderChannels();
  }

  /// Once every stop of a multi-stop order is delivered there is no rider
  /// action left, so the order is treated as done locally even if the
  /// server hasn't moved its coarse `status` to `delivered` yet — otherwise
  /// it would sit in the active list with no action panel and keep location
  /// tracking on its high-accuracy tier. A failed stop isn't final, though:
  /// support can reopen it (`can_deliver`), so an order left with one stays
  /// open — on hold until then (see [RiderMeOrdersState.isOnHold]). Once no
  /// stop is left to work, the active list is re-fetched so the server has
  /// the final word.
  Future<void> _afterStopResolved(int orderId) async {
    await loadOrder(orderId);
    final order = state.selectedOrder;
    if (order == null || order.id != orderId || order.stops.isEmpty) return;
    final allResolved = order.stops.every((s) => s.isDelivered || s.isFailed);
    if (!allResolved) return;
    if (order.stops.every((s) => s.isDelivered)) {
      _setStage(orderId, RiderDeliveryStage.delivered);
    }
    await load(filter: 'active', silent: true);
  }

  Future<bool> _runAction(ResultFuture<void> Function() action) async {
    state = state.copyWith(
      actionStatus: RiderMeActionStatus.inProgress,
      clearActionMessage: true,
      clearActionFieldErrors: true,
    );
    final result = await action();
    return result.fold(
      (f) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.error,
          actionMessage: f.message,
          actionFieldErrors: f is ValidationFailure ? f.errors : null,
        );
        return false;
      },
      (_) {
        state = state.copyWith(actionStatus: RiderMeActionStatus.success);
        return true;
      },
    );
  }

  void _setStage(int orderId, RiderDeliveryStage stage) =>
      state = state.copyWith(
        stageByOrderId: {...state.stageByOrderId, orderId: stage},
      );

  Future<bool> arrivedAtPickup(int orderId) async {
    final ok = await _runAction(() => _repo.arrivedAtPickup(orderId));
    if (ok) _setStage(orderId, RiderDeliveryStage.arrivedAtPickup);
    return ok;
  }

  /// [pickupPin] is the 4-digit collection code, required when the order's
  /// `requiresPickupCode` is true. A wrong code fails with a `pickup_pin`
  /// entry in [RiderMeOrdersState.actionFieldErrors].
  Future<bool> pickUpOrder(int orderId, {String? pickupPin}) async {
    final ok = await _runAction(
        () => _repo.pickUpOrder(orderId, pickupPin: pickupPin));
    if (ok) _setStage(orderId, RiderDeliveryStage.pickedUp);
    return ok;
  }

  /// The response carries the order with its wait window, so it is applied
  /// directly (starting the countdown) instead of re-fetching; an unreadable
  /// body falls back to a re-fetch.
  Future<bool> arrivedAtDropoff(int orderId) async {
    final ok = await _runOrderAction(
        orderId, () => _repo.arrivedAtDropoff(orderId));
    if (ok) _setStage(orderId, RiderDeliveryStage.arrivedAtDropoff);
    return ok;
  }

  /// Runs an action whose success body is the updated order and stores it —
  /// see [arrivedAtDropoff].
  Future<bool> _runOrderAction(
    int orderId,
    ResultFuture<RiderMeOrderModel?> Function() action,
  ) async {
    RiderMeOrderModel? updated;
    final ok = await _runAction(() async {
      final result = await action();
      return result.map<void>((order) => updated = order);
    });
    if (!ok) return false;
    final order = updated;
    if (order != null) {
      _applyOrder(order);
    } else {
      await loadOrder(orderId);
    }
    return true;
  }

  /// `deliveryPin` is required — 4 digits, sent as a string so a leading
  /// zero survives. Reloads the active list on success since the order
  /// leaves it.
  Future<bool> deliverOrder(
    int orderId, {
    required String deliveryPin,
    String? deliveredToName,
    String? proofPhotoPath,
  }) async {
    final ok = await _runAction(() => _repo.deliverOrder(
          orderId,
          deliveryPin: deliveryPin,
          deliveredToName: deliveredToName,
          proofPhotoPath: proofPhotoPath,
        ));
    if (ok) {
      _setStage(orderId, RiderDeliveryStage.delivered);
      await load(filter: 'active');
    }
    return ok;
  }

  Future<bool> releaseOrder(int orderId, {String? reason}) async {
    final ok = await _runAction(() => _repo.releaseOrder(orderId, reason: reason));
    if (ok) await load(filter: 'active');
    return ok;
  }

  /// Rider waited and can't reach the customer. The server keeps the order
  /// `out_for_delivery` with `can_deliver` false — on hold until support
  /// resolves it (see [RiderMeOrdersState.isOnHold]) — so it is re-fetched
  /// for the open sheet, then the list, rather than assumed gone.
  Future<bool> markUnreachable(int orderId, {String? reason}) async {
    final ok =
        await _runAction(() => _repo.markUnreachable(orderId, reason: reason));
    if (ok) {
      await loadOrder(orderId);
      await load(filter: 'active', silent: true);
    }
    return ok;
  }

  /// The stop comes back with its `waiting` window — see [arrivedAtDropoff].
  Future<bool> arriveAtStop(int orderId, int stopId) async {
    final ok = await _runOrderAction(
        orderId, () => _repo.arriveAtStop(orderId, stopId));
    if (ok) {
      final current = state.arrivedStopIds[orderId] ?? const <int>{};
      state = state.copyWith(arrivedStopIds: {
        ...state.arrivedStopIds,
        orderId: {...current, stopId},
      });
    }
    return ok;
  }

  /// See [deliverOrder] re: `deliveryPin`. Re-fetches just this order on
  /// success to resync its stop statuses — the full active list only once
  /// the last stop is resolved (see [_afterStopResolved]).
  Future<bool> deliverStop(
    int orderId,
    int stopId, {
    required String deliveryPin,
    String? deliveredToName,
    String? proofPhotoPath,
  }) async {
    final ok = await _runAction(() => _repo.deliverStop(
          orderId,
          stopId,
          deliveryPin: deliveryPin,
          deliveredToName: deliveredToName,
          proofPhotoPath: proofPhotoPath,
        ));
    if (ok) await _afterStopResolved(orderId);
    return ok;
  }

  Future<bool> failStop(int orderId, int stopId, {required String reason}) async {
    final ok =
        await _runAction(() => _repo.failStop(orderId, stopId, reason: reason));
    if (ok) await _afterStopResolved(orderId);
    return ok;
  }

  void clearActionStatus() =>
      state = state.copyWith(actionStatus: RiderMeActionStatus.idle);
}

final riderMeOrdersProvider =
    NotifierProvider<RiderMeOrdersNotifier, RiderMeOrdersState>(
        RiderMeOrdersNotifier.new);

/// Gates the GPS ping loop — true once at least one order is past pickup
/// (pings aren't useful before the rider is moving with the package).
/// Same `Provider<bool>`-over-`watch(state)` shape as `riderQueueProvider`
/// in rider_dashboard_screen.dart.
final shouldTrackLocationProvider = Provider<bool>((ref) {
  final state = ref.watch(riderMeOrdersProvider);
  return state.orders.any((o) {
    final s = state.stageFor(o);
    return s == RiderDeliveryStage.pickedUp ||
        s == RiderDeliveryStage.arrivedAtDropoff;
  });
});

// ── Order history ────────────────────────────────────────────────────────
//
// Deliberately a separate notifier from RiderMeOrdersNotifier above, even
// though both ultimately call the same `getOrders` repository method —
// sharing one `orders` list between an `active` load and a `history` load
// would have each overwrite the other's results. Same two-notifiers-one-
// repository shape as the Offers/Orders split earlier in this file.

class RiderMeOrderHistoryState extends Equatable {
  final RiderMeOrdersStatus status;
  final List<RiderMeOrderModel> orders;
  final String? errorMessage;

  const RiderMeOrderHistoryState({
    this.status = RiderMeOrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  RiderMeOrderHistoryState copyWith({
    RiderMeOrdersStatus? status,
    List<RiderMeOrderModel>? orders,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderMeOrderHistoryState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, orders, errorMessage];
}

class RiderMeOrderHistoryNotifier extends Notifier<RiderMeOrderHistoryState> {
  @override
  RiderMeOrderHistoryState build() => const RiderMeOrderHistoryState();

  RiderMeOrderRepository get _repo => sl<RiderMeOrderRepository>();

  Future<void> load({int? perPage}) async {
    state = state.copyWith(
        status: RiderMeOrdersStatus.loading, clearError: true);
    final result = await _repo.getOrders(filter: 'history', perPage: perPage);
    result.fold(
      (f) => state = state.copyWith(
          status: RiderMeOrdersStatus.error, errorMessage: f.message),
      (orders) => state = state.copyWith(
          status: RiderMeOrdersStatus.loaded, orders: orders),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final riderMeOrderHistoryProvider =
    NotifierProvider<RiderMeOrderHistoryNotifier, RiderMeOrderHistoryState>(
        RiderMeOrderHistoryNotifier.new);
