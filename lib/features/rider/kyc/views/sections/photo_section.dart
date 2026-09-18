import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/models/upload_state.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_avatar_providers.dart';
import 'package:delivery_boy/features/rider/profile/views/screens/rider_selfie_capture_screen.dart';
import 'package:delivery_boy/features/rider/shared_widgets/rider_avatar.dart';

class PhotoSection extends ConsumerStatefulWidget {
  const PhotoSection({super.key});

  @override
  ConsumerState<PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends ConsumerState<PhotoSection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.photo;

  Future<void> _capture() async {
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => const RiderSelfieCaptureScreen()),
    );
    if (file == null || !mounted) return;

    final failure =
        await ref.read(kycUploadsProvider.notifier).uploadPhoto(file.path);
    if (!mounted) return;
    if (failure != null) {
      CustomDialog.showError(
        context: context,
        title: 'Upload Failed',
        subtitle: failure.message,
      );
      return;
    }
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final photoUrl = ref.watch(riderAvatarUrlProvider);
    final upload =
        ref.watch(kycUploadsProvider.select((u) => u[kycPhotoUploadKey]));
    final isUploading = upload?.isUploading ?? false;
    final hasPhoto = photoUrl != null || (upload?.isDone ?? false);
    final radius = m.iconBadge * 1.6;

    return KycSectionLayout(
      section: section,
      primaryLabel: hasPhoto ? 'Continue' : 'Take selfie',
      isBusy: isUploading,
      onPrimary: hasPhoto ? continueToNextStep : _capture,
      secondary: hasPhoto
          ? TextButton.icon(
              onPressed: isUploading ? null : _capture,
              icon: const Icon(HugeIcons.strokeRoundedCamera01),
              label: const Text('Retake selfie'),
            )
          : null,
      children: [
        Center(
          child: upload?.localPath != null
              ? CircleAvatar(
                  radius: radius,
                  backgroundImage: FileImage(File(upload!.localPath!)),
                )
              : RiderAvatar(
                  radius: radius,
                  imageUrl: photoUrl,
                  backgroundColor: AppColors.surfaceVariant,
                  placeholder: Icon(
                    HugeIcons.strokeRoundedFaceId,
                    size: radius * 0.8,
                    color: AppColors.textHint,
                  ),
                ),
        ),
        if (upload?.progress == UploadProgress.failed)
          Text(
            upload!.errorMessage ?? "Your photo didn't upload.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: m.captionSize, color: AppColors.error),
          ),
        for (final tip in const [
          'Face the camera in good, even light.',
          'Remove hats, sunglasses and face coverings.',
          'The camera takes the photo once your face is steady.',
        ])
          _Tip(text: tip, metrics: m),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text, required this.metrics});

  final String text;
  final KycMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          HugeIcons.strokeRoundedCheckmarkCircle02,
          size: metrics.iconBadge * 0.4,
          color: AppColors.success,
        ),
        SizedBox(width: metrics.gutter * 0.5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: metrics.bodySize,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
