import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
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

  Future<void> load() async {
    state = state.copyWith(
        status: RiderMeOrdersStatus.loading, clearError: true);
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

  const RiderMeOrdersState({
    this.status = RiderMeOrdersStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.errorMessage,
    this.actionStatus = RiderMeActionStatus.idle,
    this.actionMessage,
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
      );

  @override
  List<Object?> get props => [
        status,
        orders,
        selectedOrder,
        errorMessage,
        actionStatus,
        actionMessage,
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

  void selectOrder(RiderMeOrderModel order) =>
      state = state.copyWith(selectedOrder: order);

  Future<bool> _runAction(Future<void> Function() action) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    try {
      await action();
      state = state.copyWith(actionStatus: RiderMeActionStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        actionStatus: RiderMeActionStatus.error,
        actionMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> arrivedAtPickup(int orderId) => _runAction(() async {
        final result = await _repo.arrivedAtPickup(orderId);
        result.fold((f) => throw Exception(f.message), (_) {});
      });

  Future<bool> pickUpOrder(int orderId) => _runAction(() async {
        final result = await _repo.pickUpOrder(orderId);
        result.fold((f) => throw Exception(f.message), (_) {});
      });

  Future<bool> deliverOrder(
    int orderId, {
    String? deliveredToName,
    String? proofPhotoPath,
  }) =>
      _runAction(() async {
        final result = await _repo.deliverOrder(
          orderId,
          deliveredToName: deliveredToName,
          proofPhotoPath: proofPhotoPath,
        );
        result.fold((f) => throw Exception(f.message), (_) {});
      });

  Future<bool> releaseOrder(int orderId, {String? reason}) =>
      _runAction(() async {
        final result = await _repo.releaseOrder(orderId, reason: reason);
        result.fold((f) => throw Exception(f.message), (_) {});
      });

  Future<bool> deliverStop(
    int orderId,
    int stopId, {
    String? deliveredToName,
    String? proofPhotoPath,
  }) =>
      _runAction(() async {
        final result = await _repo.deliverStop(
          orderId,
          stopId,
          deliveredToName: deliveredToName,
          proofPhotoPath: proofPhotoPath,
        );
        result.fold((f) => throw Exception(f.message), (_) {});
      });

  Future<bool> failStop(int orderId, int stopId, {required String reason}) =>
      _runAction(() async {
        final result =
            await _repo.failStop(orderId, stopId, reason: reason);
        result.fold((f) => throw Exception(f.message), (_) {});
      });

  void clearActionStatus() =>
      state = state.copyWith(actionStatus: RiderMeActionStatus.idle);
}

final riderMeOrdersProvider =
    NotifierProvider<RiderMeOrdersNotifier, RiderMeOrdersState>(
        RiderMeOrdersNotifier.new);
