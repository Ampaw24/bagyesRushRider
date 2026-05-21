import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_date_picker_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/document_upload_card.dart';
import 'kyc_shared_widgets.dart';
import 'package:hugeicons/hugeicons.dart';

class KycStep1IdentityView extends ConsumerStatefulWidget {
  const KycStep1IdentityView({super.key});

  @override
  ConsumerState<KycStep1IdentityView> createState() =>
      _KycStep1IdentityViewState();
}

class _KycStep1IdentityViewState extends ConsumerState<KycStep1IdentityView> {
  final _formKey = GlobalKey<FormState>();
  final _nationalIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    final identity = ref.read(kycProvider).identity;
    _nationalIdCtrl.text = identity.nationalId;
    _addressCtrl.text = identity.address;
    _dob = identity.dateOfBirth;
  }

  @override
  void dispose() {
    _nationalIdCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(kycProvider.notifier).updateIdentity(
          KycIdentityData(
            nationalId: _nationalIdCtrl.text.trim(),
            dateOfBirth: _dob,
            address: _addressCtrl.text.trim(),
          ),
        );
    ref.read(kycProvider.notifier).goToStep(1);
  }

  void _pickDoc(String docKey) {
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
  Widget build(BuildContext context) {
    final uploadStates = ref.watch(kycProvider).uploadStates;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KycSectionHeader(
              icon: HugeIcons.strokeRoundedIdentityCard,
              title: 'Identity Verification',
              subtitle: 'Provide your personal information and ID documents',
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'National ID Number',
              hint: 'e.g. GHA-000000000-0',
              prefixIcon: HugeIcons.strokeRoundedCreditCard,
              controller: _nationalIdCtrl,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().length < 4) {
                  return 'Enter a valid National ID number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppDatePickerField(
              label: 'Date of Birth',
              initialDate: _dob,
              firstDate: DateTime(1940),
              lastDate: DateTime.now()
                  .subtract(const Duration(days: 365 * 18)),
              onDateSelected: (d) => setState(() => _dob = d),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Select your date of birth';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Residential Address',
              hint: 'e.g. 12 High Street, Accra',
              prefixIcon: HugeIcons.strokeRoundedLocation01,
              controller: _addressCtrl,
              maxLines: 2,
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Enter your full residential address';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const KycDocSectionTitle(title: 'ID Documents'),
            const SizedBox(height: 12),

            DocumentUploadCard(
              label: 'National ID (Front)',
              icon: HugeIcons.strokeRoundedCreditCard,
              uploadState:
                  uploadStates[KycDocKey.idFront] ?? const UploadState(),
              onTap: () => _pickDoc(KycDocKey.idFront),
              onRemove: () => ref
                  .read(kycProvider.notifier)
                  .removeUpload(KycDocKey.idFront),
            ),
            const SizedBox(height: 12),

            DocumentUploadCard(
              label: 'National ID (Back)',
              icon: HugeIcons.strokeRoundedCreditCard,
              uploadState:
                  uploadStates[KycDocKey.idBack] ?? const UploadState(),
              onTap: () => _pickDoc(KycDocKey.idBack),
              onRemove: () => ref
                  .read(kycProvider.notifier)
                  .removeUpload(KycDocKey.idBack),
            ),
            const SizedBox(height: 12),

            DocumentUploadCard(
              label: 'Selfie Photo',
              icon: HugeIcons.strokeRoundedFaceId,
              uploadState:
                  uploadStates[KycDocKey.selfie] ?? const UploadState(),
              onTap: () => _pickDoc(KycDocKey.selfie),
              onRemove: () => ref
                  .read(kycProvider.notifier)
                  .removeUpload(KycDocKey.selfie),
            ),

            const SizedBox(height: 32),

            AppGradientButton(
              label: 'Continue',
              onPressed: _saveAndNext,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
