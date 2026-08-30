import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for the `/rider/me` profile API — see
/// the "v1 / rider" Postman collection (profile #1-10).
class RiderMeProfileApiService {
  final Dio _dio;

  RiderMeProfileApiService(this._dio);

  Future<Response<dynamic>> getMe() => _dio.get(ApiEndpoints.riderMe);

  Future<Response<dynamic>> updateProfile(Map<String, dynamic> data) =>
      _dio.put(ApiEndpoints.riderMe, data: data);

  Future<Response<dynamic>> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) =>
      _dio.post(ApiEndpoints.riderMeAgreement, data: {
        'accept_terms': acceptTerms,
        'consent_to_verification': consentToVerification,
        if (termsVersion != null) 'terms_version': termsVersion,
      });

  Future<Response<dynamic>> setAvailability(bool isOnline) =>
      _dio.patch(ApiEndpoints.riderMeAvailability, data: {
        'is_online': isOnline,
      });

  Future<Response<dynamic>> uploadDocument({
    required String type,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'document': await MultipartFile.fromFile(filePath),
    });
    return _dio.post(
      ApiEndpoints.riderMeDocument(type),
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response<dynamic>> getDocument(String type) =>
      _dio.get(ApiEndpoints.riderMeDocument(type));

  Future<Response<dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) =>
      _dio.post(ApiEndpoints.riderMeLocation, data: {
        'latitude': latitude,
        'longitude': longitude,
      });

  Future<Response<dynamic>> updatePayout({
    int? payoutProviderId,
    String? accountNumber,
    String? accountName,
    int? momoProviderId,
    String? mobileMoneyNumber,
  }) =>
      _dio.put(ApiEndpoints.riderMePayout, data: {
        if (payoutProviderId != null) 'payout_provider_id': payoutProviderId,
        if (accountNumber != null) 'account_number': accountNumber,
        if (accountName != null) 'account_name': accountName,
        if (momoProviderId != null) 'momo_provider_id': momoProviderId,
        if (mobileMoneyNumber != null)
          'mobile_money_number': mobileMoneyNumber,
      });

  Future<Response<dynamic>> uploadPhoto(String filePath) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    return _dio.post(
      ApiEndpoints.riderMePhoto,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response<dynamic>> submitForReview() =>
      _dio.post(ApiEndpoints.riderMeSubmitReview);
}
