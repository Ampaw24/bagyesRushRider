import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/widgets/animated_list_item.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

class RiderNewOrdersScreen extends ConsumerStatefulWidget {
  const RiderNewOrdersScreen({super.key});

  @override
  ConsumerState<RiderNewOrdersScreen> createState() =>
      _RiderNewOrdersScreenState();
}

class _RiderNewOrdersScreenState extends ConsumerState<RiderNewOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newOrdersProvider.notifier).load();
    });
  }

  String get _userId =>
      sl<UserSessionManager>().currentUser?['_id'] as String? ?? '';

  void _openDetailSheet(RiderOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderOrderDetailSheet(
        order: order,
        actionButton: _AcceptRejectRow(
          order: order,
          userId: _userId,
          onReject: () => _showRejectDialog(order),
        ),
      ),
    );
  }

  void _showRejectDialog(RiderOrderModel order) {
    String reason = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reason for Rejection',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => reason = v,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason here...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontFamily: 'Roboto'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              AppGradientButton(
                label: 'Submit Rejection',
                onPressed: () async {
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(newOrdersProvider.notifier)
                      .rejectOrder(
                        orderId: order.id,
                        courierId: _userId,
                        reason: reason,
                      );
                  if (ok && mounted) {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order rejected'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newOrdersProvider);

    ref.listen<NewOrdersState>(newOrdersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(newOrdersProvider.notifier).clearError();
      }
    });

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
              child: Icon(HugeIcons.strokeRoundedShoppingCart01,
                  color: AppColors.primary.withValues(alpha: 0.6), size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No New Orders',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New delivery requests will appear here.',
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
      onRefresh: () => ref.read(newOrdersProvider.notifier).load(),
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
              child: Slidable(
                key: ValueKey(order.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.5,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _quickAccept(order),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      label: 'Accept',
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                    ),
                    SlidableAction(
                      onPressed: (_) => _showRejectDialog(order),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      icon: HugeIcons.strokeRoundedCancelCircle,
                      label: 'Reject',
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12)),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _openDetailSheet(order),
                  child: RiderOrderCard(
                    order: order,
                    actionButton: GestureDetector(
                      onTap: () => _openDetailSheet(order),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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

  Future<void> _quickAccept(RiderOrderModel order) async {
    final ok = await ref.read(newOrdersProvider.notifier).acceptOrder(
          orderId: order.id,
          courierId: _userId,
        );
    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

// ── Accept / Reject row shown inside the detail sheet ────────────────────────

class _AcceptRejectRow extends ConsumerStatefulWidget {
  final RiderOrderModel order;
  final String userId;
  final VoidCallback onReject;

  const _AcceptRejectRow({
    required this.order,
    required this.userId,
    required this.onReject,
  });

  @override
  ConsumerState<_AcceptRejectRow> createState() => _AcceptRejectRowState();
}

class _AcceptRejectRowState extends ConsumerState<_AcceptRejectRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _loading ? null : () {
              Navigator.pop(context);
              widget.onReject();
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Reject',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppGradientButton(
            label: 'Accept',
            isLoading: _loading,
            onPressed: _loading ? null : _accept,
          ),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    setState(() => _loading = true);
    final ok = await ref.read(newOrdersProvider.notifier).acceptOrder(
          orderId: widget.order.id,
          courierId: widget.userId,
        );
    setState(() => _loading = false);
    if (ok && mounted) {
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
