import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/vehicles/capture/camera_access.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/vehicles/views/screens/vehicle_verification_screen.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_camera_overlays.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vehicle_test_support.dart';

const _both = {'front': frontUrl, 'back': backUrl};

void main() {
  late FakeProfileServer server;
  late FakeVehicleRepo repo;
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('vehicle_screen_');
  });
  tearDown(() {
    sl.reset();
    dir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    RiderMeProfileModel profile, {
    Widget child = const VehicleVerificationScreen(),
    Size screen = const Size(360, 780),
  }) async {
    tester.view.physicalSize = screen * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    server = FakeProfileServer(profile);
    repo = FakeVehicleRepo(server);
    sl.registerSingleton<VehicleVerificationRepository>(repo);

    final container = ProviderContainer(overrides: [
      riderMeProfileProvider.overrideWith(() => ServerBackedProfile(server)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<void> captureBoth(ProviderContainer container) async {
    final notifier = container.read(vehicleKycProvider.notifier);
    notifier.recordCapture(
        VehicleCaptureType.front, await tempJpeg(dir, 'front'));
    notifier.recordCapture(VehicleCaptureType.rear, await tempJpeg(dir, 'rear'));
  }

  testWidgets('a motorbike with no photos is asked for front and rear',
      (tester) async {
    await pump(tester, riderProfile());

    expect(find.text('Verification required'), findsOneWidget);
    expect(find.text('Front view'), findsOneWidget);
    expect(find.text('Rear view'), findsOneWidget);
    expect(find.textContaining('Stand behind your motorbike'), findsOneWidget);
    // Not offered until the API can store them.
    expect(find.text('Left side'), findsNothing);
    expect(find.textContaining("gallery can't be used"), findsOneWidget);
    expect(find.text('Take photos'), findsOneWidget);
    expect(find.text('0 of 2 uploaded'), findsOneWidget);
  });

  testWidgets('a car gets the same flow in car terms', (tester) async {
    await pump(
      tester,
      riderProfile(vehicleType: 'car', vehicleTypeLabel: 'Car'),
    );
    expect(find.textContaining('Stand in front of your car'), findsOneWidget);
    expect(find.textContaining('motorbike'), findsNothing);
  });

  testWidgets('taken photos are uploaded on request, then pending review',
      (tester) async {
    final container = await pump(tester, riderProfile());
    await tester.runAsync(() => captureBoth(container));
    await tester.pump();
    expect(find.text('Upload 2 photos'), findsOneWidget);
    expect(find.text('Ready to upload'), findsNWidgets(2));

    await tester.tap(find.text('Upload 2 photos'));
    // The upload reads the photo files for real: let that I/O finish, then
    // pump so its continuations run. Bounded, so a regression fails rather
    // than hangs.
    for (var i = 0; i < 100 && repo.uploads.length < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pump();

    expect(repo.uploads,
        [VehicleCaptureType.front, VehicleCaptureType.rear]);
    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('a failed upload offers retry and retake, keeping the photo',
      (tester) async {
    final container = await pump(tester, riderProfile());
    await tester.runAsync(() => captureBoth(container));
    repo.uploadResults[VehicleCaptureType.front] =
        const Left(ServerFailure("Couldn't reach the server."));

    await tester.runAsync(() =>
        container.read(vehicleKycProvider.notifier).uploadPending());
    await tester.pump();

    expect(find.text('Retry upload'), findsOneWidget);
    expect(find.text('Retake'), findsNWidgets(2));
    expect(find.textContaining('still saved on this phone'), findsOneWidget);
    expect(find.text('Upload 1 photo'), findsOneWidget);
  });

  testWidgets('a verified vehicle says so and has nothing left to do',
      (tester) async {
    await pump(tester, riderProfile(photos: _both, canGoOnline: true));
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('2 of 2 uploaded'), findsOneWidget);
  });

  testWidgets('a rejection shows the reason and asks for new photos',
      (tester) async {
    await pump(
      tester,
      riderProfile(
        photos: _both,
        status: 'rejected',
        rejectionReason: 'Registration plate was not clearly visible.',
      ),
    );
    expect(find.text('Action required'), findsOneWidget);
    expect(find.text('Registration plate was not clearly visible.'),
        findsOneWidget);
    expect(find.text('Retake photos'), findsOneWidget);
  });

  group('profile card', () {
    testWidgets('shows the vehicle, plate, ownership and status',
        (tester) async {
      await pump(
        tester,
        riderProfile(make: 'Honda', model: 'CB125'),
        child: const SingleChildScrollView(child: VehicleProfileCard()),
      );
      expect(find.text('Honda CB125'), findsOneWidget);
      expect(find.text('Plate GR42'), findsOneWidget);
      expect(find.text('Owned by the rider'), findsOneWidget);
      expect(find.text('Verification required'), findsOneWidget);
      expect(find.text('Verify vehicle'), findsOneWidget);
    });

    testWidgets('pending review once both photos are on the server',
        (tester) async {
      await pump(
        tester,
        riderProfile(photos: _both),
        child: const SingleChildScrollView(child: VehicleProfileCard()),
      );
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('View photos'), findsOneWidget);
    });

    testWidgets('a rejection asks the rider to resubmit', (tester) async {
      await pump(
        tester,
        riderProfile(
          photos: _both,
          status: 'rejected',
          rejectionReason: 'Photos too dark.',
        ),
        child: const SingleChildScrollView(child: VehicleProfileCard()),
      );
      expect(find.text('Photos too dark.'), findsOneWidget);
      expect(find.text('Resubmit'), findsOneWidget);
    });
  });

  group('camera permission', () {
    Future<void> pumpView(WidgetTester tester, CameraAccess access,
        {VoidCallback? onAllow}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: CameraPermissionView(
            access: access,
            onAllow: onAllow ?? () {},
            onClose: () {},
          ),
        ),
      ));
    }

    testWidgets('denied: explains why and lets the rider allow it',
        (tester) async {
      var asked = 0;
      await pumpView(tester, CameraAccess.denied, onAllow: () => asked++);
      expect(find.text('Camera access required'), findsOneWidget);
      await tester.tap(find.text('Allow camera'));
      expect(asked, 1);
    });

    testWidgets('permanently denied: points to Settings', (tester) async {
      await pumpView(tester, CameraAccess.permanentlyDenied);
      expect(find.text('Camera permission is turned off'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('restricted: nothing the rider can grant', (tester) async {
      await pumpView(tester, CameraAccess.restricted);
      expect(find.text('Camera unavailable'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Not now'), findsOneWidget);
    });
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = await pump(
      tester,
      riderProfile(
        photos: _both,
        status: 'rejected',
        rejectionReason: 'Registration plate was not clearly visible.',
      ),
      screen: const Size(320, 568),
    );
    await tester.runAsync(() => captureBoth(container));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: VehicleProfileCard()),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
