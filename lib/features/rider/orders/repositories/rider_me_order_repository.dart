import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';

/// Contract for the `/rider/me` order lifecycle API — offer → accept →
/// arrived-at-pickup → pick-up → deliver (or per-stop deliver/fail).
/// See the "v1 / rider" Postman collection (order #1-11).
abstract class RiderMeOrderRepository {
  ResultFuture<List<RiderMeOfferModel>> getOffers();
  ResultFuture<void> acceptOffer(int offerId);
  ResultFuture<void> declineOffer(int offerId, {String? reason});

  ResultFuture<List<RiderMeOrderModel>> getOrders({
    String? filter, // all | active | history
    String? status,
    int? perPage,
  });
  ResultFuture<RiderMeOrderModel> getOrder(int orderId);

  ResultFuture<void> arrivedAtPickup(int orderId);
  ResultFuture<void> pickUpOrder(int orderId);
  ResultFuture<void> deliverOrder(
    int orderId, {
    String? deliveredToName,
    String? proofPhotoPath,
  });

  /// Hands an accepted order back to the dispatch pool.
  ResultFuture<void> releaseOrder(int orderId, {String? reason});

  ResultFuture<void> deliverStop(
    int orderId,
    int stopId, {
    String? deliveredToName,
    String? proofPhotoPath,
  });

  ResultFuture<void> failStop(
    int orderId,
    int stopId, {
    required String reason,
  });
}
