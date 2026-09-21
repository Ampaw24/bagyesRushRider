import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/app_toast.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_providers.dart';
import 'package:delivery_boy/features/rider/wallet/views/widgets/rider_withdrawal_request_sheet.dart';
import 'package:delivery_boy/features/rider/wallet/views/widgets/rider_withdrawal_tile.dart';

/// Withdrawal lifecycle in one place: balance summary, the Withdraw action
/// (gated on payout details being configured), and the full history from
/// `GET /rider/me/withdrawals` with cancel on pending rows.
class RiderWithdrawalsScreen extends ConsumerStatefulWidget {
  const RiderWithdrawalsScreen({super.key});

  @override
  ConsumerState<RiderWithdrawalsScreen> createState() =>
      _RiderWithdrawalsScreenState();
}

class _RiderWithdrawalsScreenState
    extends ConsumerState<RiderWithdrawalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeWalletProvider.notifier).load();
      // Defensive: this screen assumes the dashboard already warmed up the
      // profile provider, but don't assume it was always the entry point.
      if (ref.read(riderMeProfileProvider).status ==
          RiderMeProfileStatus.initial) {
        ref.read(riderMeProfileProvider.notifier).load();
      }
    });
  }

  void _onWithdrawTap() {
    // `payout` defaults to `RiderPayoutInfo(isConfigured: false)` until a
    // real `GET /rider/me` response says otherwise, so this fails closed —
    // there is no path to the amount sheet without a confirmed payout.
    final payout = ref.read(riderMeProfileProvider).profile?.payout;
    if (payout?.isConfigured != true) {
      context.push(AppRoutes.kycSection('payout'));
      return;
    }
    final wallet = ref.read(riderMeWalletProvider).wallet;
    final available = wallet?.availableBalance ?? wallet?.balance ?? 0;
    RiderWithdrawalRequestSheet.show(
      context,
      availableBalance: available,
      currency: wallet?.currency ?? 'GHS',
    );
  }

  void _onCancelTap(int withdrawalId) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'Cancel withdrawal?',
      subtitle: 'This pending withdrawal request will be cancelled.',
      confirmText: 'Cancel it',
      cancelText: 'Keep it',
      onConfirm: () async {
        final notifier = ref.read(riderMeWalletProvider.notifier);
        final success = await notifier.cancelWithdrawal(withdrawalId);
        if (!mounted) return;
        if (success) {
          AppToast.show(
            context,
            isSuccess: true,
            title: 'Withdrawal cancelled',
            subtitle: 'Your balance has been updated.',
          );
        } else {
          final message = ref.read(riderMeWalletProvider).actionMessage ??
              'Something went wrong.';
          AppToast.show(context,
              isSuccess: false, title: 'Could not cancel', subtitle: message);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    final state = ref.watch(riderMeWalletProvider);
    final notifier = ref.read(riderMeWalletProvider.notifier);
    final wallet = state.wallet;
    final currency = wallet?.currency ?? 'GHS';
    final available =
        (wallet?.availableBalance ?? wallet?.balance ?? 0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Withdrawals'),
        backgroundColor: AppColors.scaffold,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: notifier.load,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      w * 0.05, w * 0.04, w * 0.05, w * 0.03),
                  child: _BalanceSummary(
                    available: available,
                    currency: currency,
                    w: w,
                    h: h,
                    isLoading: state.status == RiderMeWalletStatus.loading,
                    onWithdraw: state.status == RiderMeWalletStatus.loaded
                        ? _onWithdrawTap
                        : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      w * 0.05, w * 0.02, w * 0.05, w * 0.015),
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.044,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              ...switch (state.withdrawalsStatus) {
                RiderMeWithdrawalsStatus.initial ||
                RiderMeWithdrawalsStatus.loading =>
                  [
                    const SliverToBoxAdapter(
                      child:
                          ShimmerListPlaceholder(itemCount: 4, itemHeight: 72),
                    ),
                  ],
                RiderMeWithdrawalsStatus.error => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _WithdrawalsErrorState(
                        w: w,
                        message: state.withdrawalsErrorMessage ??
                            'Something went wrong.',
                        onRetry: notifier.load,
                      ),
                    ),
                  ],
                RiderMeWithdrawalsStatus.loaded => state.withdrawals.isEmpty
                    ? [
                        SliverFillRemaining(
                            hasScrollBody: false,
                            child: _WithdrawalsEmptyState(w: w))
                      ]
                    : [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                              w * 0.05, 0, w * 0.05, w * 0.06),
                          sliver: SliverList.builder(
                            itemCount: state.withdrawals.length,
                            itemBuilder: (_, i) {
                              final withdrawal = state.withdrawals[i];
                              return AnimatedListItem(
                                index: i,
                                child: RiderWithdrawalTile(
                                  withdrawal: withdrawal,
                                  currency: currency,
                                  w: w,
                                  h: h,
                                  onCancel: withdrawal.isCancellable
                                      ? () => _onCancelTap(withdrawal.id)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  final double available;
  final String currency;
  final double w, h;
  final bool isLoading;
  final VoidCallback? onWithdraw;

  const _BalanceSummary({
    required this.available,
    required this.currency,
    required this.w,
    required this.h,
    required this.isLoading,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available to withdraw',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: h * 0.008),
          Text(
            '$currency ${available.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.075,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: h * 0.02),
          AppGradientButton(
            label: 'Withdraw',
            isLoading: isLoading,
            onPressed: onWithdraw,
          ),
        ],
      ),
    );
  }
}

class _WithdrawalsEmptyState extends StatelessWidget {
  const _WithdrawalsEmptyState({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.1, vertical: w * 0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(HugeIcons.strokeRoundedMoneySend01,
              size: w * 0.14, color: AppColors.textHint),
          SizedBox(height: w * 0.04),
          Text(
            'No withdrawals yet',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Your withdrawal requests and their status will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: w * 0.032,
                color: AppColors.textSecondary,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalsErrorState extends StatelessWidget {
  const _WithdrawalsErrorState(
      {required this.w, required this.message, required this.onRetry});

  final double w;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.1, vertical: w * 0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(HugeIcons.strokeRoundedAlertCircle,
              size: w * 0.13, color: AppColors.error),
          SizedBox(height: w * 0.04),
          Text(
            "Couldn't load withdrawals",
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: w * 0.031, color: AppColors.textSecondary),
          ),
          SizedBox(height: w * 0.05),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
