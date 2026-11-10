import 'package:gopady_rider/constant/typedef.dart';
import 'package:gopady_rider/features/rider/auth/models/auth_user_model.dart';
import 'package:gopady_rider/features/rider/auth/models/rider_agreement_model.dart';

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
  /// No vehicle fields: type, plate, make and model are collected after
  /// signup in the KYC vehicle section (`PUT /rider/me`). This relies on the
  /// backend's `RegisterRequest` not requiring `vehicle_type_id` or
  /// `plate_number` for `role: rider`.
  ResultFuture<AuthResult> register({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,

    /// `required_if:role,vendor,rider`, max 255.
    required String city,
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

  /// Confirms a [sendForgotPasswordCode] code (`/otp/verify`, purpose
  /// `account_recovery`) so a wrong code is caught before the rider types a
  /// new password. [resetPassword] still needs the same code.
  ResultFuture<void> verifyPasswordResetCode({
    required String phone,
    required String code,
  });

  ResultFuture<void> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  });

  /// Changes the signed-in rider's password (`/password/change`). Keeps the
  /// rider signed in and needs their current password — distinct from the
  /// OTP-based [sendForgotPasswordCode]/[resetPassword] flow, which is for
  /// a rider who can't provide one.
  ResultFuture<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Permanently deletes the signed-in rider's account
  /// (`POST /account/delete`). Requires the current password to confirm
  /// intent; `reason` is optional feedback sent to support.
  ResultFuture<void> deleteAccount({
    required String password,
    String? reason,
  });

  ResultFuture<AuthUserModel> getProfile();

  ResultFuture<void> logout();

  /// Records terms-of-service + background-verification consent
  /// (`POST /rider/me/agreement`). Requires Bearer auth, so this can only
  /// succeed once [register] (or [login]) has produced a session token —
  /// see `RiderAuthNotifier.registerAndAcceptAgreement`, which sequences
  /// the two correctly.
  ResultFuture<RiderAgreementModel> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  });
}
