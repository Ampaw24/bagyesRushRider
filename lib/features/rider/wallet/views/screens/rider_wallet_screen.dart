import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_providers.dart';
import 'package:hugeicons/hugeicons.dart';

enum WalletPeriod { all, today, thisWeek, thisMonth }

// ─── Dummy data ───────────────────────────────────────────────────────────────

const _weeklyBars = [42.5, 65.0, 38.0, 80.0, 55.0, 92.0, 47.0];
const _weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _todayDummy = 92.0;
const _weekDummy = 419.5;
const _monthDummy = 1248.75;
const _totalDummy = 4830.20;
const _weekGoal = 500.0;
const _streakDays = 5;
const _deliveriesThisMonth = 38;

final _txDummy = [
  _Tx('Delivery #4821', 'Accra Central', 18.50, '2:45 PM', true),
  _Tx('Delivery #4820', 'Osu', 12.00, '1:10 PM', true),
  _Tx('Delivery #4819', 'Labadi', 15.75, '11:30 AM', true),
  _Tx('Withdrawal', 'MTN Mobile Money', -200.00, 'Yesterday', false),
  _Tx('Delivery #4818', 'Airport Res.', 22.00, 'Yesterday', true),
  _Tx('Bonus', 'Weekend surge reward', 25.00, 'Sat, 17 May', true),
  _Tx('Delivery #4815', 'Dzorwulu', 9.50, 'Sat, 17 May', true),
  _Tx('Withdrawal', 'Vodafone Cash', -150.00, 'Fri, 16 May', false),
];

class _Tx {
  final String title, place;
  final double amount;
  final String time;
  final bool credit;
  const _Tx(this.title, this.place, this.amount, this.time, this.credit);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RiderWalletScreen extends ConsumerStatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  ConsumerState<RiderWalletScreen> createState() => _State();
}

class _State extends ConsumerState<RiderWalletScreen> {
  WalletPeriod _period = WalletPeriod.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeWalletProvider.notifier).load();
    });
  }

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
    return txs.where((t) => t.isCredit).fold(0.0, (sum, t) {
      return _matchesPeriod(_txDate(t), p)
          ? sum + (t.amount?.toDouble() ?? 0)
          : sum;
    });
  }

  List<RiderMeWalletTransactionModel> _filtered(
      List<RiderMeWalletTransactionModel> txs) {
    if (_period == WalletPeriod.all) return txs;
    return txs.where((t) => _matchesPeriod(_txDate(t), _period)).toList();
  }

  String _formatTxDate(DateTime? d) =>
      d == null ? '' : DateFormat('MMM d, h:mm a').format(d);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderMeWalletProvider);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final top = MediaQuery.of(context).padding.top;

    final isLoaded = state.status == RiderMeWalletStatus.loaded;
    final today = isLoaded ? _subtotal(state.transactions, WalletPeriod.today) : _todayDummy;
    final week = isLoaded ? _subtotal(state.transactions, WalletPeriod.thisWeek) : _weekDummy;
    final month = isLoaded ? _subtotal(state.transactions, WalletPeriod.thisMonth) : _monthDummy;
    final total = isLoaded ? (state.wallet?.balance.toDouble() ?? 0) : _totalDummy;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(riderMeWalletProvider.notifier).load(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Top balance card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _BalanceCard(
                total: total,
                today: today,
                topPad: top,
                w: w,
                h: h,
              ),
            ),

            // ── Stats row ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: h * 0.014),
                child: Row(
                  children: [
                    _StatPill(label: 'Today', amount: today, w: w, h: h),
                    SizedBox(width: w * 0.025),
                    _StatPill(
                        label: 'This Week', amount: week, w: w, h: h),
                    SizedBox(width: w * 0.025),
                    _StatPill(
                        label: 'This Month', amount: month, w: w, h: h),
                  ],
                ),
              ),
            ),

            // ── Weekly chart ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: _WeeklyCard(w: w, h: h),
              ),
            ),

            SizedBox(height: h * 0.014).asSliver,

            // ── Info tiles row ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: Row(
                  children: [
                    _InfoTile(
                      icon: HugeIcons.strokeRoundedDeliveryBox01,
                      value: '$_deliveriesThisMonth',
                      label: 'Deliveries',
                      w: w,
                      h: h,
                    ),
                    SizedBox(width: w * 0.025),
                    _InfoTile(
                      icon: HugeIcons.strokeRoundedFire,
                      value: '${_streakDays}d',
                      label: 'Streak',
                      w: w,
                      h: h,
                    ),
                    SizedBox(width: w * 0.025),
                    _InfoTile(
                      icon: HugeIcons.strokeRoundedTarget01,
                      value:
                          '${((week / _weekGoal) * 100).clamp(0, 100).toInt()}%',
                      label: 'Goal',
                      w: w,
                      h: h,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: h * 0.025).asSliver,

            // ── Transactions heading + filter ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: w * 0.044,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    _PeriodFilter(
                      period: _period,
                      onSelect: (p) => setState(() => _period = p),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: h * 0.01).asSliver,

            // ── List ─────────────────────────────────────────────────────────
            if (state.status == RiderMeWalletStatus.loading)
              const SliverToBoxAdapter(
                child: ShimmerListPlaceholder(
                    itemCount: 5, itemHeight: 68),
              )
            else if (isLoaded && _filtered(state.transactions).isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.04, 0, w * 0.04, h * 0.06),
                sliver: SliverList.builder(
                  itemCount: _filtered(state.transactions).length,
                  itemBuilder: (_, i) {
                    final item = _filtered(state.transactions)[i];
                    return AnimatedListItem(
                      index: i,
                      child: _TxTile(
                        title: item.description ?? 'Delivery',
                        sub: _formatTxDate(_txDate(item)),
                        amount: item.amount?.toDouble() ?? 0,
                        credit: item.isCredit,
                        w: w,
                        h: h,
                      ),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.04, 0, w * 0.04, h * 0.06),
                sliver: SliverList.builder(
                  itemCount: _txDummy.length,
                  itemBuilder: (_, i) {
                    final tx = _txDummy[i];
                    return AnimatedListItem(
                      index: i,
                      child: _TxTile(
                        title: tx.title,
                        sub: '${tx.place} · ${tx.time}',
                        amount: tx.amount,
                        credit: tx.credit,
                        w: w,
                        h: h,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double total, today, topPad, w, h;
  const _BalanceCard({
    required this.total,
    required this.today,
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
              'GHS ${v.toStringAsFixed(2)}',
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
                  value: 'GHS ${today.toStringAsFixed(2)}',
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
                  value: 'GHS 0.00',
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

// ─── Stat Pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final double amount, w, h;
  const _StatPill(
      {required this.label,
      required this.amount,
      required this.w,
      required this.h});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.03, vertical: h * 0.014),
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
              'GHS ${amount.toStringAsFixed(0)}',
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

// ─── Weekly Chart Card ────────────────────────────────────────────────────────

class _WeeklyCard extends StatelessWidget {
  final double w, h;
  const _WeeklyCard({required this.w, required this.h});

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
                'GHS ${_weekDummy.toStringAsFixed(2)}',
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
            child: _SimpleBarChart(w: w, h: h),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final double w, h;
  const _SimpleBarChart({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final maxVal = _weeklyBars.reduce(math.max);

    return LayoutBuilder(builder: (_, c) {
      final gap = w * 0.02;
      final barW = (c.maxWidth - gap * (_weeklyBars.length - 1)) /
          _weeklyBars.length;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_weeklyBars.length, (i) {
          final pct = _weeklyBars[i] / maxVal;
          final isMax = _weeklyBars[i] == maxVal;
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
                      height: barH,
                      decoration: BoxDecoration(
                        color: isMax
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.18),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ),
                    SizedBox(height: h * 0.006),
                    Text(
                      _weekLabels[i],
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: w * 0.028,
                        color: isMax
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isMax ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _weeklyBars.length - 1) SizedBox(width: gap),
            ],
          );
        }),
      );
    });
  }
}

// ─── Info Tile ────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final double w, h;
  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.03, vertical: h * 0.016),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: w * 0.055),
            SizedBox(height: h * 0.007),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.042,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.028,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period Filter ────────────────────────────────────────────────────────────

class _PeriodFilter extends StatelessWidget {
  final WalletPeriod period;
  final void Function(WalletPeriod) onSelect;
  const _PeriodFilter({required this.period, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Row(
      children: WalletPeriod.values.map((p) {
        final selected = period == p;
        final label = switch (p) {
          WalletPeriod.all => 'All',
          WalletPeriod.today => 'Today',
          WalletPeriod.thisWeek => 'Week',
          WalletPeriod.thisMonth => 'Month',
        };
        return GestureDetector(
          onTap: () => onSelect(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(left: w * 0.018),
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.028, vertical: h * 0.005),
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
                fontSize: w * 0.03,
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

// ─── Transaction Tile ─────────────────────────────────────────────────────────

class _TxTile extends StatelessWidget {
  final String title, sub;
  final double amount, w, h;
  final bool credit;
  const _TxTile({
    required this.title,
    required this.sub,
    required this.amount,
    required this.credit,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    final isWithdraw = title.toLowerCase().contains('withdraw');
    final isBonus = title.toLowerCase().contains('bonus');

    final Color dot = isWithdraw
        ? AppColors.warning
        : isBonus
            ? AppColors.accent
            : AppColors.success;

    final IconData ico = isWithdraw
        ? HugeIcons.strokeRoundedPayment01
        : isBonus
            ? HugeIcons.strokeRoundedGift
            : HugeIcons.strokeRoundedDeliveryBox01;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.01),
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.04, vertical: h * 0.014),
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
            child: Icon(ico, color: dot, size: w * 0.046),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: h * 0.002),
                Text(
                  sub,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.03,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          Text(
            credit
                ? '+GHS ${amount.abs().toStringAsFixed(2)}'
                : '-GHS ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: credit ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget get asSliver => SliverToBoxAdapter(child: this);
}
