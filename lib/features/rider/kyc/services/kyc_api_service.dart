import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

class KycApiService {
  final Dio _dio;

  KycApiService(this._dio);

  Future<Response<dynamic>> submitKyc(Map<String, dynamic> data) {
    return _dio.post(ApiEndpoints.submitKyc, data: data);
  }

  Future<Response<dynamic>> getKycStatus(String userId) {
    return _dio.get(ApiEndpoints.getKycStatus(userId));
  }

  Future<Response<dynamic>> uploadKycDoc(FormData formData) {
    return _dio.post(
      ApiEndpoints.uploadKycDoc,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
