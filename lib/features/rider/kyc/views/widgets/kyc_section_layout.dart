import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';

/// Shared frame for every checklist step: app bar, a one-line intro, the
/// step's fields, and a primary action pinned above the keyboard.
class KycSectionLayout extends StatelessWidget {
  const KycSectionLayout({
    super.key,
    required this.section,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.isBusy = false,
    this.secondary,
  });

  final KycSection section;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isBusy;

  /// Optional action under the primary button, e.g. "Retake photo".
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(section.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: m.gutter,
                  vertical: m.gap,
                ),
                child: KycContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Intro(section: section, metrics: m),
                      for (final child in children) ...[
                        SizedBox(height: m.gap),
                        child,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _ActionBar(
              label: primaryLabel,
              onPressed: onPrimary,
              isBusy: isBusy,
              secondary: secondary,
              metrics: m,
            ),
          ],
        ),
      ),
    );
  }
}

/// Centres content in a readable column on wide screens.
class KycContentWidth extends StatelessWidget {
  const KycContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: KycMetrics.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// A group heading inside a step, e.g. "Documents".
class KycSubheading extends StatelessWidget {
  const KycSubheading(this.text, {super.key, this.caption});

  final String text;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: m.bodySize,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: TextStyle(
              fontSize: m.captionSize,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Read-only fact shown in a step, e.g. the plate set at registration.
class KycInfoRow extends StatelessWidget {
  const KycInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Container(
      padding: EdgeInsets.all(m.gutter * 0.75),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(m.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: m.iconBadge * 0.45, color: AppColors.textSecondary),
          SizedBox(width: m.gutter * 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: m.captionSize,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: m.bodySize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: TextStyle(
                      fontSize: m.captionSize,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.section, required this.metrics});

  final KycSection section;
  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Row(
      children: [
        Container(
          width: m.iconBadge,
          height: m.iconBadge,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            section.icon,
            size: m.iconBadge * 0.5,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: m.gutter * 0.75),
        Expanded(
          child: Text(
            section.description,
            style: TextStyle(
              fontSize: m.bodySize,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.label,
    required this.onPressed,
    required this.isBusy,
    required this.secondary,
    required this.metrics,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;
  final Widget? secondary;
  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(m.gutter, m.gap * 0.75, m.gutter, m.gap * 0.75),
        child: KycContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppGradientButton(
                label: label,
                onPressed: onPressed,
                isLoading: isBusy,
              ),
              if (secondary != null) ...[
                SizedBox(height: m.gap * 0.5),
                secondary!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
