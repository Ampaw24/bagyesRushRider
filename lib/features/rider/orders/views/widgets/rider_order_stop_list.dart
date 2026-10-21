import 'package:gopady_rider/constant/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/core/widgets/adaptive_animated_size.dart';
import 'package:gopady_rider/features/rider/orders/models/rider_me_order_model.dart';
import 'package:gopady_rider/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/dropoff_wait_countdown.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/reason_input_sheet.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_order_card_shell.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_order_detail_sections.dart';
import 'package:hugeicons/hugeicons.dart';

/// A parcel's stops, each worked on its own once the parcel is picked up:
/// arrive, then deliver — or fail it once its wait window is over. Shown in
/// the order sheet's body, where there's room for the whole list.
class RiderOrderStopList extends ConsumerWidget {
  final RiderMeOrderModel order;
  final bool busy;
  final void Function(int stopId) onArrive;
  final void Function(int stopId) onDeliver;
  final Future<bool> Function(int stopId, String reason) onFail;

  const RiderOrderStopList({
    super.key,
    required this.order,
    required this.busy,
    required this.onArrive,
    required this.onDeliver,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(riderMeOrdersProvider);
    final gap = MediaQuery.sizeOf(context).width * 0.025;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < order.stops.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _StopTile(
            number: i + 1,
            stop: order.stops[i],
            // A stop's `waiting` window also proves arrival, so this holds
            // after an app restart too.
            hasArrived: ordersState.hasArrived(order.id, order.stops[i].id) ||
                order.stops[i].wait != null,
            busy: busy,
            onArrive: () => onArrive(order.stops[i].id),
            onDeliver: () => onDeliver(order.stops[i].id),
            onFail: (reason) => onFail(order.stops[i].id, reason),
            failureMessage: () =>
                ref.read(riderMeOrdersProvider).actionMessage,
          ),
        ],
      ],
    );
  }
}

/// [failed] is on hold — support may yet reopen it; [reopened] is a failed
/// stop support has made deliverable again (`can_deliver`).
enum _StopState { pending, arrived, waiting, delivered, failed, reopened }

class _StopTile extends StatelessWidget {
  /// Position in the route, shown in the badge.
  final int number;
  final RiderMeOrderStopModel stop;
  final bool hasArrived;
  final bool busy;
  final VoidCallback onArrive;
  final VoidCallback onDeliver;
  final Future<bool> Function(String reason) onFail;
  final String? Function() failureMessage;

  const _StopTile({
    required this.number,
    required this.stop,
    required this.hasArrived,
    required this.busy,
    required this.onArrive,
    required this.onDeliver,
    required this.onFail,
    required this.failureMessage,
  });

  _StopState get _state {
    if (stop.isDelivered) return _StopState.delivered;
    if (stop.isFailed) {
      return stop.isReopened ? _StopState.reopened : _StopState.failed;
    }
    if (!hasArrived) return _StopState.pending;
    return stop.wait != null ? _StopState.waiting : _StopState.arrived;
  }

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        RiderOrderCardButton(
          label: 'Deliver',
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
          child: RiderOrderCardButton(
            label: 'Fail',
            outlined: true,
            destructive: true,
            onPressed: busy ? null : () => _openFailSheet(context),
          ),
        ),
        SizedBox(width: MediaQuery.sizeOf(context).width * 0.025),
        Expanded(
          flex: 2,
          child: RiderOrderCardButton(
            label: 'Deliver',
            onPressed: busy ? null : onDeliver,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);
    final state = _state;
    final (String statusLabel, Color statusColor) = switch (state) {
      _StopState.delivered => ('Delivered', AppColors.success),
      _StopState.failed => ('Failed', AppColors.error),
      _StopState.reopened => ('Reopened', AppColors.info),
      _StopState.arrived || _StopState.waiting => ('Arrived', AppColors.primary),
      _StopState.pending => ('Pending', AppColors.textSecondary),
    };
    final Widget? action = switch (state) {
      _StopState.pending => RiderOrderCardButton(
          label: 'Arrived at this Stop',
          onPressed: busy ? null : onArrive,
        ),
      _StopState.arrived => _buildArrivedActions(context),
      _StopState.waiting => _buildWaitingActions(context, stop.wait!),
      // The rider was already there, so straight back to Deliver / Fail.
      _StopState.reopened => _buildArrivedActions(context),
      _StopState.delivered || _StopState.failed => null,
    };
    final recipient = stop.recipientName?.trim() ?? '';
    final reason =
        state == _StopState.failed ? (stop.failureReason?.trim() ?? '') : '';
    final detailStyle = TextStyle(
      fontFamily: AppFonts.body,
      fontSize: (w * 0.031).clamp(11.0, 13.0),
      color: AppColors.textSecondary,
    );

    return OrderSurface(
      padding: EdgeInsets.all(w * 0.035),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StopBadge(number: number, state: state, color: statusColor),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.address ?? 'Stop $number',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: (w * 0.035).clamp(13.0, 15.0),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (recipient.isNotEmpty) ...[
                      SizedBox(height: w * 0.008),
                      Text(
                        'For $recipient',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: detailStyle,
                      ),
                    ],
                    if (reason.isNotEmpty) ...[
                      SizedBox(height: w * 0.008),
                      Text(reason, style: detailStyle),
                    ],
                    if (state == _StopState.failed) ...[
                      SizedBox(height: w * 0.008),
                      Text(
                        'Waiting for support',
                        style: detailStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: w * 0.02),
              AnimatedSwitcher(
                duration: motion,
                child: OrderStatusPill(
                  key: ValueKey(statusLabel),
                  label: statusLabel,
                  color: statusColor,
                ),
              ),
            ],
          ),
          // The stop's actions change as the rider works it — arrived,
          // waiting, done. Ease between them rather than jumping.
          AdaptiveAnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: motion,
              child: action == null
                  ? SizedBox(key: ValueKey(state), width: double.infinity)
                  : Padding(
                      key: ValueKey(state),
                      padding: EdgeInsets.only(top: w * 0.03),
                      child: action,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The stop's place in the route; once the stop is done, a tick or cross
/// instead, so its outcome doesn't rest on colour alone.
class _StopBadge extends StatelessWidget {
  final int number;
  final _StopState state;
  final Color color;

  const _StopBadge({
    required this.number,
    required this.state,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * 0.075).clamp(26.0, 34.0);
    final icon = switch (state) {
      _StopState.delivered => HugeIcons.strokeRoundedTick02,
      _StopState.failed => HugeIcons.strokeRoundedCancel01,
      _ => null,
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.55, color: color)
          : Text(
              '$number',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
    );
  }
}
