import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Ordered status transition chain for the trip flow.
const _statusChain = [
  'accepted',
  'heading_to_pickup',
  'arrived_at_pickup',
  'picked_up',
  'en_route',
  'delivered',
];

const _nextButtonLabels = {
  'accepted': 'Head to Pickup',
  'heading_to_pickup': 'Arrived at Pickup',
  'arrived_at_pickup': 'Picked Up',
  'picked_up': 'En Route',
  'en_route': 'Mark Delivered',
  'delivered': 'Delivered ✓',
};

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
      ref.read(activeOrdersProvider.notifier).load();
    });
  }

  void _openOrderSheet(RiderOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderOrderDetailSheet(
        order: order,
        actionButton: _TripActionButton(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeOrdersProvider);

    ref.listen<ActiveOrdersState>(activeOrdersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(activeOrdersProvider.notifier).clearError();
      }
    });

    if (state.status == OrdersStatus.loading ||
        state.status == OrdersStatus.initial) {
      return const ShimmerListPlaceholder(itemCount: 4, itemHeight: 110);
    }

    if (state.orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(activeOrdersProvider.notifier).load(),
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
                child: RiderOrderCard(
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

  Widget _viewButton(RiderOrderModel order) {
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

// ── Trip action button (self-contained consumer widget) ───────────────────────

class _TripActionButton extends ConsumerStatefulWidget {
  final RiderOrderModel order;

  const _TripActionButton({required this.order});

  @override
  ConsumerState<_TripActionButton> createState() => _TripActionButtonState();
}

class _TripActionButtonState extends ConsumerState<_TripActionButton> {
  bool _loading = false;

  String get _currentStatus => widget.order.status ?? 'accepted';

  bool get _isDelivered => _currentStatus == 'delivered';

  String get _buttonLabel =>
      _nextButtonLabels[_currentStatus] ?? 'Update Status';

  String get _nextStatus {
    final idx = _statusChain.indexOf(_currentStatus);
    if (idx < 0 || idx >= _statusChain.length - 1) return _currentStatus;
    return _statusChain[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientButton(
      label: _buttonLabel,
      isLoading: _loading,
      onPressed: _isDelivered ? null : _advance,
    );
  }

  Future<void> _advance() async {
    if (_loading) return;
    setState(() => _loading = true);

    final notifier = ref.read(activeOrdersProvider.notifier);
    final userId = sl<UserSessionManager>().userId ?? '';
    final orderId = widget.order.id;
    bool ok = false;

    switch (_currentStatus) {
      // arrived_at_pickup → picked_up uses setTrip (PICKUP leg)
      case 'arrived_at_pickup':
        ok = await notifier.setTrip({
          'orderId': orderId,
          'courierId': userId,
          'tripType': 'PICKUP',
        });
        break;

      // en_route → delivered uses finishTrip
      case 'en_route':
        ok = await notifier.finishTrip({
          'orderId': orderId,
          'courierId': userId,
        });
        break;

      // All other transitions use updateOrderStatus
      default:
        ok = await notifier.updateOrderStatus(
          orderId: orderId,
          status: _nextStatus,
        );
    }

    setState(() => _loading = false);

    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      // Reload the list so the card status updates
      ref.read(activeOrdersProvider.notifier).load();

      if (_currentStatus == 'en_route') {
        // Trip finished — close sheet and show rating
        Navigator.of(context).pop();
        _showRating(context);
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $_nextStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showRating(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RatingSheet(orderId: widget.order.id),
    );
  }
}

// ── Inline rating sheet ───────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final String orderId;
  const _RatingSheet({required this.orderId});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(HugeIcons.strokeRoundedCheckmarkCircle01,
                color: Colors.green, size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'Trip Completed!',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How was this delivery?',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : HugeIcons.strokeRoundedStar,
                    color: i < _rating ? Colors.amber : Colors.grey.shade300,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontFamily: 'Roboto'),
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 20),
          AppGradientButton(
            label: _rating == 0 ? 'Skip' : 'Submit Rating',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
