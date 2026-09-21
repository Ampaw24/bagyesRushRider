import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notification_repository.dart';
import 'package:delivery_boy/features/rider/notifications/services/rider_notification_api_service.dart';

class RiderNotificationRepositoryImpl implements RiderNotificationRepository {
  final RiderNotificationApiService _api;

  RiderNotificationRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderNotificationModel>>>
      getNotifications() async {
    try {
      final response = await _api.getNotifications();
      final notifications = _asList(response.data)
          .map((e) => RiderNotificationModel.fromJson(e))
          .toList();
      return Right(notifications);
    } on DioException catch (e) {
      return Left(ServerFailure(dioErrorMessage(e)));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) =>
      _runVoid(() => _api.markRead(id));

  @override
  Future<Either<Failure, void>> markAllRead() =>
      _runVoid(() => _api.markAllRead());

  @override
  Future<Either<Failure, void>> deleteNotification(String id) =>
      _runVoid(() => _api.deleteNotification(id));

  Future<Either<Failure, void>> _runVoid(
    Future<Response<dynamic>> Function() action,
  ) async {
    try {
      await action();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(dioErrorMessage(e)));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }

  /// Unwraps a Laravel paginated collection envelope
  /// (`{"data": {"items": [...], "pagination": {...}}}`), a plain
  /// collection envelope (`{"data": [...]}`), or a bare JSON array.
  List<Map<String, dynamic>> _asList(dynamic raw) {
    final data = raw is Map<String, dynamic> ? raw['data'] : raw;
    final list = data is Map<String, dynamic> ? data['items'] : data;
    return (list is List ? list : const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }
}
