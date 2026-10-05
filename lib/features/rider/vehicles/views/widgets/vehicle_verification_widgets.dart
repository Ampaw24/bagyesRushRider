import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_hub_widgets.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification_configuration.dart';

/// How a [VehicleVerificationStatus] reads on screen. Every status has an
/// icon and words, never colour alone.
class VehicleStatusStyle {
  final String label;
  final String message;
  final IconData icon;
  final Color color;

  const VehicleStatusStyle._(this.label, this.message, this.icon, this.color);

  factory VehicleStatusStyle.of(
    VehicleVerificationStatus status,
    VehicleKind kind, {
    String? rejectionReason,
  }) {
    final noun = kind.noun;
    return switch (status) {
      VehicleVerificationStatus.photosRequired => VehicleStatusStyle._(
          'Verification required',
          'Take live photos of your $noun to verify it for deliveries.',
          HugeIcons.strokeRoundedCamera01,
          AppColors.primary,
        ),
      VehicleVerificationStatus.pendingReview => VehicleStatusStyle._(
          'Pending review',
          'Our team reviews your $noun photos with your profile. '
              "We'll notify you once you're approved.",
          HugeIcons.strokeRoundedTime04,
          AppColors.warning,
        ),
      VehicleVerificationStatus.verified => VehicleStatusStyle._(
          'Verified',
          'Your $noun is verified for deliveries.',
          HugeIcons.strokeRoundedCheckmarkCircle02,
          AppColors.success,
        ),
      VehicleVerificationStatus.actionRequired => VehicleStatusStyle._(
          'Action required',
          rejectionReason ??
              "Our team couldn't approve your profile. Retake your $noun "
                  'photos if they were unclear, then resubmit.',
          HugeIcons.strokeRoundedCancelCircle,
          AppColors.error,
        ),
    };
  }
}

/// The status as a callout, for the top of the verification screen.
class VehicleStatusNotice extends StatelessWidget {
  const VehicleStatusNotice({super.key, required this.view});

  final VehicleVerificationView view;

  @override
  Widget build(BuildContext context) {
    final style = VehicleStatusStyle.of(
      view.status,
      view.vehicle.kind,
      rejectionReason: view.rejectionReason,
    );
    return KycNotice(
      icon: style.icon,
      color: style.color,
      title: style.label,
      message: style.message,
    );
  }
}

/// Why there's no "choose from gallery" option.
class VehicleLiveCaptureNote extends StatelessWidget {
  const VehicleLiveCaptureNote({super.key});

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          HugeIcons.strokeRoundedSquareLock02,
          size: m.iconBadge * 0.4,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: m.gutter * 0.5),
        Expanded(
          child: Text(
            'For security, vehicle photos must be taken live with your '
            "camera. Photos from your gallery can't be used.",
            style: TextStyle(
              fontSize: m.captionSize,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// A square vehicle photo: the local capture when there is one, otherwise
/// the server's, otherwise a placeholder. Decoded at display size, never at
/// the camera's full resolution.
class VehiclePhotoThumbnail extends StatelessWidget {
  const VehiclePhotoThumbnail({
    super.key,
    required this.size,
    required this.placeholderIcon,
    this.localPath,
    this.url,
  });

  final double size;
  final IconData placeholderIcon;
  final String? localPath;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final placeholder = Center(
      child: Icon(placeholderIcon, size: size * 0.4, color: AppColors.textHint),
    );
    Widget fallback(BuildContext _, Object __, StackTrace? ___) => placeholder;

    final path = localPath;
    final remote = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(m.radius * 0.75),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: AppColors.surfaceVariant,
          child: path != null
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  errorBuilder: fallback,
                )
              : remote != null
                  ? Image.network(
                      remote,
                      fit: BoxFit.cover,
                      cacheWidth: cacheWidth,
                      frameBuilder: (_, child, frame, sync) =>
                          sync || frame != null ? child : placeholder,
                      errorBuilder: fallback,
                    )
                  : placeholder,
        ),
      ),
    );
  }
}
