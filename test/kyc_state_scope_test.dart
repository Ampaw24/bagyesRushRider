import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/kyc/models/upload_state.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SwitchableProfile extends RiderMeProfileNotifier {
  @override
  RiderMeProfileState build() => const RiderMeProfileState(
        status: RiderMeProfileStatus.loaded,
        profile: RiderMeProfileModel(id: 1),
      );

  void signInAs(int id) =>
      state = state.copyWith(profile: RiderMeProfileModel(id: id));
}

class _FailingUploads implements RiderMeProfileRepository {
  @override
  Future<Either<Failure, RiderMeDocumentModel>> uploadDocument({
    required String type,
    required String filePath,
  }) async =>
      const Left(ServerFailure('File too large'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => sl.registerSingleton<RiderMeProfileRepository>(_FailingUploads()));
  tearDown(sl.reset);

  test("one rider's uploads are cleared when another rider's profile loads",
      () async {
    final container = ProviderContainer(overrides: [
      riderMeProfileProvider.overrideWith(_SwitchableProfile.new),
    ]);
    addTearDown(container.dispose);

    // Keep the providers alive, as the screens watching them would.
    container.listen(kycUploadsProvider, (_, __) {});
    await container
        .read(kycUploadsProvider.notifier)
        .uploadDocument('drivers_licence_front', '/tmp/licence.jpg');
    expect(
      container.read(kycUploadsProvider)['drivers_licence_front']?.progress,
      UploadProgress.failed,
    );

    (container.read(riderMeProfileProvider.notifier) as _SwitchableProfile)
        .signInAs(2);

    expect(container.read(kycUploadsProvider), isEmpty);
  });
}
