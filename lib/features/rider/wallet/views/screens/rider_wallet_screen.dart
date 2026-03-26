import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_wallet_providers.dart';

class RiderWalletScreen extends ConsumerStatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  ConsumerState<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends ConsumerState<RiderWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderWalletProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderWalletProvider);
    final total = double.tryParse(state.wallet?.total ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(riderWalletProvider.notifier).load(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Gradient header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFFCA445D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Earnings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Animated counter
                    TweenAnimationBuilder<double>(
                      key: ValueKey(total),
                      tween: Tween(begin: 0, end: total),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (_, value, __) => Text(
                        'GHS ${value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Roboto',
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stat cards ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    _StatCard(
                        label: 'Today',
                        amount: state.todayTotal,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    _StatCard(
                        label: 'This Week',
                        amount: state.weekTotal,
                        color: Colors.blue),
                    const SizedBox(width: 10),
                    _StatCard(
                        label: 'This Month',
                        amount: state.monthTotal,
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),

            // ── Period filter chips ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EarningsPeriod.values.map((p) {
                      final isSelected = state.period == p;
                      final label = switch (p) {
                        EarningsPeriod.all => 'All',
                        EarningsPeriod.today => 'Today',
                        EarningsPeriod.thisWeek => 'This Week',
                        EarningsPeriod.thisMonth => 'This Month',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => ref
                              .read(riderWalletProvider.notifier)
                              .setPeriod(p),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ── Earnings list ────────────────────────────────────────────────
            if (state.status == WalletStatus.loading)
              const SliverToBoxAdapter(
                child: ShimmerListPlaceholder(itemCount: 5, itemHeight: 72),
              )
            else if (state.filteredEarnings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No earnings for this period',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.builder(
                  itemCount: state.filteredEarnings.length,
                  itemBuilder: (_, i) {
                    final item = state.filteredEarnings[i];
                    return AnimatedListItem(
                      index: i,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fastfood_outlined,
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(
                            item.description ?? 'Delivery',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: item.formattedDate.isNotEmpty
                              ? Text(
                                  item.formattedDate,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                )
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'GHS ${item.amount?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                'Earning',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatCard(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GHS ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
