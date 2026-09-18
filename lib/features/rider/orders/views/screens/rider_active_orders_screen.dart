import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_detail_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class RiderActiveOrdersScreen extends ConsumerStatefulWidget {
  const RiderActiveOrdersScreen({super.key});

  @override
  ConsumerState<RiderActiveOrdersScreen> createState() =>
      _RiderActiveOrdersScreenState();
}

class _RiderActiveOrdersScreenState
    extends ConsumerState<RiderActiveOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderMeOrdersProvider.notifier).load(filter: 'active');
    });
  }

  Future<void> _openOrderSheet(RiderMeOrderModel order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderMeOrderDetailSheet(initialOrder: order),
    );
    // Always reload — simplest robust refresh after any in-sheet action
    // (arrived/pick-up/deliver/release/unreachable all change what belongs
    // in the active list).
    if (mounted) {
      ref.read(riderMeOrdersProvider.notifier).load(filter: 'active');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderMeOrdersProvider);

    ref.listen<RiderMeOrdersState>(riderMeOrdersProvider, (prev, next) {
      // Only on a new error: the message stays set across later emissions
      // (e.g. actions in the detail sheet), which would re-open the dialog.
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        CustomDialog.showError(
          context: context,
          title: "Couldn't Load Orders",
          subtitle: next.errorMessage!,
        );
      }
    });

    if (state.status == RiderMeOrdersStatus.loading ||
        state.status == RiderMeOrdersStatus.initial) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    if (state.orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(riderMeOrdersProvider.notifier).load(filter: 'active'),
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
                onTap: () => _openOrderSheet(order),
                child: RiderMeOrderCard(
                  order: order,
                  actionButton: _viewButton(order),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: Icon(HugeIcons.strokeRoundedBicycle,
                color: AppColors.primary.withValues(alpha: 0.6), size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Active Orders',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders you accept will appear here.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewButton(RiderMeOrderModel order) {
    return GestureDetector(
      onTap: () => _openOrderSheet(order),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFCA445D)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'View',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
