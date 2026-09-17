import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';

/// Contract for the `/rider/me` profile API — see
/// the "v1 / rider" Postman collection (profile #1-10).
abstract class RiderMeProfileRepository {
  ResultFuture<RiderMeProfileModel> getMe();

  /// Partial update — pass only the fields being changed (all fields on
  /// the endpoint are `sometimes`/`nullable`).
  ResultFuture<RiderMeProfileModel> updateProfile(Map<String, dynamic> data);

  ResultFuture<void> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  });

  ResultFuture<void> setAvailability(bool isOnline);

  ResultFuture<RiderMeDocumentModel> uploadDocument({
    required String type,
    required String filePath,
  });

  ResultFuture<RiderMeDocumentModel> getDocument(String type);

  ResultFuture<void> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speedKph,
    int? accuracyM,
  });

  /// Offline catch-up upload — chunk to at most 60 pings per call.
  ResultFuture<void> updateLocationBatch(List<RiderMeLocationPing> pings);

  /// `current_password` is required — validated against the password of the
  /// user behind the current Sanctum token.
  ResultFuture<RiderMeProfileModel> updatePayout({
    required String currentPassword,
    int? payoutProviderId,
    String? accountNumber,
    String? accountName,
    int? momoProviderId,
    String? mobileMoneyNumber,
  });

  ResultFuture<String?> uploadPhoto(String filePath);

  ResultFuture<void> submitForReview();
}
