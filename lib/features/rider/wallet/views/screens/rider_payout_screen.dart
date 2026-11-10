import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/core/widgets/app_status_animation.dart';
import 'package:gopady_rider/features/rider/kyc/models/kyc_section.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_profile_gate.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:gopady_rider/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:gopady_rider/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:gopady_rider/features/rider/wallet/views/widgets/payout_account_card.dart';

/// Where withdrawals are paid, from `/rider/me`'s `payout` object, with the
/// way in to change it. The account itself is edited (password-confirmed)
/// on [AppRoutes.payoutEdit].
class RiderPayoutScreen extends StatelessWidget {
  const RiderPayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KycProfileGate(
      title: KycSection.payout.title,
      builder: (context, profile) => _PayoutView(payout: profile.payout),
    );
  }
}

class _PayoutView extends ConsumerWidget {
  const _PayoutView({required this.payout});

  final RiderPayoutInfo payout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = KycMetrics.of(context);
    final configured = payout.isConfigured;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(KycSection.payout.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: ref.read(riderMeProfileProvider.notifier).load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: m.gutter,
                    vertical: m.gap,
                  ),
                  children: [
                    KycContentWidth(
                      child: configured
                          ? _ConfiguredBody(payout: payout, metrics: m)
                          : _EmptyBody(metrics: m),
                    ),
                  ],
                ),
              ),
            ),
            KycActionBar(
              label:
                  configured ? 'Change payout account' : 'Add payout account',
              onPressed: () => context.push(AppRoutes.payoutEdit),
              isBusy: false,
              metrics: m,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfiguredBody extends StatelessWidget {
  const _ConfiguredBody({required this.payout, required this.metrics});

  final RiderPayoutInfo payout;
  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KycSubheading('Withdrawals are paid to'),
        SizedBox(height: m.gap * 0.5),
        PayoutAccountCard(payout: payout),
        SizedBox(height: m.gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              HugeIcons.strokeRoundedSecurityLock,
              size: m.iconBadge * 0.4,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: m.gutter * 0.5),
            Expanded(
              child: Text(
                'Only the last 4 digits are shown. Changing this account '
                'asks for your password.',
                style: TextStyle(
                  fontSize: m.captionSize,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.metrics});

  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: m.gap * 2),
      child: Column(
        children: [
          const AppStatusAnimation(AppStatus.info,
              sizeFactor: 0.3, maxSize: 160),
          SizedBox(height: m.gap),
          Text(
            'No payout account yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: m.titleSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: m.gap * 0.5),
          Text(
            'Add a mobile money or bank account so you can withdraw your '
            'earnings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: m.bodySize,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
