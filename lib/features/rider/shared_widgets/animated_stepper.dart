import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

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

class _StepCircle extends StatefulWidget {
  final int stepIndex;
  final int currentStep;
  final String label;

  const _StepCircle({
    required this.stepIndex,
    required this.currentStep,
    required this.label,
  });

  @override
  State<_StepCircle> createState() => _StepCircleState();
}

class _StepCircleState extends State<_StepCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(_StepCircle old) {
    super.didUpdateWidget(old);
    if (old.currentStep != widget.currentStep) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.stepIndex == widget.currentStep) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.stepIndex < widget.currentStep;
    final isActive = widget.stepIndex == widget.currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: isActive ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: AnimatedContainer(
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
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('check'),
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '${widget.stepIndex + 1}',
                        key: ValueKey(widget.stepIndex),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Roboto',
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
