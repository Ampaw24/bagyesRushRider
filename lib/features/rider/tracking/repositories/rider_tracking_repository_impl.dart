import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/tracking/repositories/rider_tracking_repository.dart';
import 'package:delivery_boy/features/rider/tracking/services/rider_tracking_api_service.dart';

class RiderTrackingRepositoryImpl implements RiderTrackingRepository {
  final RiderTrackingApiService _api;

  RiderTrackingRepositoryImpl(this._api);

  @override
  Future<Either<Failure, void>> updateLocation(
          Map<String, dynamic> data) =>
      _run(() async {
        final response = await _api.updateLocation(data);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to update location');
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
