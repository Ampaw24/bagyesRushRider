import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_progress.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';

/// Headline, progress and review status at the top of the checklist.
class KycStatusHeader extends StatelessWidget {
  const KycStatusHeader({
    super.key,
    required this.progress,
    this.hasSubmitted = false,
  });

  final KycProgress progress;
  final bool hasSubmitted;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final (title, subtitle) = _copy();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: m.titleSize * 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: m.gap * 0.25),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: m.bodySize,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        SizedBox(height: m.gap),
        Semantics(
          label: '${progress.completedCount} of ${progress.totalCount} steps complete',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(m.radius),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: m.gap * 0.4,
              backgroundColor: AppColors.border,
              color: progress.isProfileComplete
                  ? AppColors.success
                  : AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: m.gap * 0.4),
        Text(
          '${progress.completedCount} of ${progress.totalCount} steps complete',
          style: TextStyle(
            fontSize: m.captionSize,
            color: AppColors.textSecondary,
          ),
        ),
        if (progress.isRejected) ...[
          SizedBox(height: m.gap),
          KycNotice(
            icon: HugeIcons.strokeRoundedCancelCircle,
            color: AppColors.error,
            title: 'Changes needed',
            message: progress.rejectionReason ??
                'Our team couldn’t approve your profile. Update the steps '
                    'below and submit again.',
          ),
        ],
        if (progress.expiredCredentials.isNotEmpty) ...[
          SizedBox(height: m.gap),
          KycNotice(
            icon: HugeIcons.strokeRoundedAlert02,
            color: AppColors.error,
            title: 'Expired',
            message:
                '${_list(progress.expiredCredentials)} — renew to keep riding.',
          ),
        ] else if (progress.expiringCredentials.isNotEmpty) ...[
          SizedBox(height: m.gap),
          KycNotice(
            icon: HugeIcons.strokeRoundedTime04,
            color: AppColors.warning,
            title: 'Expiring soon',
            message: '${_list(progress.expiringCredentials)} — renew in time '
                'to avoid a pause in orders.',
          ),
        ],
      ],
    );
  }

  (String, String) _copy() {
    if (progress.isApproved) {
      return ("You're verified", 'Your profile is approved — you can go online.');
    }
    if (!progress.isProfileComplete) {
      final left = progress.outstandingSectionCount;
      return (
        'Complete your profile',
        '$left ${left == 1 ? 'step' : 'steps'} left before we can review '
            'your account. Your progress saves as you go.',
      );
    }
    if (hasSubmitted) {
      return (
        progress.statusLabel ?? 'Under review',
        'We’re checking your details and will notify you once you’re approved.',
      );
    }
    return (
      'Ready for review',
      'Everything is in. Submit your profile so our team can approve you.',
    );
  }

  static String _list(List<String> keys) =>
      keys.map((k) => kycLabel(k).toLowerCase()).join(', ').replaceFirstMapped(
            RegExp(r'^.'),
            (m) => m[0]!.toUpperCase(),
          );
}

/// Every step as one grouped list — a single surface with dividers rather
/// than a card per row.
class KycSectionList extends StatelessWidget {
  const KycSectionList({
    super.key,
    required this.progress,
    required this.onOpen,
  });

  final KycProgress progress;
  final ValueChanged<KycSection> onOpen;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    // A Material surface (not a DecoratedBox) so the rows' ink ripples
    // paint on top of the background instead of under it.
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (i, section) in progress.sections.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            _SectionTile(
              progress: section,
              onTap: () => onOpen(section.section),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.progress, required this.onTap});

  final KycSectionProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final section = progress.section;
    final (color, icon, status) = switch (progress.state) {
      KycSectionState.done => (
          AppColors.success,
          HugeIcons.strokeRoundedCheckmarkCircle02,
          'Complete',
        ),
      KycSectionState.optional => (
          AppColors.textSecondary,
          section.icon,
          'Optional',
        ),
      KycSectionState.actionRequired => (
          AppColors.primary,
          section.icon,
          progress.summary.isEmpty ? 'Needs attention' : '${progress.summary} needed',
        ),
    };

    return Semantics(
      button: true,
      label: '${section.title}, $status',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: m.gutter * 0.75,
            vertical: m.gap * 0.75,
          ),
          child: Row(
            children: [
              Container(
                width: m.iconBadge,
                height: m.iconBadge,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: m.iconBadge * 0.5, color: color),
              ),
              SizedBox(width: m.gutter * 0.75),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: m.bodySize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: m.captionSize,
                        color: progress.needsAction
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                HugeIcons.strokeRoundedArrowRight01,
                size: m.iconBadge * 0.4,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tinted callout — for rejection reasons and credential expiry.
class KycNotice extends StatelessWidget {
  const KycNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Container(
      padding: EdgeInsets.all(m.gutter * 0.75),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(m.radius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: m.iconBadge * 0.45, color: color),
          SizedBox(width: m.gutter * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: m.bodySize,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: m.captionSize,
                    color: AppColors.textPrimary,
                    height: 1.35,
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

/// Shown when `/rider/me` couldn't be loaded and there's nothing cached.
class KycLoadError extends StatelessWidget {
  const KycLoadError({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(m.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              HugeIcons.strokeRoundedAlert02,
              size: m.iconBadge,
              color: AppColors.textHint,
            ),
            SizedBox(height: m.gap),
            Text(
              message ?? "We couldn't load your profile.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: m.bodySize,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: m.gap),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(HugeIcons.strokeRoundedRefresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
