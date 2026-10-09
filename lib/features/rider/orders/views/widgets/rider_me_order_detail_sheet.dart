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
import 'package:delivery_boy/features/rider/orders/views/widgets/dropoff_wait_countdown.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/pickup_code_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/reason_input_sheet.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_delivery_progress.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sections.dart';
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

  /// A parcel the customer is receiving needs the sender's 4-digit collection
  /// code (see [PickupCodeSheet]); everything else is a bare confirmation.
  ///
  /// The order's `requiresPickupCode` flag decides, but a payload that didn't
  /// carry it must not let a rider through to a dead end: if the bare call is
  /// refused for want of `pickup_pin`, the code sheet opens instead of an
  /// error dialog.
  Future<void> _confirmPickup(RiderMeOrderModel order) async {
    if (_actionBusy) return;
    if (order.requiresPickupCode) {
      await _openPickupCodeSheet(order.id);
      return;
    }

    setState(() => _actionBusy = true);
    final notifier = ref.read(riderMeOrdersProvider.notifier);
    final ok = await notifier.pickUpOrder(order.id);
    if (!mounted) return;
    setState(() => _actionBusy = false);

    if (ok) {
      HapticFeedback.mediumImpact();
      return;
    }
    final state = ref.read(riderMeOrdersProvider);
    if (state.actionFieldErrors?.containsKey('pickup_pin') ?? false) {
      await _openPickupCodeSheet(order.id);
      return;
    }
    CustomDialog.showError(
      context: context,
      title: "Couldn't Update Order",
      subtitle: state.actionMessage ?? 'Action failed',
    );
  }

  Future<void> _openPickupCodeSheet(int orderId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickupCodeSheet(orderId: orderId),
    );
    // The sheet's own success already moved the stage on.
    if (confirmed == true) HapticFeedback.mediumImpact();
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
        failureMessage: () => ref.read(riderMeOrdersProvider).actionMessage,
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
        failureMessage: () => ref.read(riderMeOrdersProvider).actionMessage,
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

  /// Cheap/fast path: hand the point straight to the rider's own Maps app,
  /// no need to open [RiderOrderMapScreen] first. Server coordinates give an
  /// exact pin; the address alone still works, since Maps geocodes it.
  Future<void> _navigateTo(
    String label,
    String? address, {
    double? latitude,
    double? longitude,
  }) async {
    final hasTarget =
        (latitude != null && longitude != null) || (address?.isNotEmpty ?? false);
    if (!hasTarget) {
      CustomDialog.showInfo(
        context: context,
        title: 'No Location Yet',
        subtitle: "This order doesn't have a $label location to navigate to.",
      );
      return;
    }
    final ok = await ExternalNavigationLauncher.launch(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
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

    final isOpen = stage != RiderDeliveryStage.delivered &&
        stage != RiderDeliveryStage.closed;
    // Past pickup, a multi-stop order is advanced stop by stop — a list too
    // tall for the pinned footer, so its stop tiles sit in the body instead.
    final stopsInBody =
        order.isMultiStop && stage == RiderDeliveryStage.pickedUp;
    final w = MediaQuery.sizeOf(context).width;
    final gutter = w * 0.05;
    final sectionGap = w * 0.06;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(w * 0.05)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, sectionGap),
                  children: [
                    const DragHandle(),
                    OrderSheetHeader(
                      reference: order.reference ?? '#${order.id}',
                      statusLabel: riderMeOrderStatusLabel(order.status),
                      statusColor: riderMeOrderStatusColor(order.status),
                      amount: order.amountFormatted,
                      stopCount: order.isMultiStop ? order.stops.length : null,
                    ),
                    if (isOpen) ...[
                      SizedBox(height: w * 0.05),
                      RiderDeliveryProgress(stage: stage),
                    ],
                    SizedBox(height: sectionGap),

                    if (stopsInBody) ...[
                      const OrderSectionLabel(title: 'Stops'),
                      _buildActionPanel(order, stage),
                      SizedBox(height: sectionGap),
                    ],

                    // ── Route ──────────────────────────────────────────────
                    OrderSectionLabel(
                      title: 'Route',
                      trailing: OrderSectionAction(
                        label: 'View map',
                        icon: HugeIcons.strokeRoundedMapsLocation01,
                        onTap: () => _openMap(order),
                      ),
                    ),
                    OrderRouteTimeline(
                      pickupAddress: order.pickupAddress,
                      dropoffAddress: order.dropoffAddress,
                      dropoffLabel:
                          order.isMultiStop ? 'Final stop' : 'Drop-off',
                      onNavigatePickup: () => _navigateTo(
                        'pickup',
                        order.pickupAddress,
                        latitude: order.pickupLatitude,
                        longitude: order.pickupLongitude,
                      ),
                      onNavigateDropoff: () => _navigateTo(
                        'drop-off',
                        order.dropoffAddress,
                        latitude: order.dropoffLatitude,
                        longitude: order.dropoffLongitude,
                      ),
                    ),
                    SizedBox(height: sectionGap),

                    // ── Customer ───────────────────────────────────────────
                    const OrderSectionLabel(title: 'Customer'),
                    OrderCustomerTile(
                      name: order.customerName,
                      phone: order.customerPhone,
                      onCall: () => _callCustomer(order.customerPhone),
                      onChat: () => _openChat(order),
                    ),
                    SizedBox(height: sectionGap),

                    // ── Having trouble? ────────────────────────────────────
                    const OrderSectionLabel(title: 'Having trouble?'),
                    _buildIssueList(order, isOpen, stage),
                  ],
                ),
              ),

              // ── Pinned next step ───────────────────────────────────────
              // Always on screen, so the rider never has to scroll past the
              // order details to find how to move the delivery forward.
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                padding: EdgeInsets.fromLTRB(gutter, w * 0.03, gutter, w * 0.03),
                child: SafeArea(
                  top: false,
                  child: isOpen && !stopsInBody
                      ? _buildActionPanel(order, stage)
                      : _closeButton(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// While the customer wait window is running, "Can't reach customer" is
  /// locked behind its countdown; everywhere else the server decides.
  Widget _buildIssueList(
    RiderMeOrderModel order,
    bool isOpen,
    RiderDeliveryStage stage,
  ) {
    final wait = stage == RiderDeliveryStage.arrivedAtDropoff ? order.wait : null;
    if (wait == null) {
      return OrderIssueList(actions: _issueActions(order, isOpen));
    }
    return WaitCountdownBuilder(
      wait: wait,
      builder: (_, remaining) => OrderIssueList(
        actions: _issueActions(
          order,
          isOpen,
          waitRemaining: remaining,
        ),
      ),
    );
  }

  List<OrderIssueAction> _issueActions(
    RiderMeOrderModel order,
    bool isOpen, {
    Duration? waitRemaining,
  }) {
    final waiting = waitRemaining != null &&
        waitRemaining > Duration.zero &&
        order.canGiveUp != true;
    return [
      if (isOpen) ...[
        OrderIssueAction(
          icon: HugeIcons.strokeRoundedCallBlocked,
          title: "Can't reach customer",
          subtitle: waiting
              ? 'Available in ${formatWaitClock(waitRemaining)}'
              : 'Mark as unreachable after waiting',
          destructive: true,
          onTap: (_actionBusy || waiting)
              ? null
              : () => _openUnreachableSheet(order.id),
        ),
        OrderIssueAction(
          icon: HugeIcons.strokeRoundedArrowTurnBackward,
          title: 'Release order',
          subtitle: 'Hand it back so another rider can take it',
          onTap: _actionBusy ? null : () => _openReleaseSheet(order.id),
        ),
      ],
      OrderIssueAction(
        icon: HugeIcons.strokeRoundedFlag02,
        title: 'Report a problem',
        subtitle: 'Tell us what went wrong with this delivery',
        onTap: () => _openReport(order),
      ),
    ];
  }

  Widget _closeButton() {
    final w = MediaQuery.sizeOf(context).width;
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight((w * 0.12).clamp(46.0, 56.0)),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Close',
        style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      ),
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
          label: order.requiresPickupCode
              ? 'Enter Collection Code'
              : 'Confirm Pickup',
          isLoading: _actionBusy,
          onPressed: _actionBusy ? null : () => _confirmPickup(order),
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
          label: 'Arrived at Drop-off',
          isLoading: _actionBusy,
          onPressed: _actionBusy
              ? null
              : () => _runSimpleAction(() => ref
                  .read(riderMeOrdersProvider.notifier)
                  .arrivedAtDropoff(order.id)),
        );

      case RiderDeliveryStage.arrivedAtDropoff:
        final wait = order.wait;
        final completeButton = AppGradientButton(
          label: 'Complete Delivery',
          onPressed: () => _openDeliverySheet(order.id),
        );
        if (wait == null) return completeButton;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WaitCountdownBuilder(
              wait: wait,
              builder: (_, remaining) => DropoffWaitBanner(
                remaining: remaining,
                total: wait.total,
                onGiveUp: _actionBusy ? null : () => _openUnreachableSheet(order.id),
              ),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).width * 0.03),
            completeButton,
          ],
        );

      case RiderDeliveryStage.delivered:
      case RiderDeliveryStage.closed:
        return const SizedBox.shrink();
    }
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
              // A stop's `waiting` window also proves arrival, so this holds
              // after an app restart too.
              hasArrived: ordersState.hasArrived(order.id, stop.id) ||
                  stop.wait != null,
              busy: busy,
              onArrive: () => onArrive(stop.id),
              onDeliver: () => onDeliver(stop.id),
              onFail: (reason) => onFail(stop.id, reason),
              failureMessage: () =>
                  ref.read(riderMeOrdersProvider).actionMessage,
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
  final String? Function() failureMessage;

  const _StopTile({
    required this.orderId,
    required this.stop,
    required this.hasArrived,
    required this.busy,
    required this.onArrive,
    required this.onDeliver,
    required this.onFail,
    required this.failureMessage,
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
        failureMessage: failureMessage,
        onSubmit: onFail,
      ),
    );
  }

  /// Waiting at the stop: the Fail button stays out of reach until the wait
  /// window ends, then the banner offers it. Deliver is always available.
  Widget _buildWaitingActions(BuildContext context, RiderMeOrderWait wait) {
    final gap = MediaQuery.sizeOf(context).width * 0.03;
    return Column(
      children: [
        WaitCountdownBuilder(
          wait: wait,
          builder: (_, remaining) => DropoffWaitBanner(
            remaining: remaining,
            total: wait.total,
            onGiveUp: busy ? null : () => _openFailSheet(context),
            giveUpLabel: 'Fail this stop',
            waitingSubtitle: 'The recipient has been told you are here.',
            expiredSubtitle:
                'Still no answer? You can mark this stop as failed.',
          ),
        ),
        SizedBox(height: gap),
        AppGradientButton(
          label: 'Deliver',
          height: 38,
          onPressed: busy ? null : onDeliver,
        ),
      ],
    );
  }

  /// Arrived but no wait window in the payload — Fail and Deliver side by
  /// side, the server deciding whether a fail is allowed yet.
  Widget _buildArrivedActions(BuildContext context) {
    return Row(
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
      action = stop.wait != null
          ? _buildWaitingActions(context, stop.wait!)
          : _buildArrivedActions(context);
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
