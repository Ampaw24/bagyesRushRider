import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_target_type_step.dart'
    show targetTypeIcon;

/// Leading-badge icon — a checkmark/cancel glyph once a report is closed,
/// the target-type icon while it's still open.
IconData _cardIcon(RiderReportModel report) => switch (report.status) {
      RiderReportStatus.resolved => HugeIcons.strokeRoundedCheckmarkCircle01,
      RiderReportStatus.dismissed => HugeIcons.strokeRoundedCancelCircle,
      _ => targetTypeIcon(report.targetType),
    };

Color _badgeColor(RiderReportStatus status) => switch (status) {
      RiderReportStatus.pending => AppColors.primary,
      RiderReportStatus.inReview => AppColors.info,
      RiderReportStatus.resolved => AppColors.success,
      RiderReportStatus.dismissed => AppColors.textHint,
    };

/// One-line "who/what this is about".
String reportContextLine(RiderReportModel r) {
  final orderPart = r.orderId != null ? 'Order #${r.orderId}' : null;
  if (orderPart != null &&
      r.targetName.isNotEmpty &&
      r.targetName != orderPart) {
    return '$orderPart · ${r.targetName}';
  }
  return orderPart ?? (r.targetName.isNotEmpty ? r.targetName : 'General');
}

String reportRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String reportNextStepMessage(RiderReportModel r) {
  switch (r.status) {
    case RiderReportStatus.pending:
      final minutesAgo = DateTime.now().difference(r.createdAt).inMinutes;
      return minutesAgo < 30 ? 'Just submitted' : 'Reply expected today';
    case RiderReportStatus.inReview:
      return 'Support is looking into it';
    case RiderReportStatus.resolved:
      return r.resolutionNote ?? 'Resolved';
    case RiderReportStatus.dismissed:
      return r.resolutionNote ?? 'Dismissed';
  }
}

/// Row in the "My Reports" list.
class RiderReportCard extends StatelessWidget {
  final RiderReportModel report;
  final VoidCallback onTap;

  const RiderReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final badgeColor = _badgeColor(report.status);
    final statusColor = report.status.color;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.028),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(
                    icon: _cardIcon(report), color: badgeColor, size: w * 0.05),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.reasonLabel,
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          reportRelativeTime(report.createdAt),
                          style: TextStyle(
                              fontSize: w * 0.027, color: AppColors.textHint),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.006),
                    Text(
                      reportContextLine(report),
                      style: TextStyle(
                          fontSize: w * 0.031, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: w * 0.02),
                    Row(
                      children: [
                        Container(
                          width: w * 0.016,
                          height: w * 0.016,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                        ),
                        SizedBox(width: w * 0.014),
                        Text(
                          report.status.label,
                          style: TextStyle(
                            fontSize: w * 0.031,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        Text(' · ',
                            style: TextStyle(
                                fontSize: w * 0.031,
                                color: AppColors.textHint)),
                        Expanded(
                          child: Text(
                            reportNextStepMessage(report),
                            style: TextStyle(
                                fontSize: w * 0.031,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
