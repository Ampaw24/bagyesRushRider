import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/screens/kyc_hub_screen.dart';
import 'package:delivery_boy/features/rider/kyc/views/screens/kyc_section_screen.dart';
import 'package:delivery_boy/features/rider/profile/models/payout_provider_model.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fixtures/rider_me_incomplete.dart';

Map<String, dynamic> _json([void Function(Map<String, dynamic>)? edit]) {
  final data = (jsonDecode(riderMeIncompleteJson) as Map<String, dynamic>)['data']
      as Map<String, dynamic>;
  edit?.call(data);
  return data;
}

/// Serves `/rider/me` from [current]; a save swaps in [afterSave], standing
/// in for the server's updated view.
class _FakeServer {
  _FakeServer(this.current);

  RiderMeProfileModel current;
  RiderMeProfileModel? afterSave;
  Failure? saveFailure;
  Map<String, dynamic>? lastSaved;
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
  Future<void> load() async =>
      state = state.copyWith(profile: server.current);
}

class _FakeRepo implements RiderMeProfileRepository {
  _FakeRepo(this.server);
  final _FakeServer server;

  @override
  Future<Either<Failure, RiderMeProfileModel>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    server.lastSaved = data;
    if (server.saveFailure != null) return Left(server.saveFailure!);
    server.current = server.afterSave ?? server.current;
    return Right(server.current);
  }

  @override
  Future<Either<Failure, List<PayoutProviderModel>>> getPayoutProviders() async =>
      const Right([
        PayoutProviderModel(id: 1, type: 'mobile_money', name: 'MTN MOMO'),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpFlow(
  WidgetTester tester,
  _FakeServer server, {
  required String initialLocation,
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
        path: AppRoutes.kyc,
        builder: (_, __) => const KycHubScreen(),
        routes: [
          GoRoute(
            path: ':section',
            builder: (_, state) => KycSectionScreen(
              section: KycSection.fromSlug(state.pathParameters['section'])!,
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        riderMeProfileProvider.overrideWith(() => _ServerBackedProfile(server)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// The fixture with a complete emergency contact filled in locally, so the
/// form can be submitted without driving the pickers.
RiderMeProfileModel _withContactPrefilled({bool missing = true}) =>
    RiderMeProfileModel.fromJson(_json((json) {
      json['emergency_contact'] = {
        'name': 'Ama Hu',
        'phone': '233241234567',
        'relationship': 'sibling',
      };
      if (!missing) {
        (json['missing_profile_fields'] as List)
            .removeWhere((f) => '$f'.startsWith('emergency_contact'));
      }
    }));

void main() {
  testWidgets('checklist shows the server’s progress and the next step',
      (tester) async {
    final server = _FakeServer(RiderMeProfileModel.fromJson(_json()));
    await _pumpFlow(tester, server, initialLocation: AppRoutes.kyc);

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('1 of 8 steps complete'), findsOneWidget);
    expect(find.text('Profile photo'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('2 details needed'), findsWidgets);
    expect(find.text('Continue: Personal details'), findsOneWidget);
  });

  testWidgets('a 422 lands on the field that caused it', (tester) async {
    final server = _FakeServer(_withContactPrefilled())
      ..saveFailure = const ValidationFailure(
        'The emergency contact phone format is invalid.',
        {
          'emergency_contact_phone': [
            'The emergency contact phone format is invalid.',
          ],
        },
      );
    await _pumpFlow(
      tester,
      server,
      initialLocation: AppRoutes.kycSection(KycSection.emergencyContact.slug),
    );

    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    expect(server.lastSaved, {
      'emergency_contact_name': 'Ama Hu',
      'emergency_contact_phone': '+233241234567',
      'emergency_contact_relationship': 'sibling',
    });
    expect(
      find.text('The emergency contact phone format is invalid.'),
      findsOneWidget,
      reason: 'shown once, under the field — no dialog on top',
    );
    expect(find.text("Couldn't Save"), findsNothing);
  });

  testWidgets('a successful save moves on to the next step needing action',
      (tester) async {
    final server = _FakeServer(_withContactPrefilled())
      ..afterSave = _withContactPrefilled(missing: false);
    await _pumpFlow(
      tester,
      server,
      initialLocation: AppRoutes.kycSection(KycSection.emergencyContact.slug),
    );

    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    // Emergency contact comes after insurance, so the next outstanding
    // step is payout.
    expect(find.text('Payout account'), findsOneWidget);
    expect(find.text('Mobile money'), findsOneWidget);
  });

  testWidgets('a save the server still finds incomplete stays put',
      (tester) async {
    final server = _FakeServer(_withContactPrefilled());
    await _pumpFlow(
      tester,
      server,
      initialLocation: AppRoutes.kycSection(KycSection.emergencyContact.slug),
    );

    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    expect(find.text('Almost There'), findsOneWidget);
    expect(find.textContaining('Contact phone'), findsOneWidget);
  });

  group('fits a small phone with large text', () {
    for (final location in [
      AppRoutes.kyc,
      for (final section in KycSection.values)
        AppRoutes.kycSection(section.slug),
    ]) {
      testWidgets(location, (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final server = _FakeServer(RiderMeProfileModel.fromJson(_json()));
        await _pumpFlow(
          tester,
          server,
          initialLocation: location,
          screen: const Size(320, 568),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
