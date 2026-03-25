import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_orders_repository.dart';
import 'package:delivery_boy/features/rider/orders/services/rider_orders_api_service.dart';

class RiderOrdersRepositoryImpl implements RiderOrdersRepository {
  final RiderOrdersApiService _api;

  RiderOrdersRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderOrderModel>>> getRequestedOrders(
          String userId) =>
      _run(() async {
        final response = await _api.getRequestedOrders(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to load orders');
        }
        final list = body['data'] as List? ?? [];
        return list
            .map((e) => RiderOrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Either<Failure, List<RiderOrderModel>>> getActiveOrders(
          String userId) =>
      _run(() async {
        final response = await _api.getActiveOrders(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to load active orders');
        }
        final list = body['data'] as List? ?? [];
        return list
            .map((e) => RiderOrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Either<Failure, List<RiderOrderModel>>> getHistory(String userId) =>
      _run(() async {
        final response = await _api.getHistory(userId);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to load history');
        }
        final list = body['data'] as List? ?? [];
        return list
            .map((e) => RiderOrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Either<Failure, void>> acceptOrder({
    required String orderId,
    required String courierId,
  }) =>
      _run(() async {
        final response = await _api
            .acceptOrder({'orderId': orderId, 'courier': courierId});
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to accept order');
        }
      });

  @override
  Future<Either<Failure, void>> rejectOrder({
    required String orderId,
    required String courierId,
    required String reason,
  }) =>
      _run(() async {
        final response = await _api.rejectOrder({
          'orderId': orderId,
          'courier': courierId,
          'reason': reason,
        });
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to reject order');
        }
      });

  @override
  Future<Either<Failure, void>> updateOrderStatus({
    required String orderId,
    required String status,
  }) =>
      _run(() async {
        final response = await _api.updateOrder({
          'id': orderId,
          'data': {'status': status},
        });
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to update order');
        }
      });

  @override
  Future<Either<Failure, void>> setTrip(Map<String, dynamic> data) =>
      _run(() async {
        final response = await _api.setTrip(data);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to set trip');
        }
      });

  @override
  Future<Either<Failure, void>> finishTrip(Map<String, dynamic> data) =>
      _run(() async {
        final response = await _api.finishTrip(data);
        final body = response.data as Map<String, dynamic>;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to finish trip');
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
