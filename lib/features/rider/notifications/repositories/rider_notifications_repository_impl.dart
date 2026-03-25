import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notifications_repository.dart';
import 'package:delivery_boy/features/rider/notifications/services/rider_notifications_api_service.dart';

class RiderNotificationsRepositoryImpl implements RiderNotificationsRepository {
  final RiderNotificationsApiService _api;

  RiderNotificationsRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderNotificationModel>>> getNotifications(
      String userId) =>
      _run(() async {
        final response = await _api.getNotifications(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to load notifications');
        }
        final data = body['data'];
        if (data is List) {
          return data
              .map((e) =>
                  RiderNotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <RiderNotificationModel>[];
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
