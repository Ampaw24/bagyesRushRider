import 'package:dio/dio.dart';
import 'package:gopady_rider/core/network/api_endpoints.dart';

/// Raw Dio call for `GET /banners` — public, no auth required.
class RiderBannerApiService {
  final Dio _dio;

  RiderBannerApiService(this._dio);

  Future<Response<dynamic>> getBanners() => _dio.get(ApiEndpoints.banners);
}
