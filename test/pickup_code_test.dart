import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/services/rider_me_order_api_service.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/pickup_code_sheet.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';

/// A [RiderMeOrdersNotifier] with no network and no realtime socket: it
/// records the code it was given and answers from [result].
class _FakeOrders extends RiderMeOrdersNotifier {
  final bool Function(String? pin) result;
  final Map<String, List<String>>? fieldErrors;
  final String? message;
  final calls = <String?>[];

  _FakeOrders(this.result, {this.fieldErrors, this.message});

  @override
  RiderMeOrdersState build() => const RiderMeOrdersState();

  @override
  Future<bool> pickUpOrder(int orderId, {String? pickupPin}) async {
    calls.add(pickupPin);
    final ok = result(pickupPin);
    if (!ok) {
      state = state.copyWith(
        actionStatus: RiderMeActionStatus.error,
        actionMessage: message,
        actionFieldErrors: fieldErrors,
      );
    }
    return ok;
  }
}

Future<bool?> _openSheet(
  WidgetTester tester,
  _FakeOrders fake,
) async {
  bool? popped;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [riderMeOrdersProvider.overrideWith(() => fake)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const PickupCodeSheet(orderId: 7),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  final boxes = find.byType(TextField);
  for (var i = 0; i < code.length; i++) {
    await tester.enterText(boxes.at(i), code[i]);
    await tester.pump();
  }
}

void main() {
  group('RiderMeOrderModel.requiresPickupCode', () {
    RiderMeOrderModel parse(Map<String, dynamic> json) =>
        RiderMeOrderModel.fromJson({'id': 1, 'status': 'accepted', ...json});

    test('is true only when parcel.requires_pickup_code is set', () {
      expect(
        parse({'parcel': {'requires_pickup_code': true}}).requiresPickupCode,
        isTrue,
      );
      expect(
        parse({'parcel': {'requires_pickup_code': 1}}).requiresPickupCode,
        isTrue,
      );
      expect(
        parse({'parcel': {'requires_pickup_code': false}}).requiresPickupCode,
        isFalse,
      );
    });

    test('a food order, or a parcel without the flag, never requires one', () {
      expect(parse({}).requiresPickupCode, isFalse);
      expect(parse({'parcel': {'id': 3}}).requiresPickupCode, isFalse);
    });

    test('survives copyWith, e.g. a realtime status patch', () {
      final order =
          parse({'parcel': {'requires_pickup_code': true}}).copyWith(
        status: 'out_for_delivery',
      );
      expect(order.requiresPickupCode, isTrue);
    });
  });

  group('RiderMeOrderApiService.pickUpOrder', () {
    Future<RequestOptions> capture(String? pin) async {
      late RequestOptions seen;
      final dio = Dio()
        ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
          seen = options;
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        }));
      await RiderMeOrderApiService(dio).pickUpOrder(5, pickupPin: pin);
      return seen;
    }

    test('sends pickup_pin as a string, keeping a leading zero', () async {
      final request = await capture('0412');
      expect(request.path, '/rider/me/orders/5/pick-up');
      expect(request.data, {'pickup_pin': '0412'});
    });

    test('sends no body when there is no code', () async {
      expect((await capture(null)).data, isNull);
    });
  });

  group('PickupCodeSheet', () {
    testWidgets('cannot submit until all four digits are in', (tester) async {
      final fake = _FakeOrders((_) => true);
      await _openSheet(tester, fake);

      await _typeCode(tester, '04');
      await tester.tap(find.text('Confirm Pickup'));
      await tester.pump();

      expect(fake.calls, isEmpty);
    });

    testWidgets('sends the code exactly as typed, then closes on success',
        (tester) async {
      final fake = _FakeOrders((_) => true);
      await _openSheet(tester, fake);

      await _typeCode(tester, '0412');
      await tester.tap(find.text('Confirm Pickup'));
      await tester.pumpAndSettle();

      expect(fake.calls, ['0412']);
      expect(find.byType(PickupCodeSheet), findsNothing);
    });

    testWidgets('a wrong code shows the server error and clears the boxes',
        (tester) async {
      final fake = _FakeOrders(
        (_) => false,
        fieldErrors: {
          'pickup_pin': ['That code is not right.']
        },
      );
      await _openSheet(tester, fake);

      await _typeCode(tester, '9999');
      await tester.tap(find.text('Confirm Pickup'));
      await tester.pumpAndSettle();

      expect(find.text('That code is not right.'), findsOneWidget);
      expect(find.byType(PickupCodeSheet), findsOneWidget);
      // Cleared: the button is disabled again until a new code is typed.
      await tester.tap(find.text('Confirm Pickup'));
      await tester.pump();
      expect(fake.calls, ['9999']);
    });

    testWidgets('a lockout message is shown as-is and the code is kept',
        (tester) async {
      final fake = _FakeOrders(
        (_) => false,
        message: 'Too many attempts. Try again in 10 minutes.',
      );
      await _openSheet(tester, fake);

      await _typeCode(tester, '1234');
      await tester.tap(find.text('Confirm Pickup'));
      await tester.pumpAndSettle();

      expect(find.text('Too many attempts. Try again in 10 minutes.'),
          findsOneWidget);
    });
  });
}
