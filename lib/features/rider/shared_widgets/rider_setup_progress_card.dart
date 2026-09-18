import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_progress.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';

/// Dark "Finish setup" card for the home screen — the same technique the
/// vendor dashboard uses to nudge outstanding onboarding.
///
/// Built from [KycProgress], so it lists exactly the steps the verification
/// checklist does, and each row opens its step directly.
class RiderSetupProgressCard extends StatelessWidget {
  const RiderSetupProgressCard({
    super.key,
    required this.progress,
    required this.onOpen,
  });

  final KycProgress progress;
  final ValueChanged<KycSection> onOpen;

  @override
  Widget build(BuildContext context) {
    final pending = progress.sections.where((s) => s.needsAction).toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final w = MediaQuery.sizeOf(context).width;
    final current = pending.first.section;

    // Material rather than a decorated Container, so the rows' ink ripples
    // show on the dark surface.
    return Material(
      color: AppColors.secondaryDark,
      borderRadius: BorderRadius.circular(w * 0.045),
      child: Padding(
        padding: EdgeInsets.all(w * 0.045),
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
                  '${progress.completedCount}/${progress.totalCount}',
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
              current.prompt,
              style: TextStyle(
                fontFamily: 'Mukta',
                color: Colors.white,
                fontSize: (w * 0.046).clamp(16.0, 20.0),
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            SizedBox(height: w * 0.032),
            _SegmentBar(progress: progress, w: w),
            SizedBox(height: w * 0.018),
            for (final (i, step) in pending.indexed)
              _StepRow(
                step: step,
                isCurrent: i == 0,
                isLast: i == pending.length - 1,
                onTap: () => onOpen(step.section),
                w: w,
              ),
          ],
        ),
      ),
    );
  }
}

/// One segment per step, filled for the ones that are done.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.progress, required this.w});

  final KycProgress progress;
  final double w;

  @override
  Widget build(BuildContext context) {
    final sections = progress.sections;
    return Row(
      children: [
        for (final (i, s) in sections.indexed)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: i == sections.length - 1 ? 0 : w * 0.012,
              ),
              height: w * 0.009,
              decoration: BoxDecoration(
                color: s.needsAction
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(w * 0.01),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isCurrent,
    required this.isLast,
    required this.onTap,
    required this.w,
  });

  final KycSectionProgress step;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback onTap;
  final double w;

  @override
  Widget build(BuildContext context) {
    final circle = (w * 0.052).clamp(18.0, 22.0);

    return Semantics(
      button: true,
      label: '${step.section.title}, ${step.summary} needed',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: w * 0.022),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.section.title,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        color: isCurrent
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: (w * 0.033).clamp(12.0, 14.0),
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (step.summary.isNotEmpty)
                      Text(
                        '${step.summary} needed',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: (w * 0.029).clamp(10.5, 12.0),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
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
                )
              else
                Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: (w * 0.045).clamp(16.0, 20.0),
                  color: Colors.white.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
