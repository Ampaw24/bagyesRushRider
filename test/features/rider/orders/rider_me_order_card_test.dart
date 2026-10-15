import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_delivery_progress.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';

RiderMeOrderModel _order(String status, {String? dropoff}) =>
    RiderMeOrderModel(
      id: 7,
      reference: 'BR-000007',
      status: status,
      pickupAddress: 'Osu, Oxford St',
      dropoffAddress: dropoff ?? 'East Legon, Lagos Ave',
      amount: 25,
      createdAt: '2026-10-12 14:45:00',
    );

/// [animate] false mirrors the platform's reduced-motion setting. Tests that
/// leave it on must pump fixed durations: the Live dot's pulse loops, so
/// `pumpAndSettle` never settles.
Widget _host(Widget child, {bool animate = false, double textScale = 1}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: !animate,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('leads with the status, and a Live cue only while in progress',
      (tester) async {
    for (final status in kRiderMeOrderStatuses) {
      final order = _order(status);
      await tester.pumpWidget(_host(
        RiderMeOrderCard(key: ValueKey(status), order: order, onTap: () {}),
      ));

      expect(find.text(riderMeOrderStatusLabel(status)), findsOneWidget,
          reason: status);
      expect(find.byIcon(riderMeOrderStatusIcon(status)), findsOneWidget,
          reason: status);
      expect(find.text('Live'), order.isActive ? findsOneWidget : findsNothing,
          reason: status);
      expect(find.text('Oct 12, 2:45 PM'), findsOneWidget, reason: status);
    }
  });

  testWidgets('an Active card shows delivery progress and the next step',
      (tester) async {
    await tester.pumpWidget(_host(RiderMeOrderCard(
      order: _order('out_for_delivery'),
      stage: RiderDeliveryStage.pickedUp,
      actionLabel: 'Arrived at Drop-off',
      onTap: () {},
    )));

    expect(find.byType(RiderDeliveryProgress), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Arrived at Drop-off'),
        findsOneWidget);
    // The arrow sits in the button; there is no chevron beside the amount.
    expect(find.byIcon(HugeIcons.strokeRoundedArrowRight01), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byIcon(HugeIcons.strokeRoundedArrowRight01),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a History card has no progress or button, just a chevron',
      (tester) async {
    await tester.pumpWidget(_host(
      RiderMeOrderCard(order: _order('delivered'), onTap: () {}),
    ));

    expect(find.byType(RiderDeliveryProgress), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(HugeIcons.strokeRoundedArrowRight01), findsOneWidget);
  });

  testWidgets('a status change cross-fades the header', (tester) async {
    Widget card(String status) => _host(
          RiderMeOrderCard(order: _order(status), onTap: () {}),
          animate: true,
        );

    await tester.pumpWidget(card('accepted'));
    await tester.pumpWidget(card('out_for_delivery'));
    await tester.pump(const Duration(milliseconds: 150));

    // Mid-transition both labels are on screen.
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Out for Delivery'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Accepted'), findsNothing);
    expect(find.text('Out for Delivery'), findsOneWidget);
  });

  testWidgets('tapping the card or its button opens the order',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(RiderMeOrderCard(
      order: _order('ready'),
      stage: RiderDeliveryStage.notStarted,
      actionLabel: 'Arrived at Pickup',
      onTap: () => taps++,
    )));

    await tester.tap(find.text('BR-000007'));
    await tester.tap(find.text('Arrived at Pickup'));
    expect(taps, 2);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      RiderMeOrderCard(
        order: _order(
          'pending_payment',
          dropoff: 'Block 12, Spintex Road, opposite the Shell filling '
              'station, Accra',
        ),
        stage: RiderDeliveryStage.arrivedAtDropoff,
        actionLabel: 'Complete Delivery',
        onTap: () {},
      ),
      textScale: 1.5,
    ));

    expect(tester.takeException(), isNull);
  });

  testWidgets('an order on hold shows the On hold cue instead of Live',
      (tester) async {
    await tester.pumpWidget(_host(RiderMeOrderCard(
      order: _order('out_for_delivery'),
      onHold: true,
      actionLabel: 'View order',
      onTap: () {},
    )));

    expect(find.text('On hold'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
  });
}
