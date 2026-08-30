import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/features/rider/auth/models/auth_user_model.dart';
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
    required String vehicleType,
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
          'vehicle_type': vehicleType,
          // Normalised: `unique:riders,plate_number` is a raw string
          // comparison, and TextCapitalization is only a keyboard hint —
          // it doesn't touch pasted text.
          'plate_number': plateNumber.trim().toUpperCase(),
        });
        return _parseAuth(response);
      });

  @override
  Future<Either<Failure, AuthResult>> login({
    required String phone,
    required String password,
  }) =>
      _run(() async {
        final response = await _api.login(phone: phone, password: password);
        return _parseAuth(response);
      });

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
      final msg = apiMessageFrom(data) ?? e.message ?? 'Request failed';

      // Keep the field keys when the server rejected specific inputs, so the
      // view can place each message on the field that caused it.
      final fieldErrors = apiFieldErrorsFrom(data);
      if (fieldErrors != null) {
        return Left(ValidationFailure(msg, fieldErrors));
      }
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
