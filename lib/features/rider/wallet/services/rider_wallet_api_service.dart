import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class RiderWalletApiService {
  final Dio _dio;

  RiderWalletApiService(this._dio);

  Future<Response<dynamic>> getEarnings(String userId) {
    return _dio.get(ApiEndpoints.getEarnings(userId));
  }
}
