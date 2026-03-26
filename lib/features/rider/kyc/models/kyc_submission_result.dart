import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';

class KycSubmissionResult {
  final bool success;
  final KycStatus status;
  final String? message;

  const KycSubmissionResult({
    required this.success,
    required this.status,
    this.message,
  });
}
