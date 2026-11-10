import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/constant/app_tokens.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/features/rider/profile/providers/rider_me_profile_providers.dart';

/// "Paid to MTN MoMo •••• 1234 · Change" — where a withdrawal will land,
/// shown before the rider withdraws. Hidden until a payout account is on
/// file (the Withdraw action handles that case).
class PayoutDestinationRow extends ConsumerWidget {
  const PayoutDestinationRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payout =
        ref.watch(riderMeProfileProvider.select((s) => s.profile?.payout));
    if (payout == null || !payout.isConfigured) return const SizedBox.shrink();

    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.03);

    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.push(AppRoutes.payout),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.03,
          ),
          child: Row(
            children: [
              Icon(
                payout.isMobileMoney
                    ? HugeIcons.strokeRoundedSmartPhone01
                    : HugeIcons.strokeRoundedBank,
                size: w * 0.05,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Paid to '),
                    TextSpan(
                      text: payout.destinationLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: w * 0.034,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: w * 0.02),
              Text(
                'Change',
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: w * 0.034,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
