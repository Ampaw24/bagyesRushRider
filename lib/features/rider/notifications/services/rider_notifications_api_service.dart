import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class RiderNotificationsApiService {
  final Dio _dio;

  RiderNotificationsApiService(this._dio);

  Future<Response<dynamic>> getNotifications(String userId) {
    return _dio.get(ApiEndpoints.getNotifications(userId));
  }
}
