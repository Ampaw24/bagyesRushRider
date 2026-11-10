import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/core/errors/failures.dart';
import 'package:gopady_rider/core/router/app_routes.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';
import 'package:gopady_rider/features/rider/kyc/models/kyc_section.dart';
import 'package:gopady_rider/features/rider/kyc/providers/kyc_providers.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_document_field.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:gopady_rider/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:gopady_rider/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_select_field.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_text_field.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_make_model.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_model_model.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:gopady_rider/features/rider/vehicles/viewmodel/vehicle_catalog_viewmodel.dart';
import 'package:gopady_rider/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:gopady_rider/features/rider/vehicles/views/widgets/vehicle_photos_entry_tile.dart';

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

  /// Signup collects no vehicle details, so a new rider sets type and
  /// plate here. Once the server has them they're shown read-only, as
  /// before — changing either goes through support.
  late final bool _typeLocked = widget.profile.vehicleTypeId != null;
  late final bool _plateLocked = widget.profile.plateNumber != null;
  late int? _typeId = widget.profile.vehicleTypeId;
  final _plateCtrl = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  /// This section is where every new rider first picks type, make and
  /// model — a failed or empty fetch must be recoverable here, not a dead
  /// end.
  Future<void> _loadCatalog() async {
    final catalog = ref.read(vehicleCatalogProvider.notifier);
    if (!_typeLocked) {
      await catalog.loadTypes();
      if (!mounted) return;
      // Only one type on offer (motorbike, today): pick it rather than
      // make the rider choose from a list of one.
      final types = ref.read(vehicleCatalogProvider).types;
      if (_typeId == null && types.length == 1) {
        setState(() => _typeId = types.single.id);
      }
    }
    final typeId = _typeId;
    if (typeId == null || !mounted) return;
    await catalog.loadMakes(typeId);
    if (mounted && _makeId != null) await catalog.loadModels(_makeId!);
  }

  void _selectType(VehicleTypeModel? type) {
    clearServerError('vehicle_type_id');
    if (type == null || type.id == _typeId) return;
    setState(() {
      _typeId = type.id;
      _makeId = null;
      _modelId = null;
    });
    ref.read(vehicleCatalogProvider.notifier).loadMakes(type.id);
  }

  String _typesUnavailableHint(VehicleCatalogState catalog) {
    if (catalog.typesError != null) return catalog.typesError!;
    if (catalog.hasLoadedTypes) return 'No vehicle types available';
    return 'Loading vehicle types…';
  }

  String _makesUnavailableHint(VehicleCatalogState catalog) {
    if (_typeId == null) return 'Select the vehicle type first';
    if (catalog.makesError != null) return catalog.makesError!;
    if (catalog.hasLoadedMakes) return 'No makes listed for this vehicle type';
    return 'Loading makes…';
  }

  String _modelsUnavailableHint(VehicleCatalogState catalog) {
    if (_makeId == null) return 'Select the make first';
    if (catalog.modelsError != null) return catalog.modelsError!;
    if (catalog.hasLoadedModels) return 'No models listed for this make';
    return 'Loading models…';
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
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

    VehicleTypeModel? type;
    for (final t in catalog.types) {
      if (t.id == _typeId) type = t;
    }
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
          if (_typeLocked && _plateLocked)
            KycInfoRow(
              icon: HugeIcons.strokeRoundedMotorbike01,
              label: profile.vehicleTypeLabel ?? 'Vehicle',
              value: profile.plateNumber!,
              note: 'Contact support to change your vehicle type or plate.',
            ),
          if (!_typeLocked) ...[
            AppSelectField<VehicleTypeModel>(
              key: ValueKey('type-${catalog.types.length}-$_typeId'),
              label: 'Vehicle type',
              hint: 'Select vehicle type',
              value: type,
              options: catalog.types,
              labelBuilder: (t) => t.name,
              prefixIcon: HugeIcons.strokeRoundedMotorbike01,
              enabled: catalog.types.isNotEmpty,
              disabledHint: _typesUnavailableHint(catalog),
              onChanged: _selectType,
              validator: (t) =>
                  serverError('vehicle_type_id') ??
                  (t == null ? 'Select the vehicle type' : null),
            ),
            if (catalog.typesError != null ||
                (catalog.hasLoadedTypes && catalog.types.isEmpty))
              _CatalogRetry(onRetry: _loadCatalog),
          ],
          if (!_plateLocked && (type?.requiresPlate ?? true))
            AppTextField(
              label: 'License plate number',
              hint: 'e.g. GR-1234-22',
              prefixIcon: HugeIcons.strokeRoundedIdentityCard,
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(32)],
              onChanged: (_) => clearServerError('plate_number'),
              validator: (v) =>
                  serverError('plate_number') ??
                  ((v ?? '').trim().isEmpty
                      ? 'Enter the license plate number'
                      : null),
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
            disabledHint: _makesUnavailableHint(catalog),
            onChanged: _selectMake,
            validator: (m) =>
                serverError('vehicle_make_id') ??
                (m == null ? 'Select the make' : null),
          ),
          if (catalog.makesError != null ||
              (catalog.hasLoadedMakes && catalog.makes.isEmpty))
            _CatalogRetry(onRetry: _loadCatalog),
          AppSelectField<VehicleModelModel>(
            key: ValueKey('model-$_makeId-${catalog.models.length}'),
            label: 'Model',
            hint: catalog.isLoadingModels ? 'Loading models…' : 'Select model',
            value: model,
            options: catalog.models,
            labelBuilder: (m) => m.name,
            prefixIcon: HugeIcons.strokeRoundedMotorbike02,
            enabled: catalog.models.isNotEmpty,
            disabledHint: _modelsUnavailableHint(catalog),
            onChanged: (m) {
              clearServerError('vehicle_model_id');
              if (m != null) setState(() => _modelId = m.id);
            },
            validator: (m) =>
                serverError('vehicle_model_id') ??
                (m == null ? 'Select the model' : null),
          ),
          if (_makeId != null &&
              (catalog.modelsError != null ||
                  (catalog.hasLoadedModels && catalog.models.isEmpty)))
            _CatalogRetry(
              onRetry: () => ref
                  .read(vehicleCatalogProvider.notifier)
                  .loadModels(_makeId!),
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
    // Normalised: `unique:riders,plate_number` is a raw string comparison,
    // and TextCapitalization doesn't touch pasted text.
    final plate = _plateCtrl.text.trim().toUpperCase();
    submit(
      () async {
        final failure =
            await ref.read(kycActionsProvider.notifier).saveProfile({
          if (!_typeLocked) 'vehicle_type_id': _typeId,
          if (!_plateLocked && plate.isNotEmpty) 'plate_number': plate,
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

/// Re-fetches a catalogue list that failed or came back empty, so the
/// make/model pickers are never a dead end.
class _CatalogRetry extends StatelessWidget {
  const _CatalogRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(HugeIcons.strokeRoundedRefresh),
        label: const Text('Try again'),
      ),
    );
  }
}
