import 'package:gopady_rider/features/rider/orders/models/rider_me_order_model.dart';
import 'package:gopady_rider/features/rider/orders/providers/rider_me_order_providers.dart';

/// Orders support has just reopened: on hold in [previous] (see
/// [RiderMeOrdersState.isOnHold]) and, in [next], still active but no
/// longer on hold — `can_deliver` turned back to true.
///
/// Pure so it can be tested without a widget tree; the listener announces
/// what it returns.
List<RiderMeOrderModel> reopenedOrders(
  RiderMeOrdersState? previous,
  RiderMeOrdersState next,
) {
  if (previous == null) return const [];
  final before = {for (final o in previous.orders) o.id: o};
  return next.orders.where((order) {
    final was = before[order.id];
    return was != null &&
        previous.isOnHold(was) &&
        order.isActive &&
        !next.isOnHold(order);
  }).toList();
}
