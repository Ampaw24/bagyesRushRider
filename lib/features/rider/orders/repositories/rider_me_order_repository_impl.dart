import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/repositories/rider_me_order_repository.dart';
import 'package:delivery_boy/features/rider/orders/services/rider_me_order_api_service.dart';

class RiderMeOrderRepositoryImpl implements RiderMeOrderRepository {
  final RiderMeOrderApiService _api;

  RiderMeOrderRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderMeOfferModel>>> getOffers() =>
      _run(() async {
        final response = await _api.getOffers();
        return _asList(response.data)
            .map((e) => RiderMeOfferModel.fromJson(e))
            .toList();
      });

  @override
  Future<Either<Failure, void>> acceptOffer(int offerId) =>
      _run(() => _api.acceptOffer(offerId));

  @override
  Future<Either<Failure, void>> declineOffer(int offerId, {String? reason}) =>
      _run(() => _api.declineOffer(offerId, reason: reason));

  @override
  Future<Either<Failure, List<RiderMeOrderModel>>> getOrders({
    String? filter,
    String? status,
    int? perPage,
  }) =>
      _run(() async {
        final response =
            await _api.getOrders(filter: filter, status: status, perPage: perPage);
        return _asList(response.data)
            .map((e) => RiderMeOrderModel.fromJson(e))
            .toList();
      });

  @override
  Future<Either<Failure, RiderMeOrderModel>> getOrder(int orderId) =>
      _run(() async {
        final response = await _api.getOrder(orderId);
        return RiderMeOrderModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, void>> arrivedAtPickup(int orderId) =>
      _run(() => _api.arrivedAtPickup(orderId));

  @override
  Future<Either<Failure, void>> pickUpOrder(int orderId) =>
      _run(() => _api.pickUpOrder(orderId));

  @override
  Future<Either<Failure, void>> arrivedAtDropoff(int orderId) =>
      _run(() => _api.arrivedAtDropoff(orderId));

  @override
  Future<Either<Failure, void>> deliverOrder(
    int orderId, {
    required String deliveryPin,
    String? deliveredToName,
    String? proofPhotoPath,
  }) =>
      _run(() => _api.deliverOrder(
            orderId,
            deliveryPin: deliveryPin,
            deliveredToName: deliveredToName,
            proofPhotoPath: proofPhotoPath,
          ));

  @override
  Future<Either<Failure, void>> releaseOrder(int orderId, {String? reason}) =>
      _run(() => _api.releaseOrder(orderId, reason: reason));

  @override
  Future<Either<Failure, void>> markUnreachable(int orderId,
          {String? reason}) =>
      _run(() => _api.markUnreachable(orderId, reason: reason));

  @override
  Future<Either<Failure, void>> arriveAtStop(int orderId, int stopId) =>
      _run(() => _api.arriveAtStop(orderId, stopId));

  @override
  Future<Either<Failure, void>> deliverStop(
    int orderId,
    int stopId, {
    required String deliveryPin,
    String? deliveredToName,
    String? proofPhotoPath,
  }) =>
      _run(() => _api.deliverStop(
            orderId,
            stopId,
            deliveryPin: deliveryPin,
            deliveredToName: deliveredToName,
            proofPhotoPath: proofPhotoPath,
          ));

  @override
  Future<Either<Failure, void>> failStop(
    int orderId,
    int stopId, {
    required String reason,
  }) =>
      _run(() => _api.failStop(orderId, stopId, reason: reason));

  /// Unwraps a Laravel API Resource envelope (`{"data": {...}}`); falls
  /// back to the raw body if it isn't wrapped.
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Unwraps a Laravel collection envelope: a plain list (`{"data": [...]}`,
  /// used by offers) or a paginated one (`{"data": {"items": [...],
  /// "pagination": {...}}}`, used by orders); falls back to a bare JSON
  /// array.
  List<Map<String, dynamic>> _asList(dynamic raw) {
    dynamic data = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (data is Map<String, dynamic>) {
      data = data['items'];
    }
    final list = data as List?;
    return (list ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final data = e.response?.data;
      // The server's per-field message when there is one; never Dio's
      // developer text (see dioErrorMessage).
      final msg = dioErrorMessage(e);

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
