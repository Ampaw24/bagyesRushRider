import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';
import 'package:delivery_boy/features/rider/auth/services/rider_auth_api_service.dart';

class RiderAuthRepositoryImpl implements RiderAuthRepository {
  final RiderAuthApiService _api;

  RiderAuthRepositoryImpl(this._api);

  @override
  Future<Either<Failure, AuthResult>> login({
    required String phone,
    required String password,
  }) =>
      _run(() async {
        final response = await _api.login({'phone': phone, 'password': password});
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Login failed');
        }
        return (
          user: RiderUserModel.fromJson(body['data'] as Map<String, dynamic>),
          token: body['token'] as String,
        );
      });

  @override
  Future<Either<Failure, AuthResult>> signup({
    required String phone,
    required String password,
    required String otp,
    required String name,
    String? email,
  }) =>
      _run(() async {
        final response = await _api.signup({
          'phone': phone,
          'password': password,
          'otp': otp,
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        });
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Signup failed');
        }
        return (
          user: RiderUserModel.fromJson(body['data'] as Map<String, dynamic>),
          token: body['token'] as String,
        );
      });

  @override
  Future<Either<Failure, void>> sendOtp({required String phoneNumber}) =>
      _run(() async {
        final response = await _api.sendOtp({'phoneNumber': phoneNumber});
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to send OTP');
        }
      });

  @override
  Future<Either<Failure, void>> resetPassword({
    required String phone,
    required String newPassword,
  }) =>
      _run(() async {
        final response = await _api.resetPassword({
          'phone': phone,
          'password': newPassword,
        });
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to reset password');
        }
      });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Request failed';
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
