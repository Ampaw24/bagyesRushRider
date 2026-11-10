import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gopady_rider/core/di/service_locator.dart';
import 'package:gopady_rider/core/errors/failures.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/features/rider/profile/models/payout_provider_model.dart';
import 'package:gopady_rider/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:gopady_rider/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:gopady_rider/features/rider/profile/repositories/rider_me_profile_repository.dart';
import 'package:gopady_rider/features/rider/wallet/views/screens/rider_payout_edit_screen.dart';
import 'package:gopady_rider/features/rider/wallet/views/screens/rider_payout_screen.dart';

import 'fixtures/rider_me_incomplete.dart';

const _momo = {
  'bank': null,
  'payout_provider_id': null,
  'account_name': 'Ampaw Hu',
  'account_number_last4': null,
  'momo_provider': {'id': 1, 'name': 'MTN MoMo'},
  'momo_provider_id': 1,
  'mobile_money_number_last4': '4567',
  'is_configured': true,
};

const _bank = {
  'bank': {'id': 7, 'name': 'GCB Bank'},
  'payout_provider_id': 7,
  'account_name': 'Ampaw Hu',
  'account_number_last4': '9012',
  'momo_provider': null,
  'momo_provider_id': null,
  'mobile_money_number_last4': null,
  'is_configured': true,
};

RiderMeProfileModel _profile([Map<String, dynamic>? payout]) {
  final data = (jsonDecode(riderMeIncompleteJson)
      as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  if (payout != null) data['payout'] = payout;
  return RiderMeProfileModel.fromJson(data);
}

/// Serves `/rider/me` from [current]; a payout save swaps in [afterSave].
class _FakeServer {
  _FakeServer(this.current);

  RiderMeProfileModel current;
  RiderMeProfileModel? afterSave;
  Map<String, Object?>? lastPayout;
}

class _ServerBackedProfile extends RiderMeProfileNotifier {
  _ServerBackedProfile(this.server);
  final _FakeServer server;

  @override
  RiderMeProfileState build() => RiderMeProfileState(
        status: RiderMeProfileStatus.loaded,
        profile: server.current,
      );

  @override
  Future<void> load() async => state = state.copyWith(profile: server.current);
}

class _FakeRepo implements RiderMeProfileRepository {
  _FakeRepo(this.server);
  final _FakeServer server;

  @override
  Future<Either<Failure, RiderMeProfileModel>> updatePayout({
    required String currentPassword,
    int? payoutProviderId,
    String? accountNumber,
    String? accountName,
    int? momoProviderId,
    String? mobileMoneyNumber,
  }) async {
    server.lastPayout = {
      'current_password': currentPassword,
      'momo_provider_id': momoProviderId,
      'mobile_money_number': mobileMoneyNumber,
      'account_name': accountName,
    };
    server.current = server.afterSave ?? server.current;
    return Right(server.current);
  }

  @override
  Future<Either<Failure, List<PayoutProviderModel>>>
      getPayoutProviders() async => const Right([
            PayoutProviderModel(id: 1, type: 'mobile_money', name: 'MTN MoMo'),
            PayoutProviderModel(
                id: 2, type: 'mobile_money', name: 'Telecel Cash'),
            PayoutProviderModel(id: 7, type: 'bank', name: 'GCB Bank'),
          ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _FakeServer server, {
  String initialLocation = AppRoutes.payout,
  Size screen = const Size(360, 780),
}) async {
  tester.view.physicalSize = screen * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  sl.registerSingleton<RiderMeProfileRepository>(_FakeRepo(server));
  addTearDown(sl.reset);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.payout,
        builder: (_, __) => const RiderPayoutScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, __) => const RiderPayoutEditScreen(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      riderMeProfileProvider.overrideWith(() => _ServerBackedProfile(server)),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('RiderPayoutInfo labels', () {
    test('mobile money', () {
      final payout = _profile(_momo).payout;
      expect(payout.providerLabel, 'MTN MoMo');
      expect(payout.destinationLabel, 'MTN MoMo •••• 4567');
    });

    test('bank', () {
      final payout = _profile(_bank).payout;
      expect(payout.providerLabel, 'GCB Bank');
      expect(payout.destinationLabel, 'GCB Bank •••• 9012');
    });

    test('falls back to the method when the provider is unnamed', () {
      const payout = RiderPayoutInfo(momoProviderId: 3, isConfigured: true);
      expect(payout.destinationLabel, 'Mobile money');
    });
  });

  group('payout details', () {
    testWidgets('shows a mobile money account, masked', (tester) async {
      await _pump(tester, _FakeServer(_profile(_momo)));

      expect(find.text('Withdrawals are paid to'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Mobile money'), findsOneWidget);
      expect(find.text('Mobile money number'), findsOneWidget);
      expect(find.text('•••• 4567'), findsOneWidget);
      expect(find.text('Ampaw Hu'), findsOneWidget);
      expect(find.text('Change payout account'), findsOneWidget);
    });

    testWidgets('shows a bank account, masked', (tester) async {
      await _pump(tester, _FakeServer(_profile(_bank)));

      expect(find.text('GCB Bank'), findsOneWidget);
      expect(find.text('Bank account'), findsOneWidget);
      expect(find.text('Account number'), findsOneWidget);
      expect(find.text('•••• 9012'), findsOneWidget);
    });

    testWidgets('invites a rider with no account to add one', (tester) async {
      await _pump(tester, _FakeServer(_profile()));

      expect(find.text('No payout account yet'), findsOneWidget);
      expect(find.text('Add payout account'), findsOneWidget);
    });
  });

  testWidgets('changing the account saves and returns to the details',
      (tester) async {
    final server = _FakeServer(_profile(_momo))
      ..afterSave = _profile({
        ..._momo,
        'momo_provider': {'id': 2, 'name': 'Telecel Cash'},
        'momo_provider_id': 2,
        'mobile_money_number_last4': '1234',
      });
    await _pump(tester, server);

    await tester.tap(find.text('Change payout account'));
    await tester.pumpAndSettle();
    expect(find.text('Update payout account'), findsOneWidget);
    expect(find.text('MTN MoMo •••• 4567'), findsOneWidget,
        reason: 'the form shows the account it replaces');

    await tester.tap(find.text('MTN MoMo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Telecel Cash'));
    await tester.pumpAndSettle();

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), '201231234');
    await tester.enterText(fields.at(2), 'secret-pass');
    await tester.ensureVisible(find.text('Update payout account'));
    await tester.tap(find.text('Update payout account'));
    await tester.pumpAndSettle();

    expect(server.lastPayout, {
      'current_password': 'secret-pass',
      'momo_provider_id': 2,
      'mobile_money_number': '+233201231234',
      'account_name': 'Ampaw Hu',
    });
    expect(find.text('Payout account saved'), findsOneWidget);
    expect(find.byType(RiderPayoutScreen), findsOneWidget);
    expect(find.text('Telecel Cash'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  group('fits a small phone with large text', () {
    for (final (name, payout, location) in [
      ('details', _momo, AppRoutes.payout),
      ('empty details', null, AppRoutes.payout),
      ('edit', _bank, AppRoutes.payoutEdit),
    ]) {
      testWidgets(name, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pump(
          tester,
          _FakeServer(_profile(payout)),
          initialLocation: location,
          screen: const Size(320, 568),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
