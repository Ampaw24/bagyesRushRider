import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for `/rider/me/vehicle-photos/:side` — Bearer auth, rider
/// accounts only. Both calls return the full rider profile.
class RiderVehiclePhotoApiService {
  final Dio _dio;

  RiderVehiclePhotoApiService(this._dio);

  /// Uploading a side again replaces it; the server deletes the old file.
  Future<Response<dynamic>> uploadPhoto({
    required String side,
    required String filePath,
    ProgressCallback? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    return _dio.post(
      ApiEndpoints.riderMeVehiclePhoto(side),
      data: form,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
  }

  Future<Response<dynamic>> deletePhoto(String side) =>
      _dio.delete(ApiEndpoints.riderMeVehiclePhoto(side));
}
