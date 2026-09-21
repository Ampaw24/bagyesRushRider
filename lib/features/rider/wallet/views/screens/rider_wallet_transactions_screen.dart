import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_providers.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_transactions_providers.dart';
import 'package:delivery_boy/features/rider/wallet/views/widgets/rider_wallet_transaction_tile.dart';

enum WalletTxPeriod { all, today, thisWeek, thisMonth }

/// Full ledger — `GET /rider/me/wallet/transactions`. No dummy fallback at
/// any status; loading/empty/error each render their real state.
class RiderWalletTransactionsScreen extends ConsumerStatefulWidget {
  const RiderWalletTransactionsScreen({super.key});

  @override
  ConsumerState<RiderWalletTransactionsScreen> createState() =>
      _RiderWalletTransactionsScreenState();
}

class _RiderWalletTransactionsScreenState
    extends ConsumerState<RiderWalletTransactionsScreen> {
  WalletTxPeriod _period = WalletTxPeriod.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeWalletTransactionsProvider.notifier).load();
    });
  }

  DateTime? _txDate(RiderMeWalletTransactionModel tx) =>
      tx.createdAt == null ? null : DateTime.tryParse(tx.createdAt!);

  bool _matchesPeriod(DateTime? d, WalletTxPeriod p) {
    if (d == null) return false;
    final now = DateTime.now();
    return switch (p) {
      WalletTxPeriod.today =>
        d.year == now.year && d.month == now.month && d.day == now.day,
      WalletTxPeriod.thisWeek => now.difference(d).inDays < 7,
      WalletTxPeriod.thisMonth => d.year == now.year && d.month == now.month,
      WalletTxPeriod.all => true,
    };
  }

  List<RiderMeWalletTransactionModel> _filtered(
      List<RiderMeWalletTransactionModel> txs) {
    if (_period == WalletTxPeriod.all) return txs;
    return txs.where((t) => _matchesPeriod(_txDate(t), _period)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    final state = ref.watch(riderMeWalletTransactionsProvider);
    final notifier = ref.read(riderMeWalletTransactionsProvider.notifier);
    final currency =
        ref.watch(riderMeWalletProvider.select((s) => s.wallet?.currency)) ??
            'GHS';
    final filtered = _filtered(state.transactions);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.scaffold,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.02),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _PeriodFilter(
                  period: _period,
                  onSelect: (p) => setState(() => _period = p),
                ),
              ),
            ),
            Expanded(
              child: switch (state.status) {
                RiderMeWalletTransactionsStatus.initial ||
                RiderMeWalletTransactionsStatus.loading =>
                  const ShimmerListPlaceholder(itemCount: 8, itemHeight: 68),
                RiderMeWalletTransactionsStatus.error => _ErrorState(
                    w: w,
                    message: state.errorMessage ?? 'Something went wrong.',
                    onRetry: notifier.load,
                  ),
                RiderMeWalletTransactionsStatus.loaded => filtered.isEmpty
                    ? _EmptyState(w: w)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: notifier.load,
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                              w * 0.05, 0, w * 0.05, w * 0.06),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => AnimatedListItem(
                            index: i,
                            child: RiderWalletTransactionTile(
                              transaction: filtered[i],
                              currency: currency,
                              w: w,
                              h: h,
                            ),
                          ),
                        ),
                      ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  final WalletTxPeriod period;
  final void Function(WalletTxPeriod) onSelect;
  const _PeriodFilter({required this.period, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Wrap(
      spacing: w * 0.02,
      children: WalletTxPeriod.values.map((p) {
        final selected = period == p;
        final label = switch (p) {
          WalletTxPeriod.all => 'All',
          WalletTxPeriod.today => 'Today',
          WalletTxPeriod.thisWeek => 'Week',
          WalletTxPeriod.thisMonth => 'Month',
        };
        return GestureDetector(
          onTap: () => onSelect(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.015),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.031,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HugeIcons.strokeRoundedWallet01,
                size: w * 0.16, color: AppColors.textHint),
            SizedBox(height: w * 0.04),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              'Your earnings and withdrawals will show up here once you start delivering.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: w * 0.033,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState(
      {required this.w, required this.message, required this.onRetry});

  final double w;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HugeIcons.strokeRoundedAlertCircle,
                size: w * 0.14, color: AppColors.error),
            SizedBox(height: w * 0.04),
            Text(
              "Couldn't load your transactions",
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
