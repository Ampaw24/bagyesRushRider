import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_reopened_listener.dart';

/// Starts with one order on hold; [reopen] is support resolving it.
class _FakeOrders extends RiderMeOrdersNotifier {
  @override
  RiderMeOrdersState build() => RiderMeOrdersState(
        status: RiderMeOrdersStatus.loaded,
        orders: [_order(canDeliver: false)],
      );

  void reopen() => state = state.copyWith(orders: [_order(canDeliver: true)]);
}

RiderMeOrderModel _order({required bool canDeliver}) => RiderMeOrderModel(
      id: 7,
      reference: 'BR-000007',
      status: 'out_for_delivery',
      arrivedAtDropoffAt: '2026-10-14T10:00:00Z',
      canDeliver: canDeliver,
    );

void main() {
  testWidgets('tells the rider when support reopens an order', (tester) async {
    final fake = _FakeOrders();
    await tester.pumpWidget(ProviderScope(
      overrides: [riderMeOrdersProvider.overrideWith(() => fake)],
      child: const MaterialApp(
        home: RiderOrderReopenedListener(child: Scaffold()),
      ),
    ));
    expect(find.text('Delivery reopened'), findsNothing);

    fake.reopen();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Delivery reopened'), findsOneWidget);
    expect(find.text('BR-000007 can be delivered again.'), findsOneWidget);

    // Let the toast dismiss itself, so no timer is left running.
    await tester.pump(const Duration(seconds: 5));
  });
}
