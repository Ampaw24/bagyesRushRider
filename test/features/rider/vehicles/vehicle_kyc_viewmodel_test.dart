import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vehicle_test_support.dart';

const _front = VehicleCaptureType.front;
const _rear = VehicleCaptureType.rear;

void main() {
  late Directory dir;
  late FakeProfileServer server;
  late FakeVehicleRepo repo;
  late ProviderContainer container;

  VehicleKycNotifier notifier() => container.read(vehicleKycProvider.notifier);
  VehicleVerificationView view() => container.read(vehicleVerificationProvider)!;
  ServerBackedProfile profiles() =>
      container.read(riderMeProfileProvider.notifier) as ServerBackedProfile;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('vehicle_kyc_');
    server = FakeProfileServer(riderProfile());
    repo = FakeVehicleRepo(server);
    sl.registerSingleton<VehicleVerificationRepository>(repo);
    container = ProviderContainer(overrides: [
      riderMeProfileProvider.overrideWith(() => ServerBackedProfile(server)),
    ]);
    // Keep the providers alive, as the open screen would.
    container.listen(vehicleVerificationProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
    sl.reset();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> captureBoth() async {
    notifier().recordCapture(_front, await tempJpeg(dir, 'front'));
    notifier().recordCapture(_rear, await tempJpeg(dir, 'rear'));
  }

  test('starts with every photo missing', () {
    expect(view().status, VehicleVerificationStatus.photosRequired);
    expect(view().missingSteps.map((s) => s.type), [_front, _rear]);
  });

  test('a capture is kept as a draft; a retake replaces and deletes it',
      () async {
    final first = await tempJpeg(dir, 'first');
    final second = await tempJpeg(dir, 'second');

    notifier().recordCapture(_front, first);
    expect(view().steps.first.state, VehicleCaptureStepState.captured);

    notifier().recordCapture(_front, second);
    await Future<void>.delayed(Duration.zero);
    expect(view().steps.first.draft!.localPath, second);
    expect(File(first).existsSync(), isFalse);
  });

  test('uploads in capture order, adopts the server profile, and cleans up',
      () async {
    await captureBoth();
    final paths = [for (final s in view().steps) s.draft!.localPath];

    final failure = await notifier().uploadPending();

    expect(failure, isNull);
    expect(repo.uploads, [_front, _rear]);
    expect(view().steps.map((s) => s.state),
        everyElement(VehicleCaptureStepState.uploaded));
    // Uploaded is not verified: the account still needs approving.
    expect(view().status, VehicleVerificationStatus.pendingReview);
    expect(server.loads, 0, reason: 'used the returned profile');
    await Future<void>.delayed(Duration.zero);
    for (final path in paths) {
      expect(File(path).existsSync(), isFalse, reason: 'temp file deleted');
    }
  });

  test('one failed upload keeps its photo and does not stop the others',
      () async {
    await captureBoth();
    repo.uploadResults[_front] =
        const Left(ServerFailure("Couldn't reach the server."));

    final failure = await notifier().uploadPending();

    expect(failure?.message, "Couldn't reach the server.");
    expect(repo.uploads, [_front, _rear]);
    final front = view().steps.first;
    expect(front.state, VehicleCaptureStepState.failed);
    expect(front.draft!.errorMessage, "Couldn't reach the server.");
    expect(File(front.draft!.localPath).existsSync(), isTrue);
    expect(view().steps.last.state, VehicleCaptureStepState.uploaded);

    // Retry just that photo.
    repo.uploadResults.remove(_front);
    expect(await notifier().uploadPending(only: {_front}), isNull);
    expect(repo.uploads, [_front, _rear, _front]);
    expect(view().steps.first.state, VehicleCaptureStepState.uploaded);
  });

  test('a session expiry stops the remaining uploads', () async {
    await captureBoth();
    repo.uploadResults[_front] =
        const Left(SessionExpiredFailure('Your session has expired.'));

    final failure = await notifier().uploadPending();

    expect(failure, isA<SessionExpiredFailure>());
    expect(repo.uploads, [_front]);
    expect(view().steps.last.state, VehicleCaptureStepState.captured);
  });

  test('pressing upload again while uploading sends nothing twice', () async {
    await captureBoth();
    repo.gate = Completer<void>();

    final first = notifier().uploadPending();
    await repo.firstUpload.future;
    expect(view().isUploading, isTrue);
    expect(view().steps.first.draft!.uploadFraction, 0.5);
    expect(await notifier().uploadPending(), isNull);

    repo.gate!.complete();
    await first;
    expect(repo.uploads, [_front, _rear]);
    expect(view().isUploading, isFalse);
  });

  test('a photo that is not an image fails before any request', () async {
    final path = '${dir.path}/note.jpg';
    await File(path).writeAsString('not a photo');
    notifier().recordCapture(_front, path);

    final failure = await notifier().uploadPending();

    expect(failure, isA<ValidationFailure>());
    expect(repo.uploads, isEmpty);
    expect(view().steps.first.state, VehicleCaptureStepState.failed);
  });

  test('reloads /rider/me when the response is not a profile', () async {
    notifier().recordCapture(_front, await tempJpeg(dir, 'front'));
    repo.uploadResults[_front] = const Right(null);

    expect(await notifier().uploadPending(), isNull);
    expect(server.loads, 1);
    expect(view().steps.first.draft, isNull);
  });

  test("a new rider's sign-in drops the last rider's photos mid-upload",
      () async {
    await captureBoth();
    repo.gate = Completer<void>();

    final upload = notifier().uploadPending();
    await repo.firstUpload.future;
    profiles().signInAs(riderProfile(id: 2));
    expect(view().steps.every((s) => s.draft == null), isTrue);

    repo.gate!.complete();
    await upload;
    expect(repo.uploads, [_front], reason: 'the rear photo was never sent');
    expect(container.read(riderMeProfileProvider).profile!.id, 2);
    expect(view().steps.every((s) => s.draft == null), isTrue);
  });

  test('a rejected rider can retake and resubmit photos', () async {
    final rejected = riderProfile(
      photos: {'front': frontUrl, 'back': backUrl},
      status: 'rejected',
      rejectionReason: 'Registration plate was not clearly visible.',
    );
    server.current = rejected;
    profiles().signInAs(rejected);
    expect(view().status, VehicleVerificationStatus.actionRequired);

    notifier().recordCapture(_rear, await tempJpeg(dir, 'rear'));
    expect(await notifier().uploadPending(), isNull);
    expect(repo.uploads, [_rear]);
    expect(view().steps.last.remoteUrl, isNot(backUrl));
  });

  test('changing vehicle removes the old photos and any drafts', () async {
    final withPhotos = riderProfile(photos: {'front': frontUrl, 'back': backUrl});
    server.current = withPhotos;
    profiles().signInAs(withPhotos);
    final draft = await tempJpeg(dir, 'draft');
    notifier().recordCapture(_front, draft);

    final failure = await notifier().clearPhotosForVehicleChange();

    expect(failure, isNull);
    expect(repo.deletes, [_front, _rear]);
    expect(view().status, VehicleVerificationStatus.photosRequired);
    expect(view().steps.every((s) => s.draft == null), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(File(draft).existsSync(), isFalse);
  });
}
