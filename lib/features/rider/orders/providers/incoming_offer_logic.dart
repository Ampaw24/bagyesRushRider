import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';

/// Which of [offers] deserve the ring-and-dialog treatment right now: ones the
/// rider hasn't been told about yet ([announcedIds]) and that haven't already
/// expired. An offer with no expiry is treated as live.
///
/// Pure so it can be tested without a widget tree; the listener keeps the
/// announced set.
List<RiderMeOfferModel> offersToAnnounce({
  required List<RiderMeOfferModel> offers,
  required Set<int> announcedIds,
  required DateTime now,
}) {
  return offers.where((offer) {
    if (announcedIds.contains(offer.id)) return false;
    final expiresAt = offer.expiresAtTime;
    return expiresAt == null || expiresAt.isAfter(now);
  }).toList();
}
