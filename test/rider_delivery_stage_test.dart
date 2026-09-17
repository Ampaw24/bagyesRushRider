import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seedDeliveryStageFrom', () {
    test('maps delivered to RiderDeliveryStage.delivered', () {
      expect(seedDeliveryStageFrom('delivered'), RiderDeliveryStage.delivered);
    });

    test('maps terminal non-delivered statuses to closed', () {
      for (final status in ['cancelled', 'rejected', 'refunded']) {
        expect(seedDeliveryStageFrom(status), RiderDeliveryStage.closed,
            reason: status);
      }
    });

    test('maps every other documented status to notStarted', () {
      // kRiderMeOrderStatuses has no discrete arrived/picked-up value, so
      // these can only ever seed as "not yet actioned" — the rest of the
      // sequence is tracked client-side once an action succeeds.
      for (final status in [
        'pending_payment',
        'pending',
        'accepted',
        'preparing',
        'ready',
        'out_for_delivery',
      ]) {
        expect(seedDeliveryStageFrom(status), RiderDeliveryStage.notStarted,
            reason: status);
      }
    });

    test('falls back to notStarted for an unrecognised value', () {
      expect(seedDeliveryStageFrom('something_new'),
          RiderDeliveryStage.notStarted);
    });
  });
}
