import 'package:dio/dio.dart';

import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for `/device-tokens` — the FCM device registry shared with
/// the customer and vendor apps.
///
/// Authenticated: the Bearer header comes from `RiderDioInterceptor`, and the
/// backend associates the device with whoever that token belongs to. There is
/// no user id in the payload.
class DeviceTokenApiService {
  final Dio _dio;

  DeviceTokenApiService(this._dio);

  Future<Response<dynamic>> register({
    required String token,
    required String platform,
    required String deviceName,
  }) =>
      _dio.post(ApiEndpoints.deviceToken, data: {
        'token': token,
        'platform': platform,
        'device_name': deviceName,
      });

  Future<Response<dynamic>> unregister({required String token}) =>
      _dio.delete(ApiEndpoints.deviceToken, data: {'token': token});
}
