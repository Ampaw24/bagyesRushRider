import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for the `/rider/me` order lifecycle API — see
/// the "v1 / rider" Postman collection (order #1-11).
class RiderMeOrderApiService {
  final Dio _dio;

  RiderMeOrderApiService(this._dio);

  Future<Response<dynamic>> getOffers() =>
      _dio.get(ApiEndpoints.riderMeOffers);

  Future<Response<dynamic>> acceptOffer(int id) =>
      _dio.post(ApiEndpoints.riderMeOfferAccept(id));

  Future<Response<dynamic>> declineOffer(int id, {String? reason}) =>
      _dio.post(
        ApiEndpoints.riderMeOfferDecline(id),
        data: {if (reason != null) 'reason': reason},
      );

  Future<Response<dynamic>> getOrders({
    String? filter,
    String? status,
    int? perPage,
  }) =>
      _dio.get(ApiEndpoints.riderMeOrders, queryParameters: {
        if (filter != null) 'filter': filter,
        if (status != null) 'status': status,
        if (perPage != null) 'per_page': perPage,
      });

  Future<Response<dynamic>> getOrder(int id) =>
      _dio.get(ApiEndpoints.riderMeOrder(id));

  Future<Response<dynamic>> arrivedAtPickup(int id) =>
      _dio.post(ApiEndpoints.riderMeOrderArrivedAtPickup(id));

  Future<Response<dynamic>> pickUpOrder(int id) =>
      _dio.post(ApiEndpoints.riderMeOrderPickUp(id));

  Future<Response<dynamic>> deliverOrder(
    int id, {
    String? deliveredToName,
    String? proofPhotoPath,
  }) async {
    final form = FormData.fromMap({
      if (deliveredToName != null) 'delivered_to_name': deliveredToName,
      if (proofPhotoPath != null)
        'proof_photo': await MultipartFile.fromFile(proofPhotoPath),
    });
    return _dio.post(ApiEndpoints.riderMeOrderDeliver(id), data: form);
  }

  Future<Response<dynamic>> releaseOrder(int id, {String? reason}) =>
      _dio.post(
        ApiEndpoints.riderMeOrderRelease(id),
        data: {if (reason != null) 'reason': reason},
      );

  Future<Response<dynamic>> deliverStop(
    int id,
    int stopId, {
    String? deliveredToName,
    String? proofPhotoPath,
  }) async {
    final form = FormData.fromMap({
      if (deliveredToName != null) 'delivered_to_name': deliveredToName,
      if (proofPhotoPath != null)
        'proof_photo': await MultipartFile.fromFile(proofPhotoPath),
    });
    return _dio.post(
      ApiEndpoints.riderMeOrderStopDeliver(id, stopId),
      data: form,
    );
  }

  Future<Response<dynamic>> failStop(
    int id,
    int stopId, {
    required String reason,
  }) =>
      _dio.post(
        ApiEndpoints.riderMeOrderStopFail(id, stopId),
        data: {'reason': reason},
      );
}
