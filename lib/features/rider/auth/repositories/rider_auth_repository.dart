import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';

typedef AuthResult = ({RiderUserModel user, String token});

abstract class RiderAuthRepository {
  ResultFuture<AuthResult> login({
    required String phone,
    required String password,
  });

  ResultFuture<AuthResult> signup({
    required String phone,
    required String password,
    required String otp,
  });

  ResultFuture<void> sendOtp({required String phoneNumber});

  ResultFuture<void> resetPassword({
    required String phone,
    required String newPassword,
  });
}
