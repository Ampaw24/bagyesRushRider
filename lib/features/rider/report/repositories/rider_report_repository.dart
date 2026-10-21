import 'dart:io';

import 'package:gopady_rider/constant/typedef.dart';
import 'package:gopady_rider/features/rider/report/models/rider_report_model.dart';

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
