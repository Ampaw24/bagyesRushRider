import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_dropdown_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/document_upload_card.dart';
import 'kyc_shared_widgets.dart';
import 'package:hugeicons/hugeicons.dart';

const _vehicleTypes = [
  'Motorcycle',
  'Bicycle',
  'Car',
  'Tricycle',
  'Van',
];

class KycStep3VehicleView extends ConsumerStatefulWidget {
  const KycStep3VehicleView({super.key});

  @override
  ConsumerState<KycStep3VehicleView> createState() =>
      _KycStep3VehicleViewState();
}

class _KycStep3VehicleViewState extends ConsumerState<KycStep3VehicleView> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String? _vehicleType;

  @override
  void initState() {
    super.initState();
    final vehicle = ref.read(kycProvider).vehicle;
    _vehicleType =
        vehicle.vehicleType.isNotEmpty ? vehicle.vehicleType : null;
    _brandCtrl.text = vehicle.brand;
    _modelCtrl.text = vehicle.model;
    _plateCtrl.text = vehicle.plateNumber;
    _colorCtrl.text = vehicle.color;
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(kycProvider.notifier).updateVehicle(
          KycVehicleData(
            vehicleType: _vehicleType ?? '',
            brand: _brandCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
            plateNumber: _plateCtrl.text.trim(),
            color: _colorCtrl.text.trim(),
          ),
        );
    ref.read(kycProvider.notifier).goToStep(3);
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
              icon: HugeIcons.strokeRoundedMotorbike01,
              title: 'Vehicle Information',
              subtitle: 'Tell us about the vehicle you deliver with',
            ),
            const SizedBox(height: 20),

            AppDropdownField<String>(
              label: 'Vehicle Type',
              hint: 'Select vehicle type',
              prefixIcon: HugeIcons.strokeRoundedCar01,
              value: _vehicleType,
              items: _vehicleTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _vehicleType = v),
              validator: (v) =>
                  v == null ? 'Select your vehicle type' : null,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Vehicle Brand',
              hint: 'e.g. Honda, Yamaha',
              prefixIcon: HugeIcons.strokeRoundedIdentityCard,
              controller: _brandCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter vehicle brand'
                  : null,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Vehicle Model',
              hint: 'e.g. CB125F, NMAX',
              prefixIcon: HugeIcons.strokeRoundedChart01,
              controller: _modelCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter vehicle model'
                  : null,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Plate Number',
              hint: 'e.g. GR-1234-22',
              prefixIcon: HugeIcons.strokeRoundedTicket01,
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter plate number'
                  : null,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Vehicle Color',
              hint: 'e.g. Red, Black',
              prefixIcon: HugeIcons.strokeRoundedColors,
              controller: _colorCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter vehicle color'
                  : null,
            ),

            const SizedBox(height: 24),
            const KycDocSectionTitle(title: 'Vehicle Documents'),
            const SizedBox(height: 12),

            DocumentUploadCard(
              label: 'Vehicle Registration Document',
              icon: HugeIcons.strokeRoundedFile01,
              uploadState: uploadStates[KycDocKey.vehicleRegDoc] ??
                  const UploadState(),
              onTap: () => _pickDoc(KycDocKey.vehicleRegDoc),
              onRemove: () => ref
                  .read(kycProvider.notifier)
                  .removeUpload(KycDocKey.vehicleRegDoc),
            ),
            const SizedBox(height: 12),

            DocumentUploadCard(
              label: 'Motor Insurance Certificate',
              icon: HugeIcons.strokeRoundedShield01,
              uploadState: uploadStates[KycDocKey.vehicleInsurance] ??
                  const UploadState(),
              onTap: () => _pickDoc(KycDocKey.vehicleInsurance),
              onRemove: () => ref
                  .read(kycProvider.notifier)
                  .removeUpload(KycDocKey.vehicleInsurance),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(kycProvider.notifier).goToStep(1),
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
