import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_delivery_progress.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_detail_sheet.dart';

/// A [RiderMeOrdersNotifier] with no network and no realtime socket. Its
/// "arrived at pickup" succeeds and moves the stage on, as the real one does.
class _FakeOrders extends RiderMeOrdersNotifier {
  final RiderMeOrderModel order;
  final Map<int, RiderDeliveryStage> stages;

  _FakeOrders(this.order, {this.stages = const {}});

  @override
  RiderMeOrdersState build() => RiderMeOrdersState(
        status: RiderMeOrdersStatus.loaded,
        orders: [order],
        stageByOrderId: stages,
      );

  @override
  Future<void> loadOrder(int orderId) async {}

  @override
  Future<bool> arrivedAtPickup(int orderId) async {
    state = state.copyWith(stageByOrderId: {
      ...state.stageByOrderId,
      orderId: RiderDeliveryStage.arrivedAtPickup,
    });
    return true;
  }
}

RiderMeOrderModel _order(String status, {String? customer}) =>
    RiderMeOrderModel(
      id: 7,
      reference: 'BR-000007',
      status: status,
      pickupAddress: 'Osu, Oxford St',
      dropoffAddress: 'East Legon, Lagos Ave',
      customerName: customer ?? 'Ama Mensah',
      customerPhone: '0240000000',
      amount: 25,
      createdAt: '2026-10-12 14:45:00',
    );

/// Opens the sheet over a phone-sized screen. [animate] false mirrors the
/// platform's reduced-motion setting; with it on, tests pump fixed durations,
/// since the Live dot's pulse loops and `pumpAndSettle` never settles.
Future<void> _openSheet(
  WidgetTester tester,
  RiderMeOrderModel order, {
  bool animate = false,
  Size size = const Size(390, 844),
  double textScale = 1,
  Map<int, RiderDeliveryStage> stages = const {},
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      riderMeOrdersProvider
          .overrideWith(() => _FakeOrders(order, stages: stages)),
    ],
    child: MaterialApp(
      // Above the Navigator, so the modal sheet's route sees it too.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: !animate,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => RiderMeOrderDetailSheet(initialOrder: order),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  // Sheet slide-up plus the staggered section reveal.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('leads with the status band, summary and next step',
      (tester) async {
    await _openSheet(tester, _order('ready'));

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Oct 12, 2:45 PM'), findsOneWidget);
    expect(find.text('BR-000007'), findsOneWidget);
    expect(find.text('GHS 25.00'), findsOneWidget);
    expect(find.byType(RiderDeliveryProgress), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Arrived at Pickup'),
        findsOneWidget);
  });

  testWidgets('completing a step slides the next one in', (tester) async {
    await _openSheet(tester, _order('ready'), animate: true);

    await tester.tap(find.text('Arrived at Pickup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Mid-transition the old step is leaving as the new one arrives.
    expect(find.text('Arrived at Pickup'), findsOneWidget);
    expect(find.text('Confirm Pickup'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Arrived at Pickup'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Confirm Pickup'),
        findsOneWidget);
  });

  testWidgets('a finished order shows Close, without the Live cue or progress',
      (tester) async {
    await _openSheet(tester, _order('delivered'));

    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
    expect(find.byType(RiderDeliveryProgress), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Close'), findsOneWidget);
  });

  group('customer contact', () {
    final call = find.byTooltip('Call customer');
    final chat = find.byTooltip('Chat with customer');

    testWidgets('an order in progress shows the number, chat and call',
        (tester) async {
      await _openSheet(tester, _order('out_for_delivery'));

      expect(find.text('0240000000'), findsOneWidget);
      expect(call, findsOneWidget);
      expect(chat, findsOneWidget);
    });

    for (final status in ['delivered', 'cancelled', 'rejected', 'refunded']) {
      testWidgets('a $status order masks the number and drops chat and call',
          (tester) async {
        await _openSheet(tester, _order(status));

        expect(find.text('0240000000'), findsNothing);
        expect(find.text('024•••••00'), findsOneWidget);
        expect(call, findsNothing);
        expect(chat, findsNothing);
      });
    }

    // The server can still say out_for_delivery after the rider has
    // finished every stop — the order is over for them all the same.
    testWidgets('an order the rider has finished masks it too',
        (tester) async {
      await _openSheet(
        tester,
        _order('out_for_delivery'),
        stages: {7: RiderDeliveryStage.delivered},
      );

      expect(find.text('024•••••00'), findsOneWidget);
      expect(call, findsNothing);
      expect(chat, findsNothing);
    });
  });

  testWidgets('a customer name starting with an emoji does not crash it',
      (tester) async {
    await _openSheet(tester, _order('ready', customer: '😊 Ama'));

    expect(tester.takeException(), isNull);
    expect(find.text('😊A'), findsOneWidget);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    await _openSheet(
      tester,
      _order('out_for_delivery'),
      size: const Size(320, 568),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
  });
}
