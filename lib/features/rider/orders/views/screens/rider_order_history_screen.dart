import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sheet.dart';
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
      ref.read(orderHistoryProvider.notifier).load();
    });
  }

  void _openDetailSheet(RiderOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderOrderDetailSheet(
        order: order,
        actionButton: AppGradientButton(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderHistoryProvider);

    if (state.status == OrdersStatus.loading ||
        state.status == OrdersStatus.initial) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(HugeIcons.strokeRoundedClock01,
                  color: AppColors.primary.withValues(alpha: 0.6), size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Delivery History',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed deliveries will appear here.',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(orderHistoryProvider.notifier).load(),
      child: ListView.builder(
        itemCount: state.orders.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final order = state.orders[i];
          return AnimatedListItem(
            index: i,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GestureDetector(
                onTap: () {
                  ref.read(orderHistoryProvider.notifier).selectOrder(order);
                  _openDetailSheet(order);
                },
                child: RiderOrderCard(
                  order: order,
                  actionButton: GestureDetector(
                    onTap: () {
                      ref
                          .read(orderHistoryProvider.notifier)
                          .selectOrder(order);
                      _openDetailSheet(order);
                    },
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
