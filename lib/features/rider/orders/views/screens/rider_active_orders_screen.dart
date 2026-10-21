import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/widgets/animated_list_item.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';
import 'package:gopady_rider/core/widgets/shimmer_list_placeholder.dart';
import 'package:gopady_rider/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:gopady_rider/features/rider/orders/models/rider_me_order_model.dart';
import 'package:gopady_rider/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_me_order_card.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_me_order_detail_sheet.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_orders_empty_state.dart';
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

    // Placeholder only until the first list arrives: a reload (pull-to-
    // refresh, closing the order sheet) keeps the cards on screen, so status
    // and progress changes animate in place instead of flashing the shimmer.
    if ((state.status == RiderMeOrdersStatus.loading ||
            state.status == RiderMeOrdersStatus.initial) &&
        state.orders.isEmpty) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    Future<void> reload() =>
        ref.read(riderMeOrdersProvider.notifier).load(filter: 'active');

    if (state.orders.isEmpty) {
      return RiderOrdersEmptyState(
        icon: HugeIcons.strokeRoundedBicycle,
        title: 'No active orders',
        message: 'Orders you accept will appear here.',
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
          final stage = state.stageFor(order);
          final onHold = state.isOnHold(order);
          return AnimatedListItem(
            // Keeps each card's animation state with its order, not its slot.
            key: ValueKey(order.id),
            index: i,
            child: RiderMeOrderCard(
              order: order,
              stage: stage,
              onHold: onHold,
              onTap: () => _openOrderSheet(order),
              // Names the rider's next step on the card itself so the
              // delivery flow is discoverable without opening the order —
              // none while it waits on support.
              actionLabel: (onHold
                      ? null
                      : stage.nextActionLabel(usesStops: order.usesStopFlow)) ??
                  'View order',
            ),
          );
        },
      ),
    );
  }
}
