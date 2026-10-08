import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/auth/models/auth_user_model.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_agreement_model.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/services/rider_auth_api_service.dart';

class RiderAuthRepositoryImpl implements RiderAuthRepository {
  final RiderAuthApiService _api;

  RiderAuthRepositoryImpl(this._api);

  @override
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String city,
    required int vehicleTypeId,
    required String plateNumber,
  }) =>
      _run(() async {
        final response = await _api.register({
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': confirmPassword,
          'role': AuthRoles.rider,
          'first_name': firstName,
          'last_name': lastName,
          'city': city,
          'vehicle_type_id':  vehicleTypeId,
          // Normalised: `unique:riders,plate_number` is a raw string
          // comparison, and TextCapitalization is only a keyboard hint —
          // it doesn't touch pasted text.
          'plate_number': plateNumber.trim().toUpperCase(),
        });
        return _parseAuth(response);
      });

  /// What the server answers for a wrong phone or password (a 422 with
  /// `{message: "Invalid credentials", errors: {email: [...]}}`, checked
  /// against the live API), reproduced so that turning away another app's
  /// account looks exactly the same.
  static const _invalidCredentials = ValidationFailure('Invalid credentials', {
    'email': ['Invalid credentials'],
  });

  /// `/login` is shared by every app, so a customer's or vendor's correct
  /// password succeeds here too. Only riders get in; anyone else gets the
  /// wrong-credentials error — before the caller stores the session, so
  /// the next launch can't restore it, and without revealing that the
  /// account exists under another role.
  @override
  Future<Either<Failure, AuthResult>> login({
    required String phone,
    required String password,
  }) async {
    final result = await _run(() async {
      final response = await _api.login(phone: phone, password: password);
      return _parseAuth(response);
    });
    return result.flatMap((auth) {
      if (auth.user.isRider) return Right(auth);
      appLogger.w('[Auth] login refused: account ${auth.user.id} has role '
          '"${auth.user.role}", not a rider');
      return const Left(_invalidCredentials);
    });
  }

  @override
  Future<Either<Failure, void>> sendPhoneCode({required String phone}) =>
      _run(() => _api.sendPhoneCode(phone));

  @override
  Future<Either<Failure, void>> verifyPhone({
    required String phone,
    required String code,
  }) =>
      _run(() => _api.verifyPhone(phone: phone, code: code));

  @override
  Future<Either<Failure, void>> sendForgotPasswordCode({
    required String phone,
  }) =>
      _run(() => _api.sendForgotPasswordCode(phone));

  @override
  Future<Either<Failure, void>> verifyPasswordResetCode({
    required String phone,
    required String code,
  }) =>
      _run(() => _api.verifyOtp(
            phone: phone,
            code: code,
            purpose: OtpPurposes.accountRecovery,
          ));

  @override
  Future<Either<Failure, void>> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  }) =>
      _run(() => _api.resetPassword(
            phone: phone,
            code: code,
            password: password,
            confirmPassword: confirmPassword,
          ));

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _run(() => _api.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          ));

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String password,
    String? reason,
  }) =>
      _run(() => _api.deleteAccount(password: password, reason: reason));

  @override
  Future<Either<Failure, AuthUserModel>> getProfile() => _run(() async {
        final response = await _api.getProfile();
        // NOTE: /profile has no `user` envelope level — unlike login/register.
        final raw = (response.data as Map).cast<String, dynamic>();
        final payload =
            (raw['data'] as Map?)?.cast<String, dynamic>() ?? raw;
        return AuthUserModel.fromJson(payload);
      });

  @override
  Future<Either<Failure, void>> logout() => _run(() => _api.logout());

  @override
  Future<Either<Failure, RiderAgreementModel>> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) =>
      _run(() async {
        final response = await _api.acceptAgreement(
          acceptTerms: acceptTerms,
          consentToVerification: consentToVerification,
          termsVersion: termsVersion,
        );
        final raw = (response.data as Map?)?.cast<String, dynamic>() ?? {};
        final payload = (raw['data'] as Map?)?.cast<String, dynamic>() ?? raw;
        return RiderAgreementModel.fromJson(
          payload,
          fallbackAcceptTerms: acceptTerms,
          fallbackConsentToVerification: consentToVerification,
          fallbackTermsVersion: termsVersion,
        );
      });

  // ── Parsing ─────────────────────────────────────────────────────────────

  /// Unwraps `{data: {user, token}}`, `{data: {...user, token}}` and a bare
  /// `{user, token}` alike.
  AuthResult _parseAuth(Response<dynamic> response) {
    final raw = (response.data as Map).cast<String, dynamic>();
    final payload = (raw['data'] as Map?)?.cast<String, dynamic>() ?? raw;
    final userJson =
        (payload['user'] as Map?)?.cast<String, dynamic>() ?? payload;

    return (
      user: AuthUserModel.fromJson(userJson),
      token: payload['token'] as String? ?? payload['access_token'] as String?,
      refreshToken: payload['refresh_token'] as String?,
    );
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = dioErrorMessage(e);

      // Keep the field keys when the server rejected specific inputs, so the
      // view can place each message on the field that caused it.
      final fieldErrors = apiFieldErrorsFrom(data);
      if (fieldErrors != null) {
        return Left(ValidationFailure(msg, fieldErrors));
      }
      return Left(ServerFailure(msg));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }
}
