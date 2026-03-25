import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';

abstract class RiderOrdersRepository {
  ResultFuture<List<RiderOrderModel>> getRequestedOrders(String userId);
  ResultFuture<List<RiderOrderModel>> getActiveOrders(String userId);
  ResultFuture<List<RiderOrderModel>> getHistory(String userId);
  ResultFuture<void> acceptOrder({
    required String orderId,
    required String courierId,
  });
  ResultFuture<void> rejectOrder({
    required String orderId,
    required String courierId,
    required String reason,
  });
  ResultFuture<void> updateOrderStatus({
    required String orderId,
    required String status,
  });
  ResultFuture<void> setTrip(Map<String, dynamic> data);
  ResultFuture<void> finishTrip(Map<String, dynamic> data);
}
