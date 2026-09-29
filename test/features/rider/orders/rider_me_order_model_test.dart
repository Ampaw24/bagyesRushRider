import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderMeOrderModel.fromJson', () {
    test('reads the nested Laravel resource shape', () {
      final order = RiderMeOrderModel.fromJson({
        'id': '17',
        'order_number': 'BR-000017',
        'status': 'ready',
        'vendor': {'name': 'Kofi Kitchen', 'address': 'Osu, Oxford St'},
        'delivery': {'address': 'East Legon, Lagos Ave'},
        'customer': {'first_name': 'Ama', 'last_name': 'Mensah', 'phone': '0240000000'},
        'totals': {'delivery_fee': '15.50', 'total': '120.00'},
      });

      expect(order.id, 17);
      expect(order.reference, 'BR-000017');
      expect(order.pickupAddress, 'Osu, Oxford St');
      expect(order.dropoffAddress, 'East Legon, Lagos Ave');
      expect(order.customerName, 'Ama Mensah');
      expect(order.customerPhone, '0240000000');
      expect(order.amount, 15.5);
    });

    test('still reads the flat shape', () {
      final order = RiderMeOrderModel.fromJson({
        'id': 4,
        'reference': 'ORD-4',
        'status': 'accepted',
        'pickup_address': 'A',
        'dropoff_address': 'B',
        'amount': 20,
      });

      expect(order.pickupAddress, 'A');
      expect(order.dropoffAddress, 'B');
      expect(order.amountFormatted, 'GHS 20.00');
    });

    test('falls back to the vendor name and single stop address', () {
      final order = RiderMeOrderModel.fromJson({
        'id': 5,
        'status': 'ready',
        'vendor': {'name': 'Kofi Kitchen'},
        'stops': [
          {'id': 1, 'address': {'formatted_address': 'Spintex Rd'}},
        ],
      });

      expect(order.pickupAddress, 'Kofi Kitchen');
      expect(order.dropoffAddress, 'Spintex Rd');
    });
  });

  // Trimmed from a real GET /rider/me/orders?filter=active response
  // (2026-09-28): parcel orders have no `customer`, only stop recipients.
  test('parcel order takes its contact from the stop recipient', () {
    final order = RiderMeOrderModel.fromJson({
      'id': 26,
      'order_number': 'BR-D8Q6FG3K',
      'type': 'parcel',
      'status': 'out_for_delivery',
      'stops': [
        {
          'id': 2,
          'sequence': 1,
          'address': 'MPHR+HG, Kwabenya, Ghana',
          'latitude': 5.67845056,
          'longitude': -0.25792491,
          'recipient_name': 'Ampaw',
          'recipient_phone': '233504987134',
          'status': 'pending',
          'delivered_to_name': null,
        },
      ],
      'next_stop': {
        'id': 2,
        'sequence': 1,
        'address': 'MPHR+HG, Kwabenya, Ghana',
        'recipient_name': 'Ampaw',
        'recipient_phone': '233504987134',
      },
    });

    expect(order.reference, 'BR-D8Q6FG3K');
    expect(order.customerName, 'Ampaw');
    expect(order.customerPhone, '233504987134');
    expect(order.dropoffAddress, 'MPHR+HG, Kwabenya, Ghana');
    expect(order.stops.single.recipientName, 'Ampaw');
    expect(order.stops.single.deliveredToName, isNull);
    expect(order.dropoffLatitude, 5.67845056);
    expect(order.dropoffLongitude, -0.25792491);
  });

  test('RiderMeOfferModel reads an inline order', () {
    final offer = RiderMeOfferModel.fromJson({
      'id': 9,
      'expires_at': '2026-09-28T12:00:00Z',
      'order': {
        'order_number': 'BR-9',
        'vendor': {'address': 'Osu'},
        'delivery': {'address': 'Tema'},
        'delivery_distance_km': '4.2',
        'totals': {'delivery_fee': 12},
      },
    });

    expect(offer.orderReference, 'BR-9');
    expect(offer.pickupAddress, 'Osu');
    expect(offer.dropoffAddress, 'Tema');
    expect(offer.distanceKm, 4.2);
    expect(offer.estimatedFare, 12);
  });
}
