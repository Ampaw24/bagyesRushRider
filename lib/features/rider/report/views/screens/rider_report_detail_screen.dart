import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:delivery_boy/features/rider/report/providers/rider_my_reports_providers.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_card.dart'
    show reportRelativeTime;
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_status_badge.dart';
import 'package:delivery_boy/features/rider/report/views/widgets/rider_report_target_type_step.dart'
    show targetTypeIcon;

class RiderReportDetailScreen extends ConsumerWidget {
  final int reportId;

  const RiderReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final async = ref.watch(riderReportDetailProvider(reportId));

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Report Details')),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.1),
            child: Text(
              "Couldn't load this report.\n${error is Failure ? error.message : error}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: w * 0.034),
            ),
          ),
        ),
        data: (report) => ListView(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.05),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(w * 0.045),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(w * 0.03),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: targetTypeIcon(report.targetType),
                          color: AppColors.primary,
                          size: w * 0.06,
                        ),
                      ),
                      SizedBox(width: w * 0.035),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RiderReportStatusBadge(status: report.status),
                            SizedBox(height: w * 0.02),
                            Text(
                              report.reasonLabel,
                              style: TextStyle(
                                fontSize: w * 0.046,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.04),
                  _InfoRow(label: 'Reported', value: report.targetName, w: w),
                  if (report.orderId != null)
                    _InfoRow(label: 'Order', value: '#${report.orderId}', w: w),
                  _InfoRow(
                      label: 'Submitted',
                      value: reportRelativeTime(report.createdAt),
                      w: w),
                ],
              ),
            ),
            SizedBox(height: w * 0.05),
            _SectionLabel('Your description', w: w),
            SizedBox(height: w * 0.025),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.045),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(w * 0.04),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                report.description,
                style: TextStyle(
                    fontSize: w * 0.036,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ),
            if (report.attachmentUrls.isNotEmpty) ...[
              SizedBox(height: w * 0.05),
              _SectionLabel('Photos', w: w),
              SizedBox(height: w * 0.025),
              Wrap(
                spacing: w * 0.03,
                runSpacing: w * 0.03,
                children: [
                  for (final url in report.attachmentUrls)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      child: Image.network(
                        url,
                        width: (w - w * 0.1 - w * 0.03 * 2) / 3,
                        height: (w - w * 0.1 - w * 0.03 * 2) / 3,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: (w - w * 0.1 - w * 0.03 * 2) / 3,
                          height: (w - w * 0.1 - w * 0.03 * 2) / 3,
                          color: AppColors.surfaceVariant,
                          child: Icon(Icons.broken_image,
                              color: AppColors.textHint),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: w * 0.05),
            _SectionLabel('Status', w: w),
            SizedBox(height: w * 0.025),
            _StatusTimeline(
                status: report.status,
                resolutionNote: report.resolutionNote,
                w: w),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double w;
  const _InfoRow({required this.label, required this.value, required this.w});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: w * 0.02),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textHint)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: w * 0.032,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final double w;
  const _SectionLabel(this.label, {required this.w});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: w * 0.03,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final RiderReportStatus status;
  final String? resolutionNote;
  final double w;

  const _StatusTimeline(
      {required this.status, required this.resolutionNote, required this.w});

  static const _order = [
    RiderReportStatus.pending,
    RiderReportStatus.inReview,
    RiderReportStatus.resolved,
  ];

  @override
  Widget build(BuildContext context) {
    final isDismissed = status == RiderReportStatus.dismissed;
    final currentIndex = isDismissed ? 0 : _order.indexOf(status);

    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _order.length; i++)
            _TimelineStep(
              label: isDismissed && i == 0 ? 'Dismissed' : _order[i].label,
              isDone: i <= currentIndex,
              isLast: i == _order.length - 1,
              color:
                  isDismissed && i == 0 ? AppColors.textHint : _order[i].color,
              w: w,
            ),
          if (resolutionNote != null && resolutionNote!.isNotEmpty) ...[
            SizedBox(height: w * 0.03),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.035),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Text(
                resolutionNote!,
                style: TextStyle(
                    fontSize: w * 0.032,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isLast;
  final Color color;
  final double w;

  const _TimelineStep({
    required this.label,
    required this.isDone,
    required this.isLast,
    required this.color,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: w * 0.035,
              height: w * 0.035,
              decoration: BoxDecoration(
                color: isDone ? color : AppColors.divider,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: w * 0.08,
                color:
                    isDone ? color.withValues(alpha: 0.4) : AppColors.divider,
              ),
          ],
        ),
        SizedBox(width: w * 0.03),
        Padding(
          padding: EdgeInsets.only(top: w * 0.001),
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
