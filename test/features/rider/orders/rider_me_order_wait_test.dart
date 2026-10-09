import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';

// Trimmed `data` of POST /rider/me/orders/:id/arrived-at-dropoff.
Map<String, dynamic> _arrivedJson({Map<String, dynamic>? wait}) => {
      'id': 8,
      'order_number': 'BR-7K2QX9MD',
      'status': 'out_for_delivery',
      'stops': null,
      'next_stop': null,
      'dropoff': {'name': 'Ama Mensah', 'address': 'Taifa'},
      'timeline': {'arrived_at_dropoff': '2026-10-09T10:57:30.000000Z'},
      'wait': wait ??
          {
            'started_at': '2026-10-09T10:57:30.000000Z',
            'expires_at': '2026-10-09T11:05:30.000000Z',
            'seconds_left': 352,
            'has_expired': false,
          },
      'can_give_up': false,
    };

void main() {
  test('parses the wait window and arrival fields', () {
    final order = RiderMeOrderModel.fromJson(_arrivedJson());
    expect(order.wait!.secondsLeft, 352);
    expect(order.wait!.total, const Duration(minutes: 8));
    expect(order.canGiveUp, false);
    expect(order.arrivedAtDropoffAt, '2026-10-09T10:57:30.000000Z');
  });

  test('counts down from the server seconds_left, not the phone clock', () {
    final wait = RiderMeOrderModel.fromJson(_arrivedJson()).wait!;
    final at = wait.receivedAt;
    expect(wait.remainingAt(at), const Duration(seconds: 352));
    expect(wait.remainingAt(at.add(const Duration(seconds: 100))),
        const Duration(seconds: 252));
    expect(wait.remainingAt(at.add(const Duration(seconds: 400))),
        Duration.zero);
  });

  test('has_expired wins over seconds_left', () {
    final wait = RiderMeOrderModel.fromJson(_arrivedJson(wait: {
      'seconds_left': 30,
      'has_expired': true,
    })).wait!;
    expect(wait.remainingAt(wait.receivedAt), Duration.zero);
  });

  test('absent wait stays null', () {
    final json = _arrivedJson()..remove('wait')..remove('timeline');
    final order = RiderMeOrderModel.fromJson(json);
    expect(order.wait, isNull);
    expect(order.hasArrivedAtDropoff, isFalse);
  });

  test('an order that already arrived restores the dropoff stage', () {
    final arrived = RiderMeOrderModel.fromJson(_arrivedJson());
    expect(const RiderMeOrdersState().stageFor(arrived),
        RiderDeliveryStage.arrivedAtDropoff);

    final notArrived = RiderMeOrderModel.fromJson(
        _arrivedJson()..remove('wait')..remove('timeline'));
    expect(const RiderMeOrdersState().stageFor(notArrived),
        RiderDeliveryStage.pickedUp);
  });

  test('parses a stop\'s waiting window (since / seconds_left)', () {
    final order = RiderMeOrderModel.fromJson({
      'id': 91,
      'status': 'out_for_delivery',
      'wait': null,
      'stops': [
        {
          'id': 301,
          'status': 'pending',
          'waiting': {
            'since': '2026-10-09T12:31:00.000000Z',
            'expires_at': '2026-10-09T12:39:00.000000Z',
            'seconds_left': 290,
            'has_expired': false,
          },
        },
        {'id': 302, 'status': 'pending', 'waiting': null},
      ],
    });
    final arrived = order.stops[0].wait!;
    expect(arrived.total, const Duration(minutes: 8));
    expect(arrived.remainingAt(arrived.receivedAt), const Duration(seconds: 290));
    expect(order.stops[1].wait, isNull);
    // Per-stop waits don't make a multi-stop order "arrived at drop-off".
    expect(order.hasArrivedAtDropoff, isFalse);
  });
}
