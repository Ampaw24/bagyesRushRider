import 'package:equatable/equatable.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';

/// Navigation payload for the report wizard.
///
/// The primary entry point (Settings → "Report a Problem") leaves every
/// field null so the wizard starts from "what would you like to report?".
/// A contextual entry point (an order's detail sheet) can pre-fill
/// [targetType] and/or the target fields so the wizard skips straight to
/// the reason step.
///
/// [Equatable] so this can key a Riverpod `.family` provider — one form
/// notifier instance per distinct wizard run.
class RiderReportFlowArgs extends Equatable {
  const RiderReportFlowArgs({
    this.targetType,
    this.orderId,
    this.targetName,
    this.targetImageUrl,
    this.targetPhone,
  });

  final RiderReportTargetType? targetType;
  final int? orderId;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  @override
  List<Object?> get props =>
      [targetType, orderId, targetName, targetImageUrl, targetPhone];
}
