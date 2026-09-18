import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/models/upload_state.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/document_upload_card.dart';

/// One verification document, uploaded the moment it's picked.
///
/// Shows the local upload while it's in flight (or failed), and otherwise
/// the server's `documents[slug].uploaded` — so a document uploaded last
/// week still shows as done.
class KycDocumentField extends ConsumerWidget {
  const KycDocumentField({
    super.key,
    required this.slug,
    this.required = true,
  });

  final String slug;
  final bool required;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(kycUploadsProvider.select((m) => m[slug]));
    final onServer = ref.watch(riderMeProfileProvider
        .select((s) => s.profile?.documents[slug]?.uploaded ?? false));

    final upload = local ??
        (onServer
            ? const UploadState(progress: UploadProgress.done)
            : const UploadState());

    return DocumentUploadCard(
      label: required ? kycLabel(slug) : '${kycLabel(slug)} (optional)',
      icon: KycSection.forDocument(slug).icon,
      uploadState: upload,
      onTap: () => _pickAndUpload(context, ref),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.scaffold,
      showDragHandle: true,
      builder: (_) => _SourceSheet(title: kycLabel(slug)),
    );
    if (source == null) return;

    // Capped so a full-resolution camera shot doesn't trip the server's
    // upload size limit.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (picked == null) return;

    final failure = await ref
        .read(kycUploadsProvider.notifier)
        .uploadDocument(slug, picked.path);
    if (!context.mounted) return;

    if (failure == null) {
      HapticFeedback.lightImpact();
    } else {
      CustomDialog.showError(
        context: context,
        title: 'Upload Failed',
        subtitle: failure.message,
      );
    }
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(m.gutter, 0, m.gutter, m.gap),
        child: KycContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: m.titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Make sure every corner is visible and the text is readable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: m.captionSize,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: m.gap),
              _SourceOption(
                icon: HugeIcons.strokeRoundedCamera01,
                label: 'Take a photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              _SourceOption(
                icon: HugeIcons.strokeRoundedImage01,
                label: 'Choose from gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: m.iconBadge * 0.5),
      title: Text(label, style: TextStyle(fontSize: m.bodySize)),
      onTap: onTap,
    );
  }
}
