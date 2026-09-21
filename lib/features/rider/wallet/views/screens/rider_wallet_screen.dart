import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_providers.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_transactions_providers.dart';
import 'package:delivery_boy/features/rider/wallet/views/widgets/rider_wallet_balance_card.dart';
import 'package:delivery_boy/features/rider/wallet/views/widgets/rider_wallet_transaction_tile.dart';

enum WalletPeriod { all, today, thisWeek, thisMonth }

/// Wallet overview tab — real balance, real stats, a real weekly chart
/// bucketed from already-fetched transactions, and entry points to the
/// dedicated Transactions and Withdrawals pages. No dummy fallback at any
/// status.
class RiderWalletScreen extends ConsumerStatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  ConsumerState<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends ConsumerState<RiderWalletScreen> {
  static const _recentPreviewCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeWalletProvider.notifier).load();
      ref.read(riderMeWalletTransactionsProvider.notifier).load();
    });
  }

  Future<void> _refresh() => Future.wait([
        ref.read(riderMeWalletProvider.notifier).load(),
        ref.read(riderMeWalletTransactionsProvider.notifier).load(),
      ]);

  DateTime? _txDate(RiderMeWalletTransactionModel tx) =>
      tx.createdAt == null ? null : DateTime.tryParse(tx.createdAt!);

  bool _matchesPeriod(DateTime? d, WalletPeriod p) {
    if (d == null) return false;
    final now = DateTime.now();
    return switch (p) {
      WalletPeriod.today =>
        d.year == now.year && d.month == now.month && d.day == now.day,
      WalletPeriod.thisWeek => now.difference(d).inDays < 7,
      WalletPeriod.thisMonth => d.year == now.year && d.month == now.month,
      WalletPeriod.all => true,
    };
  }

  double _subtotal(List<RiderMeWalletTransactionModel> txs, WalletPeriod p) {
    return txs
        .where((t) => t.direction == RiderMeWalletTxDirection.credit)
        .fold(0.0, (sum, t) {
      return _matchesPeriod(_txDate(t), p)
          ? sum + (t.amount?.toDouble() ?? 0)
          : sum;
    });
  }

  /// Buckets real credit transactions from the last 7 days by weekday.
  /// Legitimate reuse of the already-fetched full list (no per-day
  /// breakdown endpoint exists to fabricate this from otherwise).
  List<double> _weeklyBuckets(List<RiderMeWalletTransactionModel> txs) {
    final now = DateTime.now();
    final buckets = List<double>.filled(7, 0);
    for (final t in txs) {
      if (t.direction != RiderMeWalletTxDirection.credit) continue;
      final d = _txDate(t);
      if (d == null) continue;
      final daysAgo = now.difference(d).inDays;
      if (daysAgo < 0 || daysAgo >= 7) continue;
      buckets[d.weekday - 1] += t.amount?.toDouble() ?? 0;
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final top = MediaQuery.paddingOf(context).top;

    final walletState = ref.watch(riderMeWalletProvider);
    final txState = ref.watch(riderMeWalletTransactionsProvider);

    final wallet = walletState.wallet;
    final currency = wallet?.currency ?? 'GHS';
    final transactions = txState.transactions;

    final today = _subtotal(transactions, WalletPeriod.today);
    final week = _subtotal(transactions, WalletPeriod.thisWeek);
    final month = _subtotal(transactions, WalletPeriod.thisMonth);
    final total = (wallet?.balance ?? 0).toDouble();
    final pending = (wallet?.pendingBalance ?? 0).toDouble();
    final recentTx = transactions.take(_recentPreviewCount).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: RiderWalletBalanceCard(
                total: total,
                today: today,
                pending: pending,
                currency: currency,
                topPad: top,
                w: w,
                h: h,
              ),
            ),
            if (walletState.status == RiderMeWalletStatus.error)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(w * 0.04, h * 0.012, w * 0.04, 0),
                  child: _InlineErrorBanner(
                    message: walletState.errorMessage ??
                        "Couldn't load your balance.",
                    onRetry: () =>
                        ref.read(riderMeWalletProvider.notifier).load(),
                    w: w,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: h * 0.014),
                child: Row(
                  children: [
                    _StatPill(
                        label: 'Today',
                        amount: today,
                        currency: currency,
                        w: w,
                        h: h),
                    SizedBox(width: w * 0.025),
                    _StatPill(
                        label: 'This Week',
                        amount: week,
                        currency: currency,
                        w: w,
                        h: h),
                    SizedBox(width: w * 0.025),
                    _StatPill(
                        label: 'This Month',
                        amount: month,
                        currency: currency,
                        w: w,
                        h: h),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: _WeeklyCard(
                  buckets: _weeklyBuckets(transactions),
                  weekTotal: week,
                  currency: currency,
                  w: w,
                  h: h,
                ),
              ),
            ),
            SizedBox(height: h * 0.02).asSliver,
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: Row(
                  children: [
                    Expanded(
                      child: _WalletActionButton(
                        icon: HugeIcons.strokeRoundedMoneySend01,
                        label: 'Withdraw',
                        w: w,
                        h: h,
                        onTap: () => context.push(AppRoutes.walletWithdrawals),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: _WalletActionButton(
                        icon: HugeIcons.strokeRoundedListView,
                        label: 'Transactions',
                        w: w,
                        h: h,
                        onTap: () => context.push(AppRoutes.walletTransactions),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h * 0.025).asSliver,
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: w * 0.044,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.walletTransactions),
                      child: Text(
                        'View all',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h * 0.01).asSliver,
            if (txState.status == RiderMeWalletTransactionsStatus.loading ||
                txState.status == RiderMeWalletTransactionsStatus.initial)
              const SliverToBoxAdapter(
                child: ShimmerListPlaceholder(itemCount: 3, itemHeight: 68),
              )
            else if (txState.status == RiderMeWalletTransactionsStatus.error)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: _InlineErrorBanner(
                    message: txState.errorMessage ??
                        "Couldn't load your transactions.",
                    onRetry: () => ref
                        .read(riderMeWalletTransactionsProvider.notifier)
                        .load(),
                    w: w,
                  ),
                ),
              )
            else if (recentTx.isEmpty)
              SliverToBoxAdapter(child: _RecentEmptyState(w: w, h: h))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, h * 0.06),
                sliver: SliverList.builder(
                  itemCount: recentTx.length,
                  itemBuilder: (_, i) => AnimatedListItem(
                    index: i,
                    child: RiderWalletTransactionTile(
                      transaction: recentTx[i],
                      currency: currency,
                      w: w,
                      h: h,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Pill ──────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final double amount, w, h;
  final String currency;
  const _StatPill({
    required this.label,
    required this.amount,
    required this.currency,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: w * 0.03, vertical: h * 0.014),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.028,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: h * 0.004),
            Text(
              '$currency ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.038,
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

// ─── Weekly Chart Card ──────────────────────────────────────────────────────

const _weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _WeeklyCard extends StatelessWidget {
  final List<double> buckets;
  final double weekTotal, w, h;
  final String currency;
  const _WeeklyCard({
    required this.buckets,
    required this.weekTotal,
    required this.currency,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$currency ${weekTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          SizedBox(
            height: h * 0.14,
            child: _SimpleBarChart(buckets: buckets, w: w, h: h),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<double> buckets;
  final double w, h;
  const _SimpleBarChart(
      {required this.buckets, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold(0.0, math.max);

    return LayoutBuilder(builder: (_, c) {
      final gap = w * 0.02;
      final barW = (c.maxWidth - gap * (buckets.length - 1)) / buckets.length;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(buckets.length, (i) {
          final pct = maxVal > 0 ? buckets[i] / maxVal : 0.0;
          final isMax = maxVal > 0 && buckets[i] == maxVal;
          final barH = (c.maxHeight - h * 0.03) * pct;

          return Row(
            children: [
              SizedBox(
                width: barW,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300 + i * 60),
                      curve: Curves.easeOut,
                      width: barW,
                      height: barH < 2 ? 2 : barH,
                      decoration: BoxDecoration(
                        color: isMax
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                      ),
                    ),
                    SizedBox(height: h * 0.006),
                    Text(
                      _weekLabels[i],
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: w * 0.028,
                        color:
                            isMax ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isMax ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < buckets.length - 1) SizedBox(width: gap),
            ],
          );
        }),
      );
    });
  }
}

// ─── Action Buttons ─────────────────────────────────────────────────────────

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double w, h;
  final VoidCallback onTap;
  const _WalletActionButton({
    required this.icon,
    required this.label,
    required this.w,
    required this.h,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: h * 0.016),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: w * 0.06),
            SizedBox(height: h * 0.006),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.033,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inline error banner (wallet/recent-transactions section failures) ──────

class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final double w;
  const _InlineErrorBanner(
      {required this.message, required this.onRetry, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(HugeIcons.strokeRoundedAlertCircle,
              color: AppColors.error, size: w * 0.05),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.031,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.031,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  final double w, h;
  const _RecentEmptyState({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.03),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: h * 0.03),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(HugeIcons.strokeRoundedWallet01,
                size: w * 0.1, color: AppColors.textHint),
            SizedBox(height: h * 0.012),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  Widget get asSliver => SliverToBoxAdapter(child: this);
}
