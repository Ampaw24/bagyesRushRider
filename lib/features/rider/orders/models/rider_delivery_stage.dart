/// Client-side, per-order delivery stage — tracks "what's the next rider
/// action" through the arrived-at-pickup → pick-up → arrived-at-dropoff (or
/// per-stop arrived) → deliver sequence.
///
/// This has no server counterpart: `RiderMeOrderModel.status` is one of 10
/// coarse, platform-wide values (`kRiderMeOrderStatuses`) with no discrete
/// arrived/picked-up/arrived-at-dropoff states, and the order payload has no
/// per-action timestamps either. Stage is therefore tracked entirely
/// in-memory in `RiderMeOrdersState`, advanced optimistically as each action
/// call succeeds, and is NOT persisted — a rider who force-quits mid-delivery
/// sees it reset to a best-effort guess (via [seedDeliveryStageFrom]) on
/// next load, not the exact stage they left off at.
enum RiderDeliveryStage {
  notStarted,
  arrivedAtPickup,
  pickedUp,
  arrivedAtDropoff,
  delivered,
  closed,
}

/// Best-effort seed from the coarse `status` on `GET rider/me/orders[/:id]`.
///
/// HEURISTIC — `kRiderMeOrderStatuses` has no discrete arrived/picked-up/
/// arrived-at-dropoff values, so this can only distinguish "not yet
/// actioned" from "out for delivery" (at least picked up) from "delivered"
/// from "closed" (cancelled/rejected/refunded).
/// VERIFY LIVE: if a real order payload turns out to carry per-stage
/// timestamps (e.g. arrived_at_pickup_at / picked_up_at /
/// arrived_at_dropoff_at), prefer those over this seed once confirmed.
RiderDeliveryStage seedDeliveryStageFrom(String status) {
  switch (status) {
    // The one coarse status that does imply progress: the package has left
    // the pickup. Without this, a rider who restarts mid-delivery is shown
    // "Arrived at Pickup" again for an order already in hand.
    case 'out_for_delivery':
      return RiderDeliveryStage.pickedUp;
    case 'delivered':
      return RiderDeliveryStage.delivered;
    case 'cancelled':
    case 'rejected':
    case 'refunded':
      return RiderDeliveryStage.closed;
    default:
      return RiderDeliveryStage.notStarted;
  }
}

extension RiderDeliveryStageX on RiderDeliveryStage {
  /// Label of the button that moves the order out of this stage, or `null`
  /// when the rider has nothing left to do. A multi-stop order past pickup
  /// is advanced per stop, so it gets a generic prompt instead.
  String? nextActionLabel({required bool isMultiStop}) => switch (this) {
        RiderDeliveryStage.notStarted => 'Arrived at Pickup',
        RiderDeliveryStage.arrivedAtPickup => 'Confirm Pickup',
        RiderDeliveryStage.pickedUp =>
          isMultiStop ? 'Update Stops' : 'Arrived at Drop-off',
        RiderDeliveryStage.arrivedAtDropoff => 'Complete Delivery',
        RiderDeliveryStage.delivered || RiderDeliveryStage.closed => null,
      };

  /// How many of the four delivery milestones (at pickup, picked up, at
  /// drop-off, delivered) are complete.
  int get completedSteps => switch (this) {
        RiderDeliveryStage.notStarted => 0,
        RiderDeliveryStage.arrivedAtPickup => 1,
        RiderDeliveryStage.pickedUp => 2,
        RiderDeliveryStage.arrivedAtDropoff => 3,
        RiderDeliveryStage.delivered => 4,
        RiderDeliveryStage.closed => 0,
      };
}
