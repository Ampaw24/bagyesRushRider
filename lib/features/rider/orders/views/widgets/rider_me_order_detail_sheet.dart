import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/utils/external_navigation_launcher.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/core/widgets/status_badge.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_thread_args.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_thread_sheet.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/delivery_confirmation_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/reason_input_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_flow_args.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';
import 'package:hugeicons/hugeicons.dart';

/// Self-contained order detail sheet for the `/rider/me` order model —
/// unlike the legacy `RiderOrderDetailSheet` it replaces, it doesn't take an
/// injected action-button slot, because the action area now varies by
/// (isMultiStop, stage), not just by order id. Used by both the Active tab
/// (full action flow) and History (stage is always delivered/closed there,
/// so no action panel renders — no separate read-only variant needed).
class RiderMeOrderDetailSheet extends ConsumerStatefulWidget {
  final RiderMeOrderModel initialOrder;

  const RiderMeOrderDetailSheet({super.key, required this.initialOrder});

  @override
  ConsumerState<RiderMeOrderDetailSheet> createState() =>
      _RiderMeOrderDetailSheetState();
}

class _RiderMeOrderDetailSheetState
    extends ConsumerState<RiderMeOrderDetailSheet> {
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(riderMeOrdersProvider.notifier)
          .loadOrder(widget.initialOrder.id);
    });
  }

  RiderMeOrderModel _currentOrder(RiderMeOrdersState state) =>
      (state.selectedOrder?.id == widget.initialOrder.id)
          ? state.selectedOrder!
          : widget.initialOrder;

  Future<void> _runSimpleAction(Future<bool> Function() action) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _actionBusy = false);
    if (ok) {
      HapticFeedback.mediumImpact();
    } else {
      CustomDialog.showError(
        context: context,
        title: "Couldn't Update Order",
        subtitle:
            ref.read(riderMeOrdersProvider).actionMessage ?? 'Action failed',
      );
    }
  }

  Future<void> _openDeliverySheet(int orderId, {int? stopId}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DeliveryConfirmationSheet(orderId: orderId, stopId: stopId),
    );
    // No extra handling needed — success already updated shared state, and
    // for the single-drop case the order leaves the active list, so the
    // stage-driven body below naturally stops showing an action panel.
  }

  void _openReleaseSheet(int orderId) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReasonInputSheet(
        title: 'Release this order?',
        submitLabel: 'Release',
        onSubmit: (reason) =>
            ref.read(riderMeOrdersProvider.notifier).releaseOrder(
                  orderId,
                  reason: reason.isEmpty ? null : reason,
                ),
      ),
    ).then((released) {
      if (released == true && mounted) Navigator.of(context).pop();
    });
  }

  void _openUnreachableSheet(int orderId) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReasonInputSheet(
        title: "Can't reach the customer?",
        submitLabel: 'Mark Unreachable',
        onSubmit: (reason) =>
            ref.read(riderMeOrdersProvider.notifier).markUnreachable(
                  orderId,
                  reason: reason.isEmpty ? null : reason,
                ),
      ),
    ).then((marked) {
      if (marked == true && mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  /// Cheap/fast path: hand the address straight to the rider's own Maps app,
  /// no need to open [RiderOrderMapScreen] first. See
  /// `ExternalNavigationLauncher` for why this is address-only (the backend
  /// sends no coordinates) and why there's no in-app turn-by-turn.
  Future<void> _navigateTo(String? address) async {
    final ok = await ExternalNavigationLauncher.launch(address: address);
    if (!ok && mounted) {
      CustomDialog.showError(
        context: context,
        title: "Couldn't Open Maps",
        subtitle: 'No maps app is available on this device.',
      );
    }
  }

  void _openMap(RiderMeOrderModel order) =>
      context.push(AppRoutes.orderMap, extra: order);

  /// The chat API 422s until this order has an assigned rider — since this
  /// sheet only ever shows an order already on this rider's own list, that
  /// should already be true, but `RiderChatThreadSheet` still renders the
  /// "not available yet" state defensively rather than assuming it.
  void _openChat(RiderMeOrderModel order) {
    RiderChatThreadSheet.show(
      context,
      args: RiderChatThreadArgs(
        orderId: order.id,
        peerName: order.customerName,
        peerPhone: order.customerPhone,
      ),
    );
  }

  /// Pre-fills the report wizard with this order's customer — the rider
  /// still picks the reason/description, but skips the "what would you
  /// like to report?" and "which delivery?" steps since both are already
  /// known here.
  void _openReport(RiderMeOrderModel order) {
    context.push(
      AppRoutes.reportNew,
      extra: RiderReportFlowArgs(
        targetType: RiderReportTargetType.customer,
        orderId: order.id,
        targetName: (order.customerName?.isNotEmpty ?? false)
            ? order.customerName!
            : 'Customer',
        targetPhone: order.customerPhone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(riderMeOrdersProvider);
    final order = _currentOrder(ordersState);
    final stage = ordersState.stageFor(order);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            children: [
              const DragHandle(),

              // ── Gradient header ────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFCA445D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.reference ?? '#${order.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          if (order.isMultiStop) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${order.stops.length} stops',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: riderMeOrderStatusLabel(order.status),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Locations ──────────────────────────────────────────────
              _card(
                title: 'Location',
                headerAction: GestureDetector(
                  onTap: () => _openMap(order),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(HugeIcons.strokeRoundedMapsLocation01,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'View Map',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _locationRow(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        iconColor: Colors.green,
                        label: 'Pickup',
                        value: order.pickupAddress ?? '-',
                        onNavigate: () => _navigateTo(order.pickupAddress),
                      ),
                      const SizedBox(height: 10),
                      _locationRow(
                        icon: HugeIcons.strokeRoundedLocation01,
                        iconColor: AppColors.primary,
                        label: order.isMultiStop ? 'Final Stop' : 'Delivery',
                        value: order.dropoffAddress ?? '-',
                        onNavigate: () => _navigateTo(order.dropoffAddress),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Customer ───────────────────────────────────────────────
              _card(
                title: 'Customer',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _row('Name', order.customerName ?? '-'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Phone',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _callCustomer(order.customerPhone),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.customerPhone ?? '-',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(HugeIcons.strokeRoundedCall,
                                    size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Message',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openChat(order),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(HugeIcons.strokeRoundedBubbleChat,
                                    size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Problem with this delivery?',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openReport(order),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Report',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(HugeIcons.strokeRoundedFlag02,
                                    size: 16, color: AppColors.error),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Payment ────────────────────────────────────────────────
              _card(
                title: 'Payment',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _row(
                      'Amount',
                      order.amountFormatted.isEmpty
                          ? '-'
                          : order.amountFormatted,
                      valueStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      )),
                ),
              ),

              const SizedBox(height: 8),

              // ── Action panel ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildActionPanel(order, stage),
              ),

              const SizedBox(height: 12),

              // ── Release / Unreachable / Close ─────────────────────────
              if (stage != RiderDeliveryStage.delivered &&
                  stage != RiderDeliveryStage.closed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _actionBusy
                              ? null
                              : () => _openReleaseSheet(order.id),
                          child: const Text('Release',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: AppColors.textSecondary)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _actionBusy
                              ? null
                              : () => _openUnreachableSheet(order.id),
                          child: const Text('Unreachable',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: AppColors.error)),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(46),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionPanel(RiderMeOrderModel order, RiderDeliveryStage stage) {
    switch (stage) {
      case RiderDeliveryStage.notStarted:
        return AppGradientButton(
          label: 'Arrived at Pickup',
          isLoading: _actionBusy,
          onPressed: _actionBusy
              ? null
              : () => _runSimpleAction(() => ref
                  .read(riderMeOrdersProvider.notifier)
                  .arrivedAtPickup(order.id)),
        );

      case RiderDeliveryStage.arrivedAtPickup:
        return AppGradientButton(
          label: 'Picked Up',
          isLoading: _actionBusy,
          onPressed: _actionBusy
              ? null
              : () => _runSimpleAction(() => ref
                  .read(riderMeOrdersProvider.notifier)
                  .pickUpOrder(order.id)),
        );

      case RiderDeliveryStage.pickedUp:
        if (order.isMultiStop) {
          return _MultiStopPanel(
            order: order,
            busy: _actionBusy,
            onArrive: (stopId) => _runSimpleAction(() => ref
                .read(riderMeOrdersProvider.notifier)
                .arriveAtStop(order.id, stopId)),
            onDeliver: (stopId) => _openDeliverySheet(order.id, stopId: stopId),
            onFail: (stopId, reason) => ref
                .read(riderMeOrdersProvider.notifier)
                .failStop(order.id, stopId, reason: reason),
          );
        }
        return AppGradientButton(
          label: 'Arrived at Dropoff',
          isLoading: _actionBusy,
          onPressed: _actionBusy
              ? null
              : () => _runSimpleAction(() => ref
                  .read(riderMeOrdersProvider.notifier)
                  .arrivedAtDropoff(order.id)),
        );

      case RiderDeliveryStage.arrivedAtDropoff:
        return AppGradientButton(
          label: 'Mark Delivered',
          onPressed: () => _openDeliverySheet(order.id),
        );

      case RiderDeliveryStage.delivered:
      case RiderDeliveryStage.closed:
        return const SizedBox.shrink();
    }
  }

  // ── Shared card/row helpers (same visual language as the legacy sheet) ──

  Widget _card({
    required String title,
    required Widget child,
    Widget? headerAction,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (headerAction != null) headerAction,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: valueStyle ??
                const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onNavigate,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onNavigate,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(HugeIcons.strokeRoundedNavigator02,
                size: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ── Multi-stop panel ─────────────────────────────────────────────────────

class _MultiStopPanel extends ConsumerWidget {
  final RiderMeOrderModel order;
  final bool busy;
  final void Function(int stopId) onArrive;
  final void Function(int stopId) onDeliver;
  final Future<bool> Function(int stopId, String reason) onFail;

  const _MultiStopPanel({
    required this.order,
    required this.busy,
    required this.onArrive,
    required this.onDeliver,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(riderMeOrdersProvider);
    return Column(
      children: [
        for (final stop in order.stops)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StopTile(
              orderId: order.id,
              stop: stop,
              hasArrived: ordersState.hasArrived(order.id, stop.id),
              busy: busy,
              onArrive: () => onArrive(stop.id),
              onDeliver: () => onDeliver(stop.id),
              onFail: (reason) => onFail(stop.id, reason),
            ),
          ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  final int orderId;
  final RiderMeOrderStopModel stop;
  final bool hasArrived;
  final bool busy;
  final VoidCallback onArrive;
  final VoidCallback onDeliver;
  final Future<bool> Function(String reason) onFail;

  const _StopTile({
    required this.orderId,
    required this.stop,
    required this.hasArrived,
    required this.busy,
    required this.onArrive,
    required this.onDeliver,
    required this.onFail,
  });

  void _openFailSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReasonInputSheet(
        title: 'Why did this stop fail?',
        submitLabel: 'Report Failed Stop',
        requireNonEmpty: true,
        onSubmit: onFail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = stop.address ?? 'Stop ${stop.sequence ?? ''}';

    String statusText;
    Color statusColor;
    Widget? action;

    if (stop.isDelivered) {
      statusText = 'Delivered';
      statusColor = AppColors.success;
    } else if (stop.isFailed) {
      statusText =
          'Failed${stop.failureReason != null ? ': ${stop.failureReason}' : ''}';
      statusColor = AppColors.error;
    } else if (hasArrived) {
      statusText = 'Arrived';
      statusColor = AppColors.primary;
      action = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : () => _openFailSheet(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Fail',
                  style:
                      TextStyle(fontFamily: 'Roboto', color: AppColors.error)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: AppGradientButton(
              label: 'Deliver',
              height: 38,
              onPressed: busy ? null : onDeliver,
            ),
          ),
        ],
      );
    } else {
      statusText = 'Pending';
      statusColor = Colors.grey.shade400;
      action = AppGradientButton(
        label: 'Arrived at this Stop',
        height: 38,
        onPressed: busy ? null : onArrive,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(label: statusText, color: statusColor),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            action,
          ],
        ],
      ),
    );
  }
}
