import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio call for `/realtime/config` — see `RealtimeService`, which owns
/// interpreting the response.
class RealtimeConfigApiService {
  final Dio _dio;

  RealtimeConfigApiService(this._dio);

  Future<Response<dynamic>> getConfig() => _dio.get(ApiEndpoints.realtimeConfig);
}
