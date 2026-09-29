import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';

const _kMilestones = ['At pickup', 'Picked up', 'At drop-off', 'Delivered'];

/// Four-segment progress bar showing where the rider is in the delivery,
/// so the next step is obvious before they reach the action button.
class RiderDeliveryProgress extends StatelessWidget {
  final RiderDeliveryStage stage;

  const RiderDeliveryProgress({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final done = stage.completedSteps;

    return Semantics(
      label: 'Delivery progress: $done of ${_kMilestones.length} steps done',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _kMilestones.length; i++) ...[
            if (i > 0) SizedBox(width: w * 0.015),
            Expanded(
              child: _Milestone(
                label: _kMilestones[i],
                isDone: i < done,
                isCurrent: i == done,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;

  const _Milestone({
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = isDone
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: w * 0.01,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(w * 0.01),
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: w * 0.028,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isDone || isCurrent
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
