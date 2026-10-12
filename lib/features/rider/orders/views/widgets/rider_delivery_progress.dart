import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_delivery_stage.dart';

const _kMilestones = ['At pickup', 'Picked up', 'At drop-off', 'Delivered'];

/// Four-segment progress bar showing where the rider is in the delivery,
/// so the next step is obvious before they reach the action button. The
/// segments fill left to right when shown, and from the old position when
/// the stage advances.
class RiderDeliveryProgress extends StatelessWidget {
  final RiderDeliveryStage stage;

  const RiderDeliveryProgress({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final done = stage.completedSteps;
    // The current milestone is drawn filled too, in the "in progress" colour.
    final filled = (done + 1).clamp(0, _kMilestones.length);

    return Semantics(
      label: 'Delivery progress: $done of ${_kMilestones.length} steps done',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: filled.toDouble()),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, value, __) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _kMilestones.length; i++) ...[
              if (i > 0) SizedBox(width: w * 0.015),
              Expanded(
                child: _Milestone(
                  label: _kMilestones[i],
                  fill: (value - i).clamp(0.0, 1.0),
                  isDone: i < done,
                  isCurrent: i == done,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  final String label;

  /// How much of this milestone's bar is drawn, 0–1.
  final double fill;
  final bool isDone;
  final bool isCurrent;

  const _Milestone({
    required this.label,
    required this.fill,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final barHeight = (w * 0.01).clamp(3.0, 6.0);
    final radius = BorderRadius.circular(barHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: barHeight,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: radius,
          ),
          child: FractionallySizedBox(
            widthFactor: fill,
            heightFactor: 1,
            // Eases from "in progress" to "done" when the step completes.
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : AppColors.primary,
                borderRadius: radius,
              ),
            ),
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.028).clamp(10.0, 12.0),
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
