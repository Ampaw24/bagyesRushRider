import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_delivery_progress.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card_shell.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_status_header.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_route_summary.dart';
import 'package:hugeicons/hugeicons.dart';

/// Card for a `RiderMeOrderModel` — used by both the Active and History
/// tabs. Leads with the order's status ([RiderOrderStatusHeader]); the whole
/// card opens the order. On the Active tab, [stage] adds the delivery
/// progress bar and [actionLabel] a full-width button naming the rider's
/// next step.
class RiderMeOrderCard extends StatelessWidget {
  final RiderMeOrderModel order;
  final VoidCallback onTap;
  final String? actionLabel;

  /// Where the rider is in this delivery, shown as progress while the
  /// delivery is still open.
  final RiderDeliveryStage? stage;

  /// Waiting on support after the rider gave up — see
  /// `RiderMeOrdersState.isOnHold`.
  final bool onHold;

  const RiderMeOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.actionLabel,
    this.stage,
    this.onHold = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final label = actionLabel;
    final stage = this.stage;
    final showProgress = stage != null &&
        stage != RiderDeliveryStage.delivered &&
        stage != RiderDeliveryStage.closed;
    final reference = order.reference ?? '#${order.id}';
    final titleStyle = TextStyle(
      fontFamily: 'Roboto',
      fontSize: (w * 0.04).clamp(14.0, 18.0),
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return RiderOrderCardShell(
      onTap: onTap,
      semanticLabel:
          'Order $reference, ${riderMeOrderStatusLabel(order.status)}',
      header: RiderOrderStatusHeader(
        status: order.status,
        isLive: order.isActive,
        onHold: onHold,
        subtitle: order.createdAtFormatted,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            if (order.amountFormatted.isNotEmpty) ...[
              SizedBox(width: w * 0.03),
              Text(order.amountFormatted, style: titleStyle),
            ],
            if (label == null) ...[
              SizedBox(width: w * 0.015),
              Icon(
                HugeIcons.strokeRoundedArrowRight01,
                size: (w * 0.045).clamp(16.0, 20.0),
                color: AppColors.textHint,
              ),
            ],
          ],
        ),
        SizedBox(height: w * 0.035),
        RiderRouteSummary(
          pickup: order.pickupAddress,
          dropoff: order.dropoffAddress,
          dropoffLabel:
              order.isMultiStop ? '${order.stops.length} stops' : null,
        ),
        if (showProgress) ...[
          SizedBox(height: w * 0.045),
          RiderDeliveryProgress(stage: stage),
        ],
        if (label != null) ...[
          SizedBox(height: w * 0.04),
          RiderOrderCardButton(
            label: label,
            onPressed: onTap,
            trailingIcon: HugeIcons.strokeRoundedArrowRight01,
          ),
        ],
      ],
    );
  }
}
