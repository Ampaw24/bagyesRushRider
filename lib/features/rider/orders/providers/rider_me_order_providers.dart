import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
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
  @override
  RiderMeOffersState build() => const RiderMeOffersState();

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

  /// Current delivery stage for [order] — the advanced-on-success stage if
  /// this session has actioned it, else a best-effort seed from its coarse
  /// `status`. See rider_delivery_stage.dart for why this can't come
  /// straight from the server.
  RiderDeliveryStage stageFor(RiderMeOrderModel order) =>
      stageByOrderId[order.id] ?? seedDeliveryStageFrom(order.status);

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

class RiderMeOrdersNotifier extends Notifier<RiderMeOrdersState> {
  @override
  RiderMeOrdersState build() => const RiderMeOrdersState();

  RiderMeOrderRepository get _repo => sl<RiderMeOrderRepository>();

  /// [filter] is `all` | `active` | `history` per the API contract.
  Future<void> load({String? filter, String? status, int? perPage}) async {
    state = state.copyWith(
        status: RiderMeOrdersStatus.loading, clearError: true);
    final result =
        await _repo.getOrders(filter: filter, status: status, perPage: perPage);
    result.fold(
      (f) => state = state.copyWith(
          status: RiderMeOrdersStatus.error, errorMessage: f.message),
      (orders) => state = state.copyWith(
          status: RiderMeOrdersStatus.loaded, orders: orders),
    );
  }

  Future<void> loadOrder(int orderId) async {
    final result = await _repo.getOrder(orderId);
    result.fold(
      (f) => state = state.copyWith(errorMessage: f.message),
      (order) => state = state.copyWith(selectedOrder: order),
    );
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

  Future<bool> pickUpOrder(int orderId) async {
    final ok = await _runAction(() => _repo.pickUpOrder(orderId));
    if (ok) _setStage(orderId, RiderDeliveryStage.pickedUp);
    return ok;
  }

  Future<bool> arrivedAtDropoff(int orderId) async {
    final ok = await _runAction(() => _repo.arrivedAtDropoff(orderId));
    if (ok) _setStage(orderId, RiderDeliveryStage.arrivedAtDropoff);
    return ok;
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

  /// Rider waited and can't reach the customer. ASSUMPTION (unconfirmed —
  /// backend unreachable while this was written): treated like [releaseOrder]
  /// — reload rather than a client-side list removal — as the safer
  /// optimistic default. Verify against a live account.
  Future<bool> markUnreachable(int orderId, {String? reason}) async {
    final ok =
        await _runAction(() => _repo.markUnreachable(orderId, reason: reason));
    if (ok) await load(filter: 'active');
    return ok;
  }

  Future<bool> arriveAtStop(int orderId, int stopId) async {
    final ok = await _runAction(() => _repo.arriveAtStop(orderId, stopId));
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
  /// success to resync its stop statuses, rather than the full active list.
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
    if (ok) await loadOrder(orderId);
    return ok;
  }

  Future<bool> failStop(int orderId, int stopId, {required String reason}) async {
    final ok =
        await _runAction(() => _repo.failStop(orderId, stopId, reason: reason));
    if (ok) await loadOrder(orderId);
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
