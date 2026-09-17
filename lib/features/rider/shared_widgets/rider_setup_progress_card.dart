import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';

class RiderSetupStep {
  final String label;
  final String activeTitle;
  final bool completed;
  final VoidCallback? onStart;

  const RiderSetupStep({
    required this.label,
    required this.activeTitle,
    required this.completed,
    this.onStart,
  });
}

/// Builds the identity-verification checklist off the same document keys
/// [RiderDocumentUploadScreen] tracks (via [riderDocumentCompletionProvider]),
/// so this card and that screen can never disagree about what's still
/// outstanding.
List<RiderSetupStep> buildRiderSetupSteps(
  Map<String, bool> docStatus, {
  required VoidCallback onStart,
}) {
  bool done(String key) => docStatus[key] ?? false;

  return [
    RiderSetupStep(
      label: 'Profile selfie',
      activeTitle: 'Upload a clear selfie to verify your identity',
      completed: done('selfie'),
      onStart: onStart,
    ),
    RiderSetupStep(
      label: "Driver's licence",
      activeTitle: "Upload your driver's licence to start accepting orders",
      completed: done('drivers_licence_front') && done('drivers_licence_back'),
      onStart: onStart,
    ),
    RiderSetupStep(
      label: 'Motor insurance',
      activeTitle: 'Upload proof of motor insurance',
      completed: done('insurance_certificate'),
      onStart: onStart,
    ),
    RiderSetupStep(
      label: 'Roadworthy certificate',
      activeTitle: 'Upload your roadworthy certificate',
      completed: done('roadworthy_certificate'),
      onStart: onStart,
    ),
  ];
}

/// Dark "Finish Setup" checklist — same technique the vendor dashboard uses
/// to nudge outstanding onboarding steps, adapted for the rider's identity
/// verification documents.
class RiderSetupProgressCard extends StatelessWidget {
  final List<RiderSetupStep> steps;

  const RiderSetupProgressCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexWhere((s) => !s.completed);
    if (currentIndex == -1) return const SizedBox.shrink();

    final completedCount = steps.where((s) => s.completed).length;
    final current = steps[currentIndex];
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(w * 0.045),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FINISH SETUP',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  color: AppColors.primaryLight,
                  fontSize: (w * 0.03).clamp(11.0, 13.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount/${steps.length}',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: (w * 0.032).clamp(11.0, 13.0),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.02),
          Text(
            current.activeTitle,
            style: TextStyle(
              fontFamily: 'Mukta',
              color: Colors.white,
              fontSize: (w * 0.046).clamp(16.0, 20.0),
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: w * 0.032),
          Row(
            children: List.generate(steps.length, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i == steps.length - 1 ? 0 : w * 0.012,
                  ),
                  height: w * 0.009,
                  decoration: BoxDecoration(
                    color: i < completedCount
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(w * 0.01),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: w * 0.018),
          ...List.generate(steps.length, (i) {
            return _RiderStepRow(
              step: steps[i],
              isDone: i < completedCount,
              isCurrent: i == currentIndex,
              isLast: i == steps.length - 1,
              w: w,
            );
          }),
        ],
      ),
    );
  }
}

class _RiderStepRow extends StatelessWidget {
  final RiderSetupStep step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final double w;

  const _RiderStepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: w * 0.022),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
      ),
      child: Row(
        children: [
          _RiderStatusCircle(isDone: isDone, isCurrent: isCurrent, w: w),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontFamily: 'Mukta',
                color: isCurrent
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: (w * 0.033).clamp(12.0, 14.0),
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isCurrent && step.onStart != null)
            GestureDetector(
              onTap: step.onStart,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.035,
                  vertical: w * 0.015,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(w * 0.05),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    color: Colors.white,
                    fontSize: (w * 0.029).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiderStatusCircle extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final double w;

  const _RiderStatusCircle({
    required this.isDone,
    required this.isCurrent,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final size = (w * 0.052).clamp(18.0, 22.0);
    if (isDone) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(
          HugeIcons.strokeRoundedTick01,
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
    );
  }
}
