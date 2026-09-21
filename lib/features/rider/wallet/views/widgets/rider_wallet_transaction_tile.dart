import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';

/// A single ledger row, shared by the wallet overview's "recent" preview and
/// the full transactions list. Maps [RiderMeWalletTransactionModel.type] to
/// an icon/label/color, with a neutral fallback for any `type` outside the
/// documented sets (rider-wallet-apis.md #7 — transaction types are only
/// partly documented) rather than guessing credit or debit.
class RiderWalletTransactionTile extends StatelessWidget {
  final RiderMeWalletTransactionModel transaction;
  final String currency;
  final double w;
  final double h;

  const RiderWalletTransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    required this.w,
    required this.h,
  });

  static const _typeLabels = {
    'credit': 'Delivery earning',
    'admin_credit': 'Wallet credit',
    'bonus': 'Bonus',
    'compensation': 'Compensation',
    'debit': 'Withdrawal',
    'admin_debit': 'Wallet debit',
    'adjustment': 'Adjustment',
  };

  String _humanizeType(String type) => type
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  String get _title {
    if (transaction.description != null &&
        transaction.description!.trim().isNotEmpty) {
      return transaction.description!;
    }
    final type = transaction.type;
    if (type == null) return 'Transaction';
    return _typeLabels[type] ?? _humanizeType(type);
  }

  String? get _formattedDate {
    final raw = transaction.createdAt;
    if (raw == null) return null;
    final date = DateTime.tryParse(raw);
    if (date == null) return null;
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final (Color dot, IconData icon) = switch (transaction.direction) {
      RiderMeWalletTxDirection.credit => transaction.type == 'bonus'
          ? (AppColors.accent, HugeIcons.strokeRoundedGift)
          : (AppColors.success, HugeIcons.strokeRoundedDeliveryBox01),
      RiderMeWalletTxDirection.debit => (
          AppColors.warning,
          HugeIcons.strokeRoundedPayment01
        ),
      RiderMeWalletTxDirection.unknown => (
          AppColors.textSecondary,
          HugeIcons.strokeRoundedInformationCircle
        ),
    };

    final amount = transaction.amount;
    final amountText = amount == null
        ? '—'
        : switch (transaction.direction) {
            RiderMeWalletTxDirection.credit =>
              '+$currency ${amount.abs().toStringAsFixed(2)}',
            RiderMeWalletTxDirection.debit =>
              '-$currency ${amount.abs().toStringAsFixed(2)}',
            RiderMeWalletTxDirection.unknown =>
              '$currency ${amount.toStringAsFixed(2)}',
          };
    final amountColor = switch (transaction.direction) {
      RiderMeWalletTxDirection.credit => AppColors.success,
      RiderMeWalletTxDirection.debit => AppColors.warning,
      RiderMeWalletTxDirection.unknown => AppColors.textPrimary,
    };

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
              color: dot.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.025),
            ),
            child: Icon(icon, color: dot, size: w * 0.046),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          Text(
            amountText,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
