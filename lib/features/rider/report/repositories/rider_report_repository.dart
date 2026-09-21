import 'dart:io';

import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';

/// Contract for the "Report a Problem" feature — see
/// `RiderReportApiService` and `ApiEndpoints.riderMeReports`.
abstract class RiderReportRepository {
  ResultFuture<List<RiderReportModel>> getReports();
  ResultFuture<RiderReportModel> getReportById(int id);
  ResultFuture<RiderReportReasonCatalog> getReportReasons();

  ResultFuture<RiderReportModel> submitReport({
    required RiderReportTargetType targetType,
    int? orderId,
    required String targetName,
    String? targetPhone,
    required String reasonCode,
    required String reasonLabel,
    required String description,
    List<File> attachments = const [],
  });
}
