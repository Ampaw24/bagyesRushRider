import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/incoming_offer_logic.dart';

RiderMeOfferModel offer(int id, {String? expiresAt}) =>
    RiderMeOfferModel(id: id, expiresAt: expiresAt);

void main() {
  parcelDetectionTests();

  final now = DateTime.utc(2026, 10, 9, 12);

  test('a new live offer is announced', () {
    final result = offersToAnnounce(
      offers: [offer(1, expiresAt: '2026-10-09T12:01:00Z')],
      announcedIds: {},
      now: now,
    );
    expect(result.map((o) => o.id), [1]);
  });

  test('an offer is never announced twice', () {
    final result = offersToAnnounce(
      offers: [offer(1), offer(2)],
      announcedIds: {1},
      now: now,
    );
    expect(result.map((o) => o.id), [2]);
  });

  test('an already-expired offer is skipped', () {
    final result = offersToAnnounce(
      offers: [offer(1, expiresAt: '2026-10-09T11:59:59Z')],
      announcedIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('an offer with no or unparseable expiry counts as live', () {
    final result = offersToAnnounce(
      offers: [offer(1), offer(2, expiresAt: 'not a date')],
      announcedIds: {},
      now: now,
    );
    expect(result.map((o) => o.id), [1, 2]);
  });

  test('order is preserved so the earliest offer rings first', () {
    final result = offersToAnnounce(
      offers: [offer(3), offer(1), offer(2)],
      announcedIds: {},
      now: now,
    );
    expect(result.map((o) => o.id), [3, 1, 2]);
  });
}

void parcelDetectionTests() {
  RiderMeOfferModel parse(Map<String, dynamic> json) =>
      RiderMeOfferModel.fromJson({'id': 1, ...json});

  group('RiderMeOfferModel.isParcel', () {
    test('a plain order offer is not a parcel', () {
      expect(parse({'order': {'order_number': 'ORD-1'}}).isParcel, isFalse);
    });

    test('type / order_type naming a parcel, on the offer or its order', () {
      expect(parse({'type': 'parcel'}).isParcel, isTrue);
      expect(parse({'order_type': 'Parcel_Delivery'}).isParcel, isTrue);
      expect(parse({'order': {'type': 'parcel'}}).isParcel, isTrue);
    });

    test('a parcel object or parcel_id marks a parcel', () {
      expect(parse({'parcel': {'id': 9}}).isParcel, isTrue);
      expect(parse({'order': {'parcel_id': 9}}).isParcel, isTrue);
    });

    test('a stops list marks a parcel; an empty one does not', () {
      expect(
        parse({'order': {'stops': [{'id': 1}]}}).isParcel,
        isTrue,
      );
      expect(parse({'stops': <Object>[]}).isParcel, isFalse);
    });
  });
}
