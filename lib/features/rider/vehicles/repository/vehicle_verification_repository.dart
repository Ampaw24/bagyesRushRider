import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';

/// Vehicle verification evidence on the backend.
///
/// Today that is `POST`/`DELETE /rider/me/vehicle-photos/:side`, which
/// stores a front and a back photo. The API has no verification session,
/// no per-vehicle review status and no other capture types yet; when it
/// does, they belong behind this interface so the screens don't change.
abstract class VehicleVerificationRepository {
  /// The captures the API can store. Every other [VehicleCaptureType] is
  /// configured but not shown to riders until it's added here.
  static const supportedCaptureTypes = {
    VehicleCaptureType.front,
    VehicleCaptureType.rear,
  };

  /// Uploads (or replaces) the photo for [type].
  ///
  /// Succeeds with the profile the server returned, or null when the body
  /// wasn't a recognisable profile — the photo is stored either way, so the
  /// caller should then reload `/rider/me`.
  ResultFuture<RiderMeProfileModel?> uploadPhoto(
    VehicleCaptureType type,
    String filePath, {
    void Function(double fraction)? onProgress,
  });

  /// Removes the photo for [type]. Same result contract as [uploadPhoto].
  ResultFuture<RiderMeProfileModel?> deletePhoto(VehicleCaptureType type);
}
