import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';

/// Contract for the `/rider/me` order lifecycle API — offer → accept →
/// arrived-at-pickup → pick-up → arrived-at-dropoff → deliver (or per-stop
/// arrived → deliver/fail). See the "v1 / rider" Postman collection
/// (order #1-14).
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
  ResultFuture<void> arrivedAtDropoff(int orderId);

  /// `deliveryPin` is required — 4 digits, sent as a string so a leading
  /// zero survives.
  ResultFuture<void> deliverOrder(
    int orderId, {
    required String deliveryPin,
    String? deliveredToName,
    String? proofPhotoPath,
  });

  /// Hands an accepted order back to the dispatch pool.
  ResultFuture<void> releaseOrder(int orderId, {String? reason});

  /// Rider waited and can't reach the customer — order-level, not per-stop.
  ResultFuture<void> markUnreachable(int orderId, {String? reason});

  ResultFuture<void> arriveAtStop(int orderId, int stopId);

  /// See [deliverOrder] re: `deliveryPin`.
  ResultFuture<void> deliverStop(
    int orderId,
    int stopId, {
    required String deliveryPin,
    String? deliveredToName,
    String? proofPhotoPath,
  });

  ResultFuture<void> failStop(
    int orderId,
    int stopId, {
    required String reason,
  });
}
