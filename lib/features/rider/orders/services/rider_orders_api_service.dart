import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class RiderOrdersApiService {
  final Dio _dio;

  RiderOrdersApiService(this._dio);

  Future<Response<dynamic>> getRequestedOrders(String userId) {
    return _dio.get(ApiEndpoints.getRequested(userId));
  }

  Future<Response<dynamic>> getActiveOrders(String userId) {
    return _dio.get(ApiEndpoints.getActiveOrders(userId));
  }

  Future<Response<dynamic>> getHistory(String userId) {
    return _dio.get(ApiEndpoints.getHistory(userId));
  }

  Future<Response<dynamic>> acceptOrder(Map<String, dynamic> data) {
    return _dio.post(ApiEndpoints.acceptOrder, data: data);
  }

  Future<Response<dynamic>> rejectOrder(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.rejectOrder, data: data);
  }

  Future<Response<dynamic>> updateOrder(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.updateOrder, data: data);
  }

  Future<Response<dynamic>> setTrip(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.setTrip, data: data);
  }

  Future<Response<dynamic>> finishTrip(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.finishTrip, data: data);
  }
}
