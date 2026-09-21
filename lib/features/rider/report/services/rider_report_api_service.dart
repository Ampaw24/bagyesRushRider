import 'dart:io';

import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';

/// Raw Dio calls for the "Report a Problem" feature — see
/// [ApiEndpoints.riderMeReports] for why this path is unverified.
class RiderReportApiService {
  final Dio _dio;

  RiderReportApiService(this._dio);

  Future<Response<dynamic>> getReports() =>
      _dio.get(ApiEndpoints.riderMeReports);

  Future<Response<dynamic>> getReportById(int id) =>
      _dio.get(ApiEndpoints.riderMeReport(id));

  Future<Response<dynamic>> getReportReasons() =>
      _dio.get(ApiEndpoints.reportReasons);

  Future<Response<dynamic>> submitReport({
    required RiderReportTargetType targetType,
    int? orderId,
    required String targetName,
    String? targetPhone,
    required String reasonCode,
    required String reasonLabel,
    required String description,
    List<File> attachments = const [],
  }) async {
    final formData = FormData.fromMap({
      'target_type': targetType.apiValue,
      if (orderId != null) 'order_id': orderId,
      'target_name': targetName,
      if (targetPhone != null && targetPhone.isNotEmpty)
        'target_phone': targetPhone,
      'reason_code': reasonCode,
      'reason_label': reasonLabel,
      'description': description,
    });
    for (final file in attachments) {
      formData.files.add(
        MapEntry('attachments[]', await MultipartFile.fromFile(file.path)),
      );
    }
    return _dio.post(ApiEndpoints.riderMeReports, data: formData);
  }
}
