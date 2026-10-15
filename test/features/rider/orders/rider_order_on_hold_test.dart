import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/reopened_order_logic.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';

/// A single drop-off order the rider has [arrived] at.
RiderMeOrderModel _drop({
  bool? canDeliver,
  String status = 'out_for_delivery',
  bool arrived = true,
}) =>
    RiderMeOrderModel(
      id: 1,
      status: status,
      canDeliver: canDeliver,
      arrivedAtDropoffAt: arrived ? '2026-10-14T10:00:00Z' : null,
    );

RiderMeOrderModel _parcel(
  List<RiderMeOrderStopModel> stops, {
  String status = 'out_for_delivery',
}) =>
    RiderMeOrderModel(id: 2, status: status, stops: stops);

RiderMeOrderStopModel _stop(int id, String status, {bool? canDeliver}) =>
    RiderMeOrderStopModel(id: id, status: status, canDeliver: canDeliver);

RiderMeOrdersState _with(List<RiderMeOrderModel> orders) =>
    RiderMeOrdersState(orders: orders);

void main() {
  const state = RiderMeOrdersState();

  group('isOnHold', () {
    test('a drop-off the rider gave up on is on hold until reopened', () {
      expect(state.isOnHold(_drop(canDeliver: false)), isTrue);
      expect(state.isOnHold(_drop(canDeliver: true)), isFalse);
      expect(state.isOnHold(_drop()), isFalse);
    });

    test('an early false never blocks the pickup steps', () {
      expect(
        state.isOnHold(
            _drop(canDeliver: false, status: 'accepted', arrived: false)),
        isFalse,
      );
    });

    test('a parcel is on hold only once every open stop has failed', () {
      expect(
        state.isOnHold(_parcel([_stop(1, 'delivered'), _stop(2, 'failed')])),
        isTrue,
      );
      expect(
        state.isOnHold(_parcel([_stop(1, 'failed'), _stop(2, 'pending')])),
        isFalse,
      );
      expect(
        state.isOnHold(_parcel([_stop(1, 'failed', canDeliver: true)])),
        isFalse,
      );
      expect(
        state.isOnHold(
            _parcel([_stop(1, 'delivered'), _stop(2, 'delivered')])),
        isFalse,
      );
    });

    test('a finished order is never on hold', () {
      expect(
          state.isOnHold(_drop(canDeliver: false, status: 'cancelled')),
          isFalse);
      expect(
        state.isOnHold(_parcel([_stop(1, 'failed')], status: 'delivered')),
        isFalse,
      );
    });

    test('an order on hold keeps its contact (still in progress)', () {
      expect(state.isInProgress(_drop(canDeliver: false)), isTrue);
    });
  });

  group('reopenedOrders', () {
    test('finds an order support made deliverable again', () {
      final reopened = reopenedOrders(
        _with([_drop(canDeliver: false)]),
        _with([_drop(canDeliver: true)]),
      );
      expect(reopened.map((o) => o.id), [1]);
    });

    test('finds a parcel whose failed stop was reopened', () {
      final reopened = reopenedOrders(
        _with([_parcel([_stop(1, 'failed')])]),
        _with([
          _parcel([_stop(1, 'failed', canDeliver: true)]),
        ]),
      );
      expect(reopened.map((o) => o.id), [2]);
    });

    test('ignores orders still on hold, newly on hold or finished', () {
      final onHold = _with([_drop(canDeliver: false)]);
      expect(reopenedOrders(onHold, onHold), isEmpty);
      expect(reopenedOrders(_with([_drop(canDeliver: true)]), onHold), isEmpty);
      expect(
        reopenedOrders(
            onHold, _with([_drop(canDeliver: false, status: 'cancelled')])),
        isEmpty,
      );
      expect(reopenedOrders(null, _with([_drop(canDeliver: true)])), isEmpty);
    });
  });
}
