import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for server-managed legal documents.
class LegalDocumentApiService {
  final Dio _dio;

  LegalDocumentApiService(this._dio);

  Future<Response<dynamic>> getRiderAgreement() =>
      _dio.get(ApiEndpoints.riderAgreement);
}
