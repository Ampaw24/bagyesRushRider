import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/status_badge.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';

/// A single withdrawal request row — status pill colored per the 6-value
/// enum documented in the admin `withdrawals` folder (`pending | approved |
/// paid | rejected | cancelled | reversed`), plus a Cancel action that only
/// appears while [RiderMeWithdrawalModel.isCancellable] is true.
class RiderWithdrawalTile extends StatelessWidget {
  final RiderMeWithdrawalModel withdrawal;
  final String currency;
  final double w;
  final double h;
  final VoidCallback? onCancel;

  const RiderWithdrawalTile({
    super.key,
    required this.withdrawal,
    required this.currency,
    required this.w,
    required this.h,
    this.onCancel,
  });

  (Color, String) get _statusStyle => switch (withdrawal.status) {
        'pending' => (AppColors.warning, 'Pending'),
        'approved' => (AppColors.info, 'Approved'),
        'paid' => (AppColors.success, 'Paid'),
        'rejected' => (AppColors.error, 'Rejected'),
        'cancelled' => (AppColors.textSecondary, 'Cancelled'),
        'reversed' => (AppColors.error, 'Reversed'),
        _ => (AppColors.textSecondary, withdrawal.status ?? 'Unknown'),
      };

  String? get _formattedDate {
    final raw = withdrawal.createdAt;
    if (raw == null) return null;
    final date = DateTime.tryParse(raw);
    if (date == null) return null;
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusStyle;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.01),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.014),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.025),
            ),
            child: Icon(HugeIcons.strokeRoundedMoneySend01,
                color: statusColor, size: w * 0.046),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currency ${withdrawal.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_formattedDate != null) ...[
                  SizedBox(height: h * 0.002),
                  Text(
                    _formattedDate!,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: statusLabel, color: statusColor),
              if (withdrawal.isCancellable && onCancel != null) ...[
                SizedBox(height: h * 0.008),
                GestureDetector(
                  onTap: onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.03,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
