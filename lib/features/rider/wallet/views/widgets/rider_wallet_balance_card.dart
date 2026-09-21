import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// Top balance card for the wallet overview — real balance, real pending
/// amount and real currency, all sourced from `GET /rider/me/wallet`.
class RiderWalletBalanceCard extends StatelessWidget {
  final double total;
  final double today;
  final double pending;
  final String currency;
  final double topPad;
  final double w;
  final double h;

  const RiderWalletBalanceCard({
    super.key,
    required this.total,
    required this.today,
    required this.pending,
    required this.currency,
    required this.topPad,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(w * 0.04, topPad + h * 0.012, w * 0.04, 0),
      padding: EdgeInsets.all(w * 0.055),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Earnings',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.034,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03, vertical: h * 0.005),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(HugeIcons.strokeRoundedWallet01,
                        color: Colors.white, size: w * 0.038),
                    SizedBox(width: w * 0.015),
                    Text(
                      'Wallet',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: w * 0.03,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.012),
          TweenAnimationBuilder<double>(
            key: ValueKey(total),
            tween: Tween(begin: 0, end: total),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text(
              '$currency ${v.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.095,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
                letterSpacing: -1,
              ),
            ),
          ),
          SizedBox(height: h * 0.016),
          Container(height: 0.8, color: Colors.white.withValues(alpha: 0.2)),
          SizedBox(height: h * 0.016),
          Row(
            children: [
              Expanded(
                child: _BalanceFooterItem(
                  label: 'Today',
                  value: '$currency ${today.toStringAsFixed(2)}',
                  w: w,
                  h: h,
                ),
              ),
              Container(
                  width: 0.8,
                  height: h * 0.04,
                  color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _BalanceFooterItem(
                  label: 'Pending',
                  value: '$currency ${pending.toStringAsFixed(2)}',
                  w: w,
                  h: h,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceFooterItem extends StatelessWidget {
  final String label, value;
  final double w, h;
  final CrossAxisAlignment align;
  const _BalanceFooterItem({
    required this.label,
    required this.value,
    required this.w,
    required this.h,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: w * 0.03,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        SizedBox(height: h * 0.003),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
