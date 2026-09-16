import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';

class RegistrationStepper extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
  final ValueChanged<int>? onStepTapped;

  const RegistrationStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final circleSize = (w * 0.08).clamp(30.0, 42.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                // Step Circle + Label Column
                Expanded(
                  child: InkWell(
                    onTap: (onStepTapped != null && i < currentIndex)
                        ? () => onStepTapped!(i)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: circleSize,
                          height: circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < currentIndex
                                ? AppColors.success
                                : i == currentIndex
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                            border: Border.all(
                              color: i < currentIndex
                                  ? AppColors.success
                                  : i == currentIndex
                                      ? AppColors.primary
                                      : AppColors.border,
                              width: i == currentIndex ? 2.5 : 1.5,
                            ),
                            boxShadow: i == currentIndex
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: i < currentIndex
                                  ? Icon(
                                      HugeIcons.strokeRoundedCheckmarkCircle01,
                                      key: const ValueKey('check'),
                                      color: Colors.white,
                                      size: (circleSize * 0.52).clamp(14.0, 22.0),
                                    )
                                  : Text(
                                      '${i + 1}',
                                      key: ValueKey('num_$i'),
                                      style: TextStyle(
                                        fontFamily: 'Mukta',
                                        fontSize:
                                            (circleSize * 0.42).clamp(12.0, 16.0),
                                        fontWeight: FontWeight.w700,
                                        color: i == currentIndex
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.028).clamp(9.0, 12.0),
                            fontWeight: i == currentIndex
                                ? FontWeight.w700
                                : i < currentIndex
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                            color: i == currentIndex
                                ? AppColors.primary
                                : i < currentIndex
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: Text(steps[i]),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: SizedBox(
                      width: (w * 0.06).clamp(12.0, 28.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i < currentIndex
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
