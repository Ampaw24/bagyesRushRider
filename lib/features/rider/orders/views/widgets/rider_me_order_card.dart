import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card_shell.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_route_summary.dart';
import 'package:hugeicons/hugeicons.dart';

/// Card for a `RiderMeOrderModel` — used by both the Active and History
/// tabs. The whole card opens the order; [actionLabel], when given, adds a
/// full-width button naming the rider's next step (Active tab only).
class RiderMeOrderCard extends StatelessWidget {
  final RiderMeOrderModel order;
  final VoidCallback onTap;
  final String? actionLabel;

  const RiderMeOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final statusColor = riderMeOrderStatusColor(order.status);
    final label = actionLabel;

    return RiderOrderCardShell(
      onTap: onTap,
      semanticLabel: 'Order ${order.reference ?? order.id}',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.reference ?? '#${order.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            RiderOrderChip(
              label: riderMeOrderStatusLabel(order.status),
              color: statusColor,
            ),
          ],
        ),
        SizedBox(height: w * 0.035),
        RiderRouteSummary(
          pickup: order.pickupAddress,
          dropoff: order.dropoffAddress,
          dropoffLabel:
              order.isMultiStop ? '${order.stops.length} stops' : null,
        ),
        if (order.amountFormatted.isNotEmpty || label == null) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.03),
            child: const Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.amountFormatted,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (label == null)
                Icon(HugeIcons.strokeRoundedArrowRight01,
                    size: w * 0.045, color: AppColors.textHint),
            ],
          ),
        ],
        if (label != null) ...[
          SizedBox(height: w * 0.03),
          RiderOrderCardButton(label: label, onPressed: onTap),
        ],
      ],
    );
  }
}
