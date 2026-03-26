import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_submission_result.dart';

abstract class KycRepository {
  ResultFuture<KycSubmissionResult> submitKyc({
    required KycFormData formData,
    required Map<String, String> uploadedDocUrls,
  });

  ResultFuture<KycStatus> getKycStatus(String userId);

  ResultFuture<String> uploadDoc({
    required String docKey,
    required String filePath,
  });
}
