import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/document_upload_card.dart';
import 'kyc_shared_widgets.dart';
import 'package:hugeicons/hugeicons.dart';

class KycStep4DocumentsView extends ConsumerWidget {
  const KycStep4DocumentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycProvider);
    final uploaded = state.uploadedDocCount;
    final total = state.totalDocCount;
    final canProceed = state.hasMinimumUploads;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Documents Uploaded',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$uploaded / $total',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: uploaded == total
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? uploaded / total : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      uploaded == total
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                if (!canProceed) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Please upload required documents to continue.',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: Colors.orange.shade700),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          _GroupTitle(title: 'Identity Documents'),
          const SizedBox(height: 10),
          _DocCard(docKey: KycDocKey.idFront, label: 'National ID (Front)',
              icon: HugeIcons.strokeRoundedCreditCard),
          const SizedBox(height: 10),
          _DocCard(docKey: KycDocKey.idBack, label: 'National ID (Back)',
              icon: HugeIcons.strokeRoundedCreditCard),
          const SizedBox(height: 10),
          _DocCard(docKey: KycDocKey.selfie, label: 'Selfie Photo',
              icon: HugeIcons.strokeRoundedFaceId),

          const SizedBox(height: 20),

          _GroupTitle(title: 'Licence'),
          const SizedBox(height: 10),
          _DocCard(docKey: KycDocKey.licensePhoto, label: 'Driver Licence Photo',
              icon: HugeIcons.strokeRoundedCar01),

          const SizedBox(height: 20),

          _GroupTitle(title: 'Vehicle Documents'),
          const SizedBox(height: 10),
          _DocCard(docKey: KycDocKey.vehicleRegDoc, label: 'Vehicle Registration',
              icon: HugeIcons.strokeRoundedFile01),
          const SizedBox(height: 10),
          _DocCard(docKey: KycDocKey.vehicleInsurance, label: 'Insurance Certificate',
              icon: HugeIcons.strokeRoundedShield01),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(kycProvider.notifier).goToStep(2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppGradientButton(
                  label: 'Review & Submit',
                  onPressed: canProceed
                      ? () => ref.read(kycProvider.notifier).goToStep(4)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String title;

  const _GroupTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DocCard extends ConsumerWidget {
  final String docKey;
  final String label;
  final IconData icon;

  const _DocCard({
    required this.docKey,
    required this.label,
    required this.icon,
  });

  void _pick(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => KycSourcePicker(
        onCamera: () {
          Navigator.pop(context);
          ref
              .read(kycProvider.notifier)
              .pickAndUploadFile(docKey, ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          ref
              .read(kycProvider.notifier)
              .pickAndUploadFile(docKey, ImageSource.gallery);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState =
        ref.watch(kycProvider).uploadStates[docKey] ?? const UploadState();
    return DocumentUploadCard(
      label: label,
      icon: icon,
      uploadState: uploadState,
      onTap: () => _pick(context, ref),
      onRemove: () => ref.read(kycProvider.notifier).removeUpload(docKey),
    );
  }
}
