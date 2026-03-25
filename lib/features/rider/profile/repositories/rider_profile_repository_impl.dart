import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_profile_repository.dart';
import 'package:delivery_boy/features/rider/profile/services/rider_profile_api_service.dart';

class RiderProfileRepositoryImpl implements RiderProfileRepository {
  final RiderProfileApiService _api;

  RiderProfileRepositoryImpl(this._api);

  @override
  Future<Either<Failure, RiderUserModel>> getProfile(String userId) =>
      _run(() async {
        final response = await _api.getProfile(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to load profile');
        }
        return RiderUserModel.fromJson(body['data'] as Map<String, dynamic>);
      });

  @override
  Future<Either<Failure, RiderUserModel>> updateCourier(
          Map<String, dynamic> data) =>
      _run(() async {
        final response = await _api.updateCourier(data);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to update profile');
        }
        return RiderUserModel.fromJson(body['data'] as Map<String, dynamic>);
      });

  @override
  Future<Either<Failure, RiderUserModel>> uploadDoc(FormData formData) =>
      _run(() async {
        final response = await _api.uploadDoc(formData);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to upload document');
        }
        return RiderUserModel.fromJson(body['data'] as Map<String, dynamic>);
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
