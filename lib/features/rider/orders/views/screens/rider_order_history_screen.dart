import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/widgets/animated_list_item.dart';
import 'package:gopady_rider/core/widgets/shimmer_list_placeholder.dart';
import 'package:gopady_rider/features/rider/orders/models/rider_me_order_model.dart';
import 'package:gopady_rider/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_me_order_card.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_me_order_detail_sheet.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_orders_empty_state.dart';
import 'package:hugeicons/hugeicons.dart';

class RiderOrderHistoryScreen extends ConsumerStatefulWidget {
  const RiderOrderHistoryScreen({super.key});

  @override
  ConsumerState<RiderOrderHistoryScreen> createState() =>
      _RiderOrderHistoryScreenState();
}

class _RiderOrderHistoryScreenState
    extends ConsumerState<RiderOrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeOrderHistoryProvider.notifier).load();
    });
  }

  void _openDetailSheet(RiderMeOrderModel order) {
    // Same detail sheet as Active — its stage-driven body naturally shows
    // no action panel for a delivered/closed order, only Release/
    // Unreachable are hidden too since those also gate on stage.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderMeOrderDetailSheet(initialOrder: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderMeOrderHistoryProvider);

    // Placeholder only until the first list arrives — a pull-to-refresh
    // keeps the cards on screen under the refresh spinner.
    if ((state.status == RiderMeOrdersStatus.loading ||
            state.status == RiderMeOrdersStatus.initial) &&
        state.orders.isEmpty) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    Future<void> reload() =>
        ref.read(riderMeOrderHistoryProvider.notifier).load();

    if (state.orders.isEmpty) {
      return RiderOrdersEmptyState(
        icon: HugeIcons.strokeRoundedClock01,
        title: 'No delivery history',
        message: 'Completed deliveries will appear here.',
        onRefresh: reload,
      );
    }

    final w = MediaQuery.sizeOf(context).width;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: reload,
      child: ListView.separated(
        itemCount: state.orders.length,
        padding: EdgeInsets.all(w * 0.04),
        physics: const AlwaysScrollableScrollPhysics(),
        separatorBuilder: (_, __) => SizedBox(height: w * 0.03),
        itemBuilder: (_, i) {
          final order = state.orders[i];
          return AnimatedListItem(
            key: ValueKey(order.id),
            index: i,
            child: RiderMeOrderCard(
              order: order,
              onTap: () => _openDetailSheet(order),
            ),
          );
        },
      ),
    );
  }
}
