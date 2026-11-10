import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gopady_rider/core/di/service_locator.dart';
import 'package:gopady_rider/core/errors/failures.dart';
import 'package:gopady_rider/features/rider/kyc/models/kyc_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/screens/kyc_section_screen.dart';
import 'package:gopady_rider/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:gopady_rider/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:gopady_rider/features/rider/profile/repositories/rider_me_profile_repository.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_text_field.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:gopady_rider/features/rider/vehicles/repository/vehicle_catalog_repository.dart';

import 'fixtures/rider_me_incomplete.dart';

/// Signup no longer collects make/model, so a freshly registered rider —
/// exactly the fixture: `type_id` set, `make_id`/`model_id` null — first
/// picks them in the KYC vehicle section. A failed or empty catalogue fetch
/// there must not leave them stuck.

const _honda = VehicleMakeModel(
  id: 7,
  vehicleTypeId: 1,
  name: 'Honda',
  slug: 'honda',
  isActive: true,
  displayOrder: 0,
);

const _motorbike = VehicleTypeModel(
  id: 1,
  name: 'Motorbike',
  slug: 'motorbike',
  requiresPlate: true,
  maxParcelSize: 'small',
  maxParcelSizeLabel: 'Small',
  isActive: true,
  displayOrder: 0,
);

const _cb150 = VehicleModelModel(
  id: 70,
  vehicleMakeId: 7,
  name: 'CB150R',
  slug: 'cb150r',
  isActive: true,
  displayOrder: 0,
);

/// Answers each `getVehicleMakes` call with the next queued result.
class _QueuedCatalog implements VehicleCatalogRepository {
  _QueuedCatalog(this.makeResults, {this.models = const []});

  final List<Either<Failure, List<VehicleMakeModel>>> makeResults;
  final List<VehicleModelModel> models;
  int makeCalls = 0;

  @override
  Future<Either<Failure, List<VehicleMakeModel>>> getVehicleMakes(
    int vehicleTypeId,
  ) async =>
      makeResults[makeCalls++];

  @override
  Future<Either<Failure, List<VehicleModelModel>>> getVehicleModels(
    int vehicleMakeId,
  ) async =>
      Right(models);

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getVehicleTypes() async =>
      const Right([_motorbike]);
}

/// Records what the vehicle step sends to `PUT /rider/me`.
class _RecordingProfileRepo implements RiderMeProfileRepository {
  Map<String, dynamic>? saved;
  RiderMeProfileModel? current;

  @override
  Future<Either<Failure, RiderMeProfileModel>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    saved = data;
    return Right(current!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoadedProfile extends RiderMeProfileNotifier {
  _LoadedProfile(this.profile);
  final RiderMeProfileModel profile;

  @override
  RiderMeProfileState build() => RiderMeProfileState(
        status: RiderMeProfileStatus.loaded,
        profile: profile,
      );

  @override
  Future<void> load() async {}
}

Future<_QueuedCatalog> _pumpVehicleSection(
  WidgetTester tester,
  List<Either<Failure, List<VehicleMakeModel>>> makeResults, {
  List<VehicleModelModel> models = const [],
  void Function(Map<String, dynamic> vehicle)? editVehicle,
  _RecordingProfileRepo? profileRepo,
}) async {
  tester.view.physicalSize = const Size(360, 780) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final catalog = _QueuedCatalog(makeResults, models: models);
  sl.registerSingleton<VehicleCatalogRepository>(catalog);
  addTearDown(sl.reset);

  final data = (jsonDecode(riderMeIncompleteJson)
      as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  editVehicle?.call(data['vehicle'] as Map<String, dynamic>);
  final profile = RiderMeProfileModel.fromJson(data);
  if (profileRepo != null) {
    profileRepo.current = profile;
    sl.registerSingleton<RiderMeProfileRepository>(profileRepo);
  }

  await tester.pumpWidget(ProviderScope(
    overrides: [
      riderMeProfileProvider.overrideWith(() => _LoadedProfile(profile)),
    ],
    child: const MaterialApp(
      home: KycSectionScreen(section: KycSection.vehicle),
    ),
  ));
  await tester.pumpAndSettle();
  return catalog;
}

void main() {
  testWidgets('a failed makes fetch can be retried', (tester) async {
    final catalog = await _pumpVehicleSection(tester, const [
      Left(NetworkFailure('No internet connection')),
      Right([_honda]),
    ]);

    expect(find.text('No internet connection'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(catalog.makeCalls, 2);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Select make'), findsOneWidget);
  });

  testWidgets('a rider with no vehicle yet sets type and plate here',
      (tester) async {
    final repo = _RecordingProfileRepo();
    await _pumpVehicleSection(
      tester,
      const [Right([_honda])],
      models: const [_cb150],
      profileRepo: repo,
      // What `/rider/me` looks like now that signup sends no vehicle.
      editVehicle: (v) => v
        ..['type_id'] = null
        ..['type'] = null
        ..['type_label'] = null
        ..['plate_number'] = null,
    );

    // The only type on offer is picked for the rider.
    expect(find.text('Motorbike'), findsOneWidget);
    expect(find.textContaining('Contact support'), findsNothing);

    await tester.enterText(
      find.descendant(
        of: find.widgetWithText(AppTextField, 'License plate number'),
        matching: find.byType(EditableText),
      ),
      'gr-1234-24',
    );
    for (final pick in ['Select make', 'Honda', 'Select model', 'CB150R']) {
      await tester.ensureVisible(find.text(pick).first);
      await tester.tap(find.text(pick).first);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Save & continue'));
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    expect(repo.saved, containsPair('vehicle_type_id', 1));
    expect(repo.saved, containsPair('plate_number', 'GR-1234-24'));
    expect(repo.saved, containsPair('vehicle_make_id', 7));
    expect(repo.saved, containsPair('vehicle_model_id', 70));
  });

  testWidgets('type and plate already on file stay read-only',
      (tester) async {
    await _pumpVehicleSection(tester, const [Right([_honda])]);

    expect(find.text('GR42'), findsOneWidget);
    expect(find.text('License plate number'), findsNothing);
    expect(find.text('Vehicle type'), findsNothing);
  });

  testWidgets('an empty catalogue says so instead of "Loading…" forever',
      (tester) async {
    await _pumpVehicleSection(tester, const [Right([])]);

    expect(find.text('No makes listed for this vehicle type'), findsOneWidget);
    expect(find.text('Loading makes…'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
}
