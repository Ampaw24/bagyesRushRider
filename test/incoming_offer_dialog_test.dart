import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_incoming_offer_dialog.dart';

Future<void> pumpDialog(WidgetTester tester, RiderMeOfferModel offer) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: RiderIncomingOfferDialog(offer: offer)),
      ),
    ),
  );
}

void main() {
  testWidgets('a normal offer keeps the notification icon', (tester) async {
    await pumpDialog(tester, const RiderMeOfferModel(id: 1));

    expect(find.byIcon(HugeIcons.strokeRoundedNotification01), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a parcel offer shows the parcel image instead', (tester) async {
    await pumpDialog(tester, const RiderMeOfferModel(id: 1, isParcel: true));

    expect(find.byIcon(HugeIcons.strokeRoundedNotification01), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel('Parcel delivery'), findsOneWidget);
  });
}
