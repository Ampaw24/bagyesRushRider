import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';

/// Horizontal animated step indicator for multi-step flows.
/// Completed steps show a green checkmark, active step shows a red pulsing
/// number, future steps show a grey number.
class AnimatedStepper extends StatelessWidget {
  final int stepCount;
  final int currentStep;
  final List<String> stepLabels;

  const AnimatedStepper({
    super.key,
    required this.stepCount,
    required this.currentStep,
    required this.stepLabels,
  }) : assert(stepLabels.length == stepCount);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: List.generate(stepCount * 2 - 1, (index) {
          if (index.isOdd) {
            // Connecting line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                color: isCompleted ? AppColors.success : Colors.grey.shade200,
              ),
            );
          } else {
            final stepIndex = index ~/ 2;
            return _StepCircle(
              stepIndex: stepIndex,
              currentStep: currentStep,
              label: stepLabels[stepIndex],
            );
          }
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int stepIndex;
  final int currentStep;
  final String label;

  const _StepCircle({
    required this.stepIndex,
    required this.currentStep,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isCompleted
                  ? const Icon(
                      HugeIcons.strokeRoundedCheckmarkCircle01,
                      key: ValueKey('check'),
                      size: 16,
                      color: Colors.white,
                    )
                  : Text(
                      '${stepIndex + 1}',
                      key: ValueKey(stepIndex),
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: 9,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400,
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : Colors.grey.shade400,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
