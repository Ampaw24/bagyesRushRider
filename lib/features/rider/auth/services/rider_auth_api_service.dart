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

  Future<Response<dynamic>> getProfile() => _dio.get(ApiEndpoints.profile);

  Future<Response<dynamic>> logout() => _dio.post(ApiEndpoints.logout);
}
