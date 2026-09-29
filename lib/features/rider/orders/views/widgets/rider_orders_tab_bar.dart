import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';

/// Segmented Active / New / History switcher for the Orders page, with live
/// counts so the rider sees waiting work without opening each tab. Must sit
/// under a [DefaultTabController].
class RiderOrdersTabBar extends ConsumerWidget {
  const RiderOrdersTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final activeCount = ref.watch(
      riderMeOrdersProvider.select((s) => s.orders.length),
    );
    final offerCount = ref.watch(
      riderMeOffersProvider.select((s) => s.offers.length),
    );
    final radius = w * 0.028;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.01, w * 0.04, w * 0.03),
      child: Container(
        padding: EdgeInsets.all(w * 0.01),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: TabBar(
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius * 0.8),
            border: Border.all(color: AppColors.border),
          ),
          splashBorderRadius: BorderRadius.circular(radius * 0.8),
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: w * 0.034,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            fontSize: w * 0.034,
          ),
          tabs: [
            _TabLabel(label: 'Active', count: activeCount),
            _TabLabel(label: 'New', count: offerCount),
            const _TabLabel(label: 'History'),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;

  const _TabLabel({required this.label, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0) ...[
            SizedBox(width: w * 0.015),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.016,
                vertical: w * 0.003,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: w * 0.026,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
