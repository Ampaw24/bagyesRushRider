import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_date_picker_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/document_upload_card.dart';
import 'kyc_shared_widgets.dart';

class KycStep2LicenceView extends ConsumerStatefulWidget {
  const KycStep2LicenceView({super.key});

  @override
  ConsumerState<KycStep2LicenceView> createState() =>
      _KycStep2LicenceViewState();
}

class _KycStep2LicenceViewState extends ConsumerState<KycStep2LicenceView> {
  final _formKey = GlobalKey<FormState>();
  final _licenceNoCtrl = TextEditingController();
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final license = ref.read(kycProvider).license;
    _licenceNoCtrl.text = license.licenseNumber;
    _expiryDate = license.expiryDate;
  }

  @override
  void dispose() {
    _licenceNoCtrl.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(kycProvider.notifier).updateLicense(
          KycLicenseData(
            licenseNumber: _licenceNoCtrl.text.trim(),
            expiryDate: _expiryDate,
          ),
        );
    ref.read(kycProvider.notifier).goToStep(2);
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
              icon: Icons.drive_eta_outlined,
              title: 'Driver Licence',
              subtitle: 'Provide your driver licence details',
            ),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Driver Licence Number',
              hint: 'e.g. DL-000000',
              prefixIcon: Icons.badge_outlined,
              controller: _licenceNoCtrl,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().length < 4) {
                  return 'Enter a valid licence number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppDatePickerField(
              label: 'Licence Expiry Date',
              initialDate: _expiryDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
              onDateSelected: (d) => setState(() => _expiryDate = d),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Select the licence expiry date';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const KycDocSectionTitle(title: 'Licence Document'),
            const SizedBox(height: 12),

            DocumentUploadCard(
              label: 'Driver Licence Photo',
              icon: Icons.drive_eta_outlined,
              uploadState:
                  uploadStates[KycDocKey.licensePhoto] ?? const UploadState(),
              onTap: () => _pickDoc(KycDocKey.licensePhoto),
              onRemove: () => ref
                  .read(kycProvider.notifier)
                  .removeUpload(KycDocKey.licensePhoto),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(kycProvider.notifier).goToStep(0),
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
                    label: 'Continue',
                    onPressed: _saveAndNext,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
