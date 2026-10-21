import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gopady_rider/constant/typedef.dart';
import 'package:gopady_rider/core/di/service_locator.dart';
import 'package:gopady_rider/core/errors/failures.dart';
import 'package:gopady_rider/core/realtime/models/realtime_events.dart';
import 'package:gopady_rider/core/realtime/realtime_service.dart';
import 'package:gopady_rider/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:gopady_rider/features/rider/orders/models/rider_me_order_model.dart';
import 'package:gopady_rider/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:gopady_rider/features/rider/orders/repositories/rider_me_order_repository.dart';

/// No socket: hands the notifier streams the test can push into.
class _FakeRealtime extends Fake implements RealtimeService {
  final riderEvents = StreamController<Map<String, dynamic>>.broadcast();
  final statusEvents = StreamController<RealtimeOrderStatusEvent>.broadcast();

  @override
  Stream<RealtimeOrderStatusEvent> get orderStatus$ => statusEvents.stream;

  @override
  Stream<Map<String, dynamic>> get riderChannelEvents$ => riderEvents.stream;

  @override
  void subscribeToOrder(int orderId) {}

  @override
  void unsubscribeFromOrder(int orderId) {}
}

/// No network: [order] is what the server says right now.
class _FakeRepo extends Fake implements RiderMeOrderRepository {
  RiderMeOrderModel order;
  bool failLists = false;
  int listCalls = 0;
  int orderCalls = 0;

  _FakeRepo(this.order);

  @override
  ResultFuture<List<RiderMeOrderModel>> getOrders({
    String? filter,
    String? status,
    int? perPage,
  }) async {
    listCalls++;
    if (failLists) return const Left(NetworkFailure('offline'));
    return Right([order]);
  }

  @override
  ResultFuture<RiderMeOrderModel> getOrder(int orderId) async {
    orderCalls++;
    return Right(order);
  }

  /// As the backend does: the order stays out for delivery, can't be
  /// delivered.
  @override
  ResultFuture<void> markUnreachable(int orderId, {String? reason}) async {
    order = order.copyWith(canDeliver: false);
    return const Right(null);
  }

  @override
  ResultFuture<void> failStop(
    int orderId,
    int stopId, {
    required String reason,
  }) async {
    order = order.copyWith(stops: [
      for (final stop in order.stops)
        stop.id == stopId
            ? RiderMeOrderStopModel(
                id: stop.id,
                status: 'failed',
                failureReason: reason,
              )
            : stop,
    ]);
    return const Right(null);
  }
}

RiderMeOrderModel _dropOff({bool? canDeliver = true}) => RiderMeOrderModel(
      id: 7,
      status: 'out_for_delivery',
      arrivedAtDropoffAt: '2026-10-14T10:00:00Z',
      canDeliver: canDeliver,
    );

/// Runs [body] against a fresh container over the fakes. Disposed inside
/// the test rather than in a tear-down: flutter_test checks for pending
/// timers (the on-hold re-check) before tear-downs run.
Future<void> _run(
  _FakeRepo repo,
  Future<void> Function(ProviderContainer container) body, {
  _FakeRealtime? realtime,
}) async {
  sl.registerSingleton<RiderMeOrderRepository>(repo);
  sl.registerSingleton<RealtimeService>(realtime ?? _FakeRealtime());
  final container = ProviderContainer();
  try {
    await body(container);
  } finally {
    container.dispose();
    await sl.reset();
  }
}

/// Through the engine's own channel, so the binding steps through the
/// states in between (resumed → inactive → hidden …) as on a device.
Future<void> _setLifecycle(WidgetTester tester, AppLifecycleState state) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

bool _onHold(ProviderContainer container) {
  final state = container.read(riderMeOrdersProvider);
  return state.isOnHold(state.orders.single);
}

void main() {
  testWidgets('marking the customer unreachable leaves the order on hold',
      (tester) async {
    await _run(_FakeRepo(_dropOff()), (container) async {
      final notifier = container.read(riderMeOrdersProvider.notifier);
      await notifier.load(filter: 'active');

      expect(await notifier.markUnreachable(7), isTrue);

      final state = container.read(riderMeOrdersProvider);
      // Still in the active list, now waiting on support.
      expect(state.orders.single.id, 7);
      expect(_onHold(container), isTrue);
      expect(state.selectedOrder?.canDeliver, isFalse);
    });
  });

  testWidgets('a failed stop leaves the parcel open, not delivered',
      (tester) async {
    final repo = _FakeRepo(const RiderMeOrderModel(
      id: 8,
      status: 'out_for_delivery',
      stops: [
        RiderMeOrderStopModel(id: 1, status: 'delivered'),
        RiderMeOrderStopModel(id: 2, status: 'pending'),
      ],
    ));
    await _run(repo, (container) async {
      final notifier = container.read(riderMeOrdersProvider.notifier);
      await notifier.load(filter: 'active');

      expect(await notifier.failStop(8, 2, reason: 'No answer'), isTrue);

      final state = container.read(riderMeOrdersProvider);
      expect(
          state.stageFor(state.orders.single), RiderDeliveryStage.pickedUp);
      expect(_onHold(container), isTrue);
    });
  });

  testWidgets('re-checks an order on hold until support reopens it',
      (tester) async {
    final repo = _FakeRepo(_dropOff(canDeliver: false));
    await _run(repo, (container) async {
      await container
          .read(riderMeOrdersProvider.notifier)
          .load(filter: 'active');
      expect(repo.orderCalls, 0);

      await tester.pump(const Duration(seconds: 21));
      expect(repo.orderCalls, 1);
      expect(_onHold(container), isTrue);

      repo.order = _dropOff(canDeliver: true); // support reopens it
      await tester.pump(const Duration(seconds: 20));
      expect(repo.orderCalls, 2);
      expect(_onHold(container), isFalse);

      // Nothing is on hold any more, so the re-checks stop.
      await tester.pump(const Duration(minutes: 2));
      expect(repo.orderCalls, 2);
    });
  });

  testWidgets('stays quiet in the background and catches up when shown',
      (tester) async {
    final repo = _FakeRepo(_dropOff(canDeliver: false));
    await _run(repo, (container) async {
      await container
          .read(riderMeOrdersProvider.notifier)
          .load(filter: 'active');
      final listCallsBefore = repo.listCalls;

      await _setLifecycle(tester, AppLifecycleState.hidden);
      await tester.pump(const Duration(minutes: 2));
      expect(repo.orderCalls, 0);

      repo.order = _dropOff(canDeliver: true); // reopened while away
      await _setLifecycle(tester, AppLifecycleState.resumed);
      await tester.pump();

      expect(repo.listCalls, listCallsBefore + 1);
      expect(_onHold(container), isFalse);
    });
  });

  testWidgets('an event on the rider channel re-checks orders on hold',
      (tester) async {
    final repo = _FakeRepo(_dropOff(canDeliver: false));
    final realtime = _FakeRealtime();
    await _run(repo, realtime: realtime, (container) async {
      await container
          .read(riderMeOrdersProvider.notifier)
          .load(filter: 'active');

      repo.order = _dropOff(canDeliver: true);
      realtime.riderEvents.add({'event': 'order.updated'});
      await tester.pump();

      expect(repo.orderCalls, 1);
      expect(_onHold(container), isFalse);
    });
  });

  testWidgets('a list without can_deliver keeps the value already known',
      (tester) async {
    final repo = _FakeRepo(_dropOff(canDeliver: false));
    await _run(repo, (container) async {
      final notifier = container.read(riderMeOrdersProvider.notifier);
      await notifier.load(filter: 'active');

      repo.order = _dropOff(canDeliver: null);
      await notifier.load(filter: 'active', silent: true);

      expect(_onHold(container), isTrue);
    });
  });

  testWidgets('a failed background refresh raises no error', (tester) async {
    final repo = _FakeRepo(_dropOff());
    await _run(repo, (container) async {
      final notifier = container.read(riderMeOrdersProvider.notifier);
      await notifier.load(filter: 'active');

      repo.failLists = true;
      await notifier.load(filter: 'active', silent: true);

      final state = container.read(riderMeOrdersProvider);
      expect(state.errorMessage, isNull);
      expect(state.status, RiderMeOrdersStatus.loaded);
      expect(state.orders, hasLength(1));
    });
  });
}
