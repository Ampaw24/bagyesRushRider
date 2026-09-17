import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderMeOrderModel.fromJson', () {
    test('parses a single-drop order with no stops', () {
      final order = RiderMeOrderModel.fromJson({
        'id': 1,
        'reference': 'ORD-001',
        'status': 'out_for_delivery',
        'pickup_address': '12 High Street',
        'dropoff_address': '5 Ring Road',
        'customer_name': 'Ama',
        'customer_phone': '0244000000',
        'amount': 45.5,
      });

      expect(order.id, 1);
      expect(order.status, 'out_for_delivery');
      expect(order.isMultiStop, isFalse);
      expect(order.isActive, isTrue);
      expect(order.stops, isEmpty);
      expect(order.amountFormatted, 'GHS 45.50');
    });

    test('parses a multi-stop order and each stop\'s delivered/failed state',
        () {
      final order = RiderMeOrderModel.fromJson({
        'id': 2,
        'status': 'out_for_delivery',
        'stops': [
          {'id': 10, 'sequence': 1, 'status': 'delivered', 'address': 'Stop A'},
          {'id': 11, 'sequence': 2, 'status': 'failed', 'address': 'Stop B',
            'failure_reason': 'No answer'},
          {'id': 12, 'sequence': 3, 'status': 'pending', 'address': 'Stop C'},
        ],
      });

      expect(order.isMultiStop, isTrue);
      expect(order.stops, hasLength(3));

      expect(order.stops[0].isDelivered, isTrue);
      expect(order.stops[0].isFailed, isFalse);

      expect(order.stops[1].isFailed, isTrue);
      expect(order.stops[1].isDelivered, isFalse);
      expect(order.stops[1].failureReason, 'No answer');

      expect(order.stops[2].isDelivered, isFalse);
      expect(order.stops[2].isFailed, isFalse);
    });

    test('treats a terminal status as inactive', () {
      final order =
          RiderMeOrderModel.fromJson({'id': 3, 'status': 'delivered'});
      expect(order.isActive, isFalse);
    });

    test('defaults status to pending and stops to empty when absent', () {
      final order = RiderMeOrderModel.fromJson({'id': 4});
      expect(order.status, 'pending');
      expect(order.stops, isEmpty);
      expect(order.amountFormatted, '');
    });
  });
}
