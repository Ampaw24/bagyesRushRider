import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/auth/models/auth_user_model.dart';

/// [token] is nullable because `/register` does not always issue one —
/// callers must handle the "registered but not yet authenticated" case.
typedef AuthResult = ({
  AuthUserModel user,
  String? token,
  String? refreshToken,
});

abstract class RiderAuthRepository {
  /// Registers a rider account. `role` is not a parameter — the
  /// implementation always sends [AuthRoles.rider].
  ///
  /// All eight fields are required by the backend's `RegisterRequest` for
  /// `role: rider`, so this cannot be called until the vehicle screens have
  /// collected [vehicleType] and [plateNumber].
  ResultFuture<AuthResult> register({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,

    /// `required_if:role,vendor,rider`, max 255.
    required String city,

    /// Must be one of `VehicleType::selectable()` — currently only
    /// `motorbike`.
    required String vehicleType,

    /// Non-nullable on purpose: the backend exempts bicycles, but bicycle
    /// isn't selectable, so a rider always needs a plate. Relax to `String?`
    /// only if that changes. `unique:riders,plate_number`, max 32.
    required String plateNumber,
  });

  ResultFuture<AuthResult> login({
    required String phone,
    required String password,
  });

  /// Phone verification for a signed-up account (`/phone/send-code`).
  ResultFuture<void> sendPhoneCode({required String phone});

  ResultFuture<void> verifyPhone({
    required String phone,
    required String code,
  });

  /// Starts the forgot-password flow (`/password/forgot`) — a different
  /// endpoint from [sendPhoneCode]; they are not interchangeable.
  ResultFuture<void> sendForgotPasswordCode({required String phone});

  ResultFuture<void> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  });

  ResultFuture<AuthUserModel> getProfile();

  ResultFuture<void> logout();
}
