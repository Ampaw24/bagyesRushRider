import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/rider_vehicle.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification_configuration.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vehicle_test_support.dart';

VehicleVerificationView _view(
  RiderMeProfileModel profile, {
  Map<VehicleCaptureType, VehicleCaptureDraft> drafts = const {},
}) =>
    VehicleVerificationView.from(
      profile: profile,
      drafts: drafts,
      supportedTypes: VehicleVerificationRepository.supportedCaptureTypes,
    );

void main() {
  group('/rider/me vehicle.photos', () {
    test('keeps sides with a photo and drops null or blank ones', () {
      final profile = riderProfile(
        photos: {'front': frontUrl, 'back': null, 'left_side': '  '},
      );
      expect(profile.vehiclePhotos, {'front': frontUrl});
    });

    test('a response without photos reads as none', () {
      final profile = RiderMeProfileModel.fromJson(riderMeData());
      expect(profile.vehiclePhotos, isEmpty);
      expect(profile.vehicleOwnershipLabel, 'Owned by the rider');
    });

    test('the API\'s "back" photo is the rear capture', () {
      final vehicle = RiderVehicle.fromProfile(
        riderProfile(photos: {'front': frontUrl, 'back': backUrl}),
      );
      expect(vehicle.photos, {
        VehicleCaptureType.front: frontUrl,
        VehicleCaptureType.rear: backUrl,
      });
    });
  });

  group('RiderVehicle', () {
    test('names the vehicle by make and model when known', () {
      final vehicle = RiderVehicle.fromProfile(
        riderProfile(make: 'Honda', model: 'CB125'),
      );
      expect(vehicle.displayName, 'Honda CB125');
      expect(vehicle.kind, VehicleKind.motorcycle);
      expect(vehicle.plateNumber, 'GR42');
    });

    test('falls back to the server type label', () {
      final vehicle = RiderVehicle.fromProfile(riderProfile());
      expect(vehicle.displayName, 'Motorbike');
      expect(vehicle.details, 'Motorbike · 2025');
    });
  });

  group('steps', () {
    test('a motorbike is asked only for the views the API stores', () {
      final view = _view(riderProfile());
      expect(view.steps.map((s) => s.type),
          [VehicleCaptureType.front, VehicleCaptureType.rear]);
      expect(view.steps.first.requirement.instruction, contains('motorbike'));
    });

    test('a car gets car instructions from the same flow', () {
      final view = _view(
        riderProfile(vehicleType: 'car', vehicleTypeLabel: 'Car'),
      );
      expect(view.vehicle.kind, VehicleKind.car);
      expect(view.steps.first.requirement.instruction, contains('your car'));
    });

    test('a local photo outranks the server one until it is uploaded', () {
      final profile = riderProfile(photos: {'front': frontUrl});
      VehicleCaptureStepState stateWith(VehicleCaptureProgress? progress) =>
          _view(profile, drafts: {
            if (progress != null)
              VehicleCaptureType.front: VehicleCaptureDraft(
                localPath: '/tmp/front.jpg',
                progress: progress,
              ),
          }).steps.first.state;

      expect(stateWith(null), VehicleCaptureStepState.uploaded);
      expect(stateWith(VehicleCaptureProgress.captured),
          VehicleCaptureStepState.captured);
      expect(stateWith(VehicleCaptureProgress.uploading),
          VehicleCaptureStepState.uploading);
      expect(stateWith(VehicleCaptureProgress.failed),
          VehicleCaptureStepState.failed);
    });

    test('missing and pending steps are told apart', () {
      final view = _view(riderProfile(), drafts: {
        VehicleCaptureType.rear: const VehicleCaptureDraft(
          localPath: '/tmp/rear.jpg',
          progress: VehicleCaptureProgress.failed,
        ),
      });
      expect(view.missingSteps.map((s) => s.type), [VehicleCaptureType.front]);
      expect(view.pendingUploads.map((s) => s.type), [VehicleCaptureType.rear]);
      expect(view.stepNumberOf(VehicleCaptureType.rear), 2);
    });
  });

  group('status', () {
    const both = {'front': frontUrl, 'back': backUrl};

    test('photos are required until every required one is on the server', () {
      expect(_view(riderProfile()).status,
          VehicleVerificationStatus.photosRequired);
      expect(_view(riderProfile(photos: {'front': frontUrl})).status,
          VehicleVerificationStatus.photosRequired);
    });

    test('uploaded photos are pending review, not verified', () {
      expect(_view(riderProfile(photos: both)).status,
          VehicleVerificationStatus.pendingReview);
    });

    test('verified only once the server approves the account', () {
      expect(_view(riderProfile(photos: both, canGoOnline: true)).status,
          VehicleVerificationStatus.verified);
      expect(_view(riderProfile(photos: both, status: 'approved')).status,
          VehicleVerificationStatus.verified);
    });

    test('an approved rider without photos still needs to take them', () {
      expect(_view(riderProfile(canGoOnline: true)).status,
          VehicleVerificationStatus.photosRequired);
    });

    test('a rejection needs action and carries the reason', () {
      final view = _view(riderProfile(
        photos: both,
        status: 'rejected',
        rejectionReason: 'Registration plate was not clearly visible.',
      ));
      expect(view.status, VehicleVerificationStatus.actionRequired);
      expect(view.rejectionReason, 'Registration plate was not clearly visible.');
    });
  });
}
