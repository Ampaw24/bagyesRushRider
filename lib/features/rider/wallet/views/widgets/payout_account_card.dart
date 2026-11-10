import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:gopady_rider/features/rider/profile/models/rider_me_profile_model.dart';

/// The payout account on file, masked as the API returns it.
class PayoutAccountCard extends StatelessWidget {
  const PayoutAccountCard({super.key, required this.payout});

  final RiderPayoutInfo payout;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final last4 = payout.last4;
    final accountName = payout.accountName;

    return Container(
      padding: EdgeInsets.all(m.gutter),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(m.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(payout: payout, metrics: m),
          Padding(
            padding: EdgeInsets.symmetric(vertical: m.gap),
            child: const Divider(height: 1, color: AppColors.divider),
          ),
          if (accountName != null)
            _DetailRow(label: 'Account name', value: accountName, metrics: m),
          if (last4 != null) ...[
            if (accountName != null) SizedBox(height: m.gap * 0.75),
            _DetailRow(
              label: payout.isMobileMoney
                  ? 'Mobile money number'
                  : 'Account number',
              value: '•••• $last4',
              metrics: m,
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.payout, required this.metrics});

  final RiderPayoutInfo payout;
  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Row(
      children: [
        Container(
          width: m.iconBadge,
          height: m.iconBadge,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            payout.isMobileMoney
                ? HugeIcons.strokeRoundedSmartPhone01
                : HugeIcons.strokeRoundedBank,
            size: m.iconBadge * 0.5,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: m.gutter * 0.75),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payout.providerLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: m.titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                payout.isMobileMoney ? 'Mobile money' : 'Bank account',
                style: TextStyle(
                  fontSize: m.captionSize,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.metrics,
  });

  final String label;
  final String value;
  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: m.bodySize,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: m.gutter * 0.5),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: m.bodySize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
