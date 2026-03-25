import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class RiderAuthApiService {
  final Dio _dio;

  RiderAuthApiService(this._dio);

  Future<Response<dynamic>> login(Map<String, dynamic> data) {
    return _dio.post(ApiEndpoints.riderLogin, data: data);
  }

  Future<Response<dynamic>> signup(Map<String, dynamic> data) {
    return _dio.post(ApiEndpoints.riderSignup, data: data);
  }

  Future<Response<dynamic>> sendOtp(Map<String, dynamic> data) {
    return _dio.post(ApiEndpoints.sendOtp, data: data);
  }

  Future<Response<dynamic>> resetPassword(Map<String, dynamic> data) {
    return _dio.put(ApiEndpoints.resetPassword, data: data);
  }
}
