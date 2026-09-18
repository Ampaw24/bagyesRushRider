import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for the role-agnostic auth API.
class RiderAuthApiService {
  final Dio _dio;

  RiderAuthApiService(this._dio);

  Future<Response<dynamic>> register(Map<String, dynamic> data) =>
      _dio.post(ApiEndpoints.register, data: data);

  Future<Response<dynamic>> login({
    required String phone,
    required String password,
  }) =>
      _dio.post(ApiEndpoints.login, data: {
        'phone': phone,
        'password': password,
      });

  /// Phone verification for a signed-up account.
  Future<Response<dynamic>> sendPhoneCode(String phone) =>
      _dio.post(ApiEndpoints.phoneSendCode, data: {'phone': phone});

  /// Body key is `code` — not `otp`.
  Future<Response<dynamic>> verifyPhone({
    required String phone,
    required String code,
  }) =>
      _dio.post(ApiEndpoints.phoneVerify, data: {
        'phone': phone,
        'code': code,
      });

  /// Public entry point for the forgot-password flow — a different
  /// endpoint from [sendPhoneCode].
  Future<Response<dynamic>> sendForgotPasswordCode(String phone) =>
      _dio.post(ApiEndpoints.passwordForgot, data: {'phone': phone});

  /// Checks a code against a [purpose] from [OtpPurposes] without any
  /// account side-effects.
  Future<Response<dynamic>> verifyOtp({
    required String phone,
    required String code,
    required String purpose,
  }) =>
      _dio.post(ApiEndpoints.otpVerify, data: {
        'phone': phone,
        'code': code,
        'purpose': purpose,
      });

  Future<Response<dynamic>> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  }) =>
      _dio.post(ApiEndpoints.passwordReset, data: {
        'phone': phone,
        'code': code,
        'password': password,
        'password_confirmation': confirmPassword,
      });

  /// Requires Bearer auth (the interceptor attaches it). Distinct from
  /// [sendForgotPasswordCode]/[resetPassword] — this needs the current
  /// password, not an OTP.
  Future<Response<dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _dio.post(ApiEndpoints.passwordChange, data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });

  Future<Response<dynamic>> getProfile() => _dio.get(ApiEndpoints.profile);

  Future<Response<dynamic>> logout() => _dio.post(ApiEndpoints.logout);

  /// Records terms-of-service + background-verification consent
  /// (`POST /rider/me/agreement`). Requires Bearer auth — only reachable
  /// once `register`/`login` has produced a session token.
  Future<Response<dynamic>> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) =>
      _dio.post(ApiEndpoints.riderMeAgreement, data: {
        'accept_terms': acceptTerms,
        'consent_to_verification': consentToVerification,
        if (termsVersion != null) 'terms_version': termsVersion,
      });
}
