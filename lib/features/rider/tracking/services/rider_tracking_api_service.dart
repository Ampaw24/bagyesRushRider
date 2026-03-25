import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class RiderTrackingApiService {
  final Dio _dio;

  RiderTrackingApiService(this._dio);

  Future<Response<dynamic>> updateLocation(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.updateLocation, data: data);
  }
}
