import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class RiderProfileApiService {
  final Dio _dio;

  RiderProfileApiService(this._dio);

  Future<Response<dynamic>> getProfile(String userId) {
    return _dio.get(ApiEndpoints.riderProfile(userId));
  }

  Future<Response<dynamic>> updateCourier(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.updateCourier, data: data);
  }

  Future<Response<dynamic>> uploadDoc(FormData formData) {
    return _dio.put(ApiEndpoints.uploadDoc, data: formData);
  }
}
