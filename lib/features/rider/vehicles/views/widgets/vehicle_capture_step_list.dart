import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_verification_widgets.dart';

/// Every capture step on one grouped surface, each with its photo, state
/// and the actions that apply to it.
class VehicleCaptureStepList extends StatelessWidget {
  const VehicleCaptureStepList({
    super.key,
    required this.view,
    required this.onCapture,
    required this.onRetry,
  });

  final VehicleVerificationView view;
  final ValueChanged<VehicleCaptureStep> onCapture;
  final ValueChanged<VehicleCaptureType> onRetry;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (i, step) in view.steps.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            _StepTile(
              step: step,
              icon: view.vehicle.kind.icon,
              enabled: !view.isUploading,
              onCapture: () => onCapture(step),
              onRetry: () => onRetry(step.type),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.icon,
    required this.enabled,
    required this.onCapture,
    required this.onRetry,
  });

  final VehicleCaptureStep step;
  final IconData icon;
  final bool enabled;
  final VoidCallback onCapture;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final requirement = step.requirement;
    final state = step.state;

    return Padding(
      padding: EdgeInsets.all(m.gutter * 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehiclePhotoThumbnail(
                size: m.iconBadge * 1.5,
                placeholderIcon: icon,
                localPath: step.draft?.localPath,
                url: step.remoteUrl,
              ),
              SizedBox(width: m.gutter * 0.75),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requirement.required
                          ? requirement.title
                          : '${requirement.title} (optional)',
                      style: TextStyle(
                        fontSize: m.bodySize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      requirement.instruction,
                      style: TextStyle(
                        fontSize: m.captionSize,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: m.gap * 0.3),
                    _StepStatus(step: step),
                  ],
                ),
              ),
            ],
          ),
          if (state != VehicleCaptureStepState.uploading)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: m.gutter * 0.25,
              children: [
                if (state == VehicleCaptureStepState.failed)
                  TextButton.icon(
                    onPressed: enabled ? onRetry : null,
                    icon: const Icon(HugeIcons.strokeRoundedRefresh),
                    label: const Text('Retry upload'),
                  ),
                TextButton.icon(
                  onPressed: enabled ? onCapture : null,
                  icon: const Icon(HugeIcons.strokeRoundedCamera01),
                  label: Text(
                    state == VehicleCaptureStepState.missing
                        ? 'Take photo'
                        : 'Retake',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StepStatus extends StatelessWidget {
  const _StepStatus({required this.step});

  final VehicleCaptureStep step;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final draft = step.draft;
    final percent = draft?.uploadFraction == null
        ? ''
        : ' ${(draft!.uploadFraction! * 100).round()}%';

    final (IconData? icon, String text, Color color) = switch (step.state) {
      VehicleCaptureStepState.missing => (
          HugeIcons.strokeRoundedCamera01,
          'Not taken yet',
          AppColors.textSecondary,
        ),
      VehicleCaptureStepState.captured => (
          HugeIcons.strokeRoundedImage01,
          'Ready to upload',
          AppColors.info,
        ),
      VehicleCaptureStepState.uploading => (
          null,
          'Uploading…$percent',
          AppColors.primary,
        ),
      VehicleCaptureStepState.failed => (
          HugeIcons.strokeRoundedAlert02,
          '${draft?.errorMessage ?? 'Upload failed.'} '
              'Your photo is still saved on this phone.',
          AppColors.error,
        ),
      VehicleCaptureStepState.uploaded => (
          HugeIcons.strokeRoundedCheckmarkCircle02,
          'Uploaded',
          AppColors.success,
        ),
    };

    final iconSize = m.captionSize * 1.2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: iconSize,
          child: icon != null
              ? Icon(icon, size: iconSize, color: color)
              : CircularProgressIndicator(
                  strokeWidth: iconSize * 0.15,
                  value: draft?.uploadFraction,
                  color: color,
                ),
        ),
        SizedBox(width: m.gutter * 0.3),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: m.captionSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
