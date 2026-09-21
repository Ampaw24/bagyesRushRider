import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';

const _kTargetTypeOptions = [
  RiderReportTargetType.vendor,
  RiderReportTargetType.customer,
  RiderReportTargetType.orderIssue,
  RiderReportTargetType.general,
];

String targetTypeTitle(RiderReportTargetType type) => switch (type) {
      RiderReportTargetType.vendor => 'Vendor',
      RiderReportTargetType.customer => 'Customer',
      RiderReportTargetType.orderIssue => 'Order Issue',
      RiderReportTargetType.general => 'General',
    };

IconData targetTypeIcon(RiderReportTargetType type) => switch (type) {
      RiderReportTargetType.vendor => HugeIcons.strokeRoundedStore01,
      RiderReportTargetType.customer => HugeIcons.strokeRoundedUserBlock01,
      RiderReportTargetType.orderIssue => HugeIcons.strokeRoundedReceiptDollar,
      RiderReportTargetType.general => HugeIcons.strokeRoundedMessageQuestion,
    };

/// Step 1 — "What would you like to report?"
class RiderReportTargetTypeStep extends StatelessWidget {
  final ValueChanged<RiderReportTargetType> onSelect;

  const RiderReportTargetTypeStep({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
      children: [
        Text(
          'What would you like to report?',
          style: TextStyle(
            fontSize: w * 0.052,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          "We'll ask a few quick questions and route this to the right team.",
          style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.06),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _kTargetTypeOptions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: w * 0.035,
            crossAxisSpacing: w * 0.035,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, i) {
            final type = _kTargetTypeOptions[i];
            return _TypeCard(
              title: targetTypeTitle(type),
              icon: targetTypeIcon(type),
              w: w,
              onTap: () {
                HapticFeedback.lightImpact();
                onSelect(type);
              },
            );
          },
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double w;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.icon,
    required this.w,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.028),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: HugeIcon(
                icon: icon,
                color: AppColors.primary,
                size: w * 0.065,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
