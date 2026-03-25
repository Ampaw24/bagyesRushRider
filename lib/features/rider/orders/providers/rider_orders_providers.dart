import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_orders_repository.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

enum OrdersStatus { initial, loading, loaded, error }

String _userId() =>
    sl<UserSessionManager>().currentUser?['_id'] as String? ?? '';

// ── New Orders ────────────────────────────────────────────────────────────────

class NewOrdersState extends Equatable {
  final OrdersStatus status;
  final List<RiderOrderModel> orders;
  final String? errorMessage;

  const NewOrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.errorMessage,
  });

  NewOrdersState copyWith({
    OrdersStatus? status,
    List<RiderOrderModel>? orders,
    String? errorMessage,
    bool clearError = false,
  }) =>
      NewOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, orders, errorMessage];
}

class NewOrdersNotifier extends Notifier<NewOrdersState> {
  @override
  NewOrdersState build() => const NewOrdersState();

  RiderOrdersRepository get _repo => sl<RiderOrdersRepository>();

  Future<void> load() async {
    state = state.copyWith(status: OrdersStatus.loading, clearError: true);
    final result = await _repo.getRequestedOrders(_userId());
    result.fold(
      (f) => state = state.copyWith(
          status: OrdersStatus.error, errorMessage: f.message),
      (orders) => state =
          state.copyWith(status: OrdersStatus.loaded, orders: orders),
    );
  }

  Future<bool> acceptOrder({
    required String orderId,
    required String courierId,
  }) async {
    final result = await _repo.acceptOrder(
        orderId: orderId, courierId: courierId);
    return result.fold(
      (f) {
        state = state.copyWith(errorMessage: f.message);
        return false;
      },
      (_) {
        load();
        return true;
      },
    );
  }

  Future<bool> rejectOrder({
    required String orderId,
    required String courierId,
    required String reason,
  }) async {
    final result = await _repo.rejectOrder(
        orderId: orderId, courierId: courierId, reason: reason);
    return result.fold(
      (f) {
        state = state.copyWith(errorMessage: f.message);
        return false;
      },
      (_) {
        load();
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final newOrdersProvider =
    NotifierProvider<NewOrdersNotifier, NewOrdersState>(NewOrdersNotifier.new);

// ── Active Orders ─────────────────────────────────────────────────────────────

class ActiveOrdersState extends Equatable {
  final OrdersStatus status;
  final List<RiderOrderModel> orders;
  final RiderOrderModel? selectedOrder;
  final String? errorMessage;

  const ActiveOrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.errorMessage,
  });

  ActiveOrdersState copyWith({
    OrdersStatus? status,
    List<RiderOrderModel>? orders,
    RiderOrderModel? selectedOrder,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ActiveOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        selectedOrder: selectedOrder ?? this.selectedOrder,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, orders, selectedOrder, errorMessage];
}

class ActiveOrdersNotifier extends Notifier<ActiveOrdersState> {
  @override
  ActiveOrdersState build() => const ActiveOrdersState();

  RiderOrdersRepository get _repo => sl<RiderOrdersRepository>();

  Future<void> load() async {
    state = state.copyWith(status: OrdersStatus.loading, clearError: true);
    final result = await _repo.getActiveOrders(_userId());
    result.fold(
      (f) => state = state.copyWith(
          status: OrdersStatus.error, errorMessage: f.message),
      (orders) => state =
          state.copyWith(status: OrdersStatus.loaded, orders: orders),
    );
  }

  void selectOrder(RiderOrderModel order) {
    state = state.copyWith(selectedOrder: order);
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final result =
        await _repo.updateOrderStatus(orderId: orderId, status: status);
    return result.fold(
      (f) {
        state = state.copyWith(errorMessage: f.message);
        return false;
      },
      (_) {
        load();
        return true;
      },
    );
  }

  Future<bool> setTrip(Map<String, dynamic> data) async {
    final result = await _repo.setTrip(data);
    return result.fold(
      (f) {
        state = state.copyWith(errorMessage: f.message);
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> finishTrip(Map<String, dynamic> data) async {
    final result = await _repo.finishTrip(data);
    return result.fold(
      (f) {
        state = state.copyWith(errorMessage: f.message);
        return false;
      },
      (_) => true,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final activeOrdersProvider =
    NotifierProvider<ActiveOrdersNotifier, ActiveOrdersState>(
        ActiveOrdersNotifier.new);

// ── Order History ─────────────────────────────────────────────────────────────

class OrderHistoryState extends Equatable {
  final OrdersStatus status;
  final List<RiderOrderModel> orders;
  final RiderOrderModel? selectedOrder;
  final String? errorMessage;

  const OrderHistoryState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.errorMessage,
  });

  OrderHistoryState copyWith({
    OrdersStatus? status,
    List<RiderOrderModel>? orders,
    RiderOrderModel? selectedOrder,
    String? errorMessage,
    bool clearError = false,
  }) =>
      OrderHistoryState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        selectedOrder: selectedOrder ?? this.selectedOrder,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, orders, selectedOrder, errorMessage];
}

class OrderHistoryNotifier extends Notifier<OrderHistoryState> {
  @override
  OrderHistoryState build() => const OrderHistoryState();

  RiderOrdersRepository get _repo => sl<RiderOrdersRepository>();

  Future<void> load() async {
    state = state.copyWith(status: OrdersStatus.loading, clearError: true);
    final result = await _repo.getHistory(_userId());
    result.fold(
      (f) => state = state.copyWith(
          status: OrdersStatus.error, errorMessage: f.message),
      (orders) => state =
          state.copyWith(status: OrdersStatus.loaded, orders: orders),
    );
  }

  void selectOrder(RiderOrderModel order) {
    state = state.copyWith(selectedOrder: order);
  }
}

final orderHistoryProvider =
    NotifierProvider<OrderHistoryNotifier, OrderHistoryState>(
        OrderHistoryNotifier.new);
