import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_document_field.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_select_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_catalog_viewmodel.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_photos_entry_tile.dart';

const _ownershipOptions = {
  'owned': 'I own this vehicle',
  'authorised': "I'm authorised by the owner",
};

class VehicleSection extends ConsumerStatefulWidget {
  const VehicleSection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<VehicleSection> createState() => _VehicleSectionState();
}

class _VehicleSectionState extends ConsumerState<VehicleSection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.vehicle;

  late int? _makeId = widget.profile.vehicleMakeId;
  late int? _modelId = widget.profile.vehicleModelId;
  late String _ownership = widget.profile.vehicleOwnership ?? 'owned';
  late final _colourCtrl =
      TextEditingController(text: widget.profile.vehicleColour);
  late final _yearCtrl =
      TextEditingController(text: widget.profile.vehicleYear?.toString());

  /// Set when the old vehicle's photos couldn't be removed after a change.
  Failure? _photoClearFailure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final typeId = widget.profile.vehicleTypeId;
      if (typeId == null) return;
      final catalog = ref.read(vehicleCatalogProvider.notifier);
      await catalog.loadMakes(typeId);
      if (_makeId != null) await catalog.loadModels(_makeId!);
    });
  }

  @override
  void dispose() {
    _colourCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _selectMake(VehicleMakeModel? make) {
    clearServerError('vehicle_make_id');
    if (make == null || make.id == _makeId) return;
    setState(() {
      _makeId = make.id;
      _modelId = null;
    });
    ref.read(vehicleCatalogProvider.notifier).loadModels(make.id);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));
    final catalog = ref.watch(vehicleCatalogProvider);
    final profile = widget.profile;

    VehicleMakeModel? make;
    for (final m in catalog.makes) {
      if (m.id == _makeId) make = m;
    }
    VehicleModelModel? model;
    for (final m in catalog.models) {
      if (m.id == _modelId) model = m;
    }

    final needsAuthorisation = _ownership == 'authorised' ||
        (profile.documents['vehicle_authorisation']?.required ?? false);

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel: 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          KycInfoRow(
            icon: HugeIcons.strokeRoundedMotorbike01,
            label: profile.vehicleTypeLabel ?? 'Vehicle',
            value: profile.plateNumber ?? 'No plate',
            note: 'Set at registration — contact support to change it.',
          ),
          // Keyed on the loaded options: the select only reads its value
          // once, and makes/models arrive after the first build.
          AppSelectField<VehicleMakeModel>(
            key: ValueKey('make-${catalog.makes.length}'),
            label: 'Make',
            hint: catalog.isLoadingMakes ? 'Loading makes…' : 'Select make',
            value: make,
            options: catalog.makes,
            labelBuilder: (m) => m.name,
            prefixIcon: HugeIcons.strokeRoundedMotorbike01,
            enabled: catalog.makes.isNotEmpty,
            disabledHint: catalog.makesError ?? 'Loading makes…',
            onChanged: _selectMake,
            validator: (m) =>
                serverError('vehicle_make_id') ??
                (m == null ? 'Select the make' : null),
          ),
          AppSelectField<VehicleModelModel>(
            key: ValueKey('model-$_makeId-${catalog.models.length}'),
            label: 'Model',
            hint: catalog.isLoadingModels ? 'Loading models…' : 'Select model',
            value: model,
            options: catalog.models,
            labelBuilder: (m) => m.name,
            prefixIcon: HugeIcons.strokeRoundedMotorbike02,
            enabled: catalog.models.isNotEmpty,
            disabledHint: _makeId == null
                ? 'Select the make first'
                : (catalog.modelsError ?? 'Loading models…'),
            onChanged: (m) {
              clearServerError('vehicle_model_id');
              if (m != null) setState(() => _modelId = m.id);
            },
            validator: (m) =>
                serverError('vehicle_model_id') ??
                (m == null ? 'Select the model' : null),
          ),
          AppTextField(
            label: 'Colour (optional)',
            prefixIcon: HugeIcons.strokeRoundedPaintBoard,
            controller: _colourCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => clearServerError('vehicle_colour'),
            validator: (_) => serverError('vehicle_colour'),
          ),
          AppTextField(
            label: 'Year (optional)',
            hint: 'e.g. 2021',
            prefixIcon: HugeIcons.strokeRoundedCalendar03,
            controller: _yearCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => clearServerError('vehicle_year'),
            validator: _validateYear,
          ),
          AppSelectField<String>(
            label: 'Ownership',
            value: _ownership,
            options: _ownershipOptions.keys.toList(),
            labelBuilder: (o) => _ownershipOptions[o]!,
            prefixIcon: HugeIcons.strokeRoundedUserGroup,
            onChanged: (o) {
              clearServerError('vehicle_ownership');
              if (o != null) setState(() => _ownership = o);
            },
            validator: (_) => serverError('vehicle_ownership'),
          ),
          const KycSubheading(
            'Vehicle photos',
            caption: 'Taken live with your camera.',
          ),
          const VehiclePhotosEntryTile(),
          const KycSubheading('Vehicle documents'),
          const KycDocumentField(slug: 'vehicle_registration'),
          if (needsAuthorisation)
            const KycDocumentField(slug: 'vehicle_authorisation'),
        ],
      ),
    );
  }

  String? _validateYear(String? value) {
    final server = serverError('vehicle_year');
    if (server != null) return server;
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    final latest = DateTime.now().year + 1;
    if (year == null || year < 1980 || year > latest) {
      return 'Enter a year between 1980 and $latest';
    }
    return null;
  }

  /// A different make or model is a different vehicle: its photos — and
  /// any verification they earned — must not carry over.
  bool get _changesVerifiedVehicle {
    final profile = widget.profile;
    if (profile.vehiclePhotos.isEmpty) return false;
    return (profile.vehicleMakeId != null &&
            _makeId != profile.vehicleMakeId) ||
        (profile.vehicleModelId != null && _modelId != profile.vehicleModelId);
  }

  Future<void> _save() async {
    final changesVehicle = _changesVerifiedVehicle;
    if (changesVehicle && !await _confirmVehicleChange()) return;

    final colour = _colourCtrl.text.trim();
    final year = int.tryParse(_yearCtrl.text.trim());
    submit(
      () async {
        final failure =
            await ref.read(kycActionsProvider.notifier).saveProfile({
          'vehicle_make_id': _makeId,
          'vehicle_model_id': _modelId,
          'vehicle_ownership': _ownership,
          if (colour.isNotEmpty) 'vehicle_colour': colour,
          if (year != null) 'vehicle_year': year,
        });
        if (failure != null || !changesVehicle) return failure;
        // The new details are saved either way; a failure here is reported
        // once the rider is on the photos screen, where retaking fixes it.
        _photoClearFailure = await ref
            .read(vehicleKycProvider.notifier)
            .clearPhotosForVehicleChange();
        return null;
      },
      onSaved: changesVehicle ? _openVehiclePhotos : null,
    );
  }

  Future<bool> _confirmVehicleChange() async {
    var confirmed = false;
    await CustomDialog.showConfirmation(
      context: context,
      title: 'Change vehicle?',
      subtitle: 'Changing your vehicle requires new verification before it '
          'can be used for deliveries. You will need to take new photos of '
          'it.',
      confirmText: 'Continue',
      icon: HugeIcons.strokeRoundedMotorbike01,
      onConfirm: () => confirmed = true,
    );
    return confirmed;
  }

  void _openVehiclePhotos() {
    final failure = _photoClearFailure;
    _photoClearFailure = null;
    context.pushReplacement(AppRoutes.vehicleVerification);
    if (failure != null) {
      CustomDialog.showWarning(
        context: context,
        title: 'Retake your photos',
        subtitle: "We couldn't remove the photos of your previous vehicle "
            '(${failure.message}). Retake each photo so they show your new '
            'one.',
      );
    }
  }
}
