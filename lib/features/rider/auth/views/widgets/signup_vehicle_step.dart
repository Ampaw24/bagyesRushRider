import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:gopady_rider/features/rider/shared_widgets/app_select_field.dart';
import 'package:gopady_rider/features/rider/shared_widgets/app_text_field.dart';
import 'package:gopady_rider/features/rider/vehicles/model/vehicle_type_model.dart';
import 'package:gopady_rider/features/rider/vehicles/viewmodel/vehicle_catalog_viewmodel.dart';

/// The one vehicle step `/register` still needs: `vehicle_type_id` and
/// `plate_number`. Make, model, year and colour are collected later, in the
/// KYC vehicle section.
///
/// The type comes from `GET /vehicle-types`; with only one on offer the
/// signup screen pre-selects it, so in practice the rider types the plate.
class SignupVehicleStep extends ConsumerWidget {
  const SignupVehicleStep({
    super.key,
    required this.formKey,
    required this.selectedType,
    required this.onTypeChanged,
    required this.plateController,
    required this.serverError,
    required this.onFieldEdited,
    required this.onRetry,
    required this.horizontalPadding,
    required this.screenHeight,
  });

  final GlobalKey<FormState> formKey;
  final VehicleTypeModel? selectedType;
  final ValueChanged<VehicleTypeModel> onTypeChanged;
  final TextEditingController plateController;

  /// The server's message for a `/register` field, until the rider edits it.
  final String? Function(String field) serverError;
  final ValueChanged<String> onFieldEdited;
  final VoidCallback onRetry;
  final double horizontalPadding;
  final double screenHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(vehicleCatalogProvider);
    final h = screenHeight;
    final requiresPlate = selectedType?.requiresPlate ?? true;
    final typesUnavailable = catalog.typesError != null ||
        (catalog.hasLoadedTypes && catalog.types.isEmpty);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: h * 0.01),
            AppSelectField<VehicleTypeModel>(
              key: ValueKey('type-${catalog.types.length}-${selectedType?.id}'),
              label: 'Vehicle type',
              hint: 'Select your vehicle type',
              sheetTitle: 'Select Vehicle Type',
              prefixIcon: HugeIcons.strokeRoundedMotorbike01,
              value: selectedType,
              options: catalog.types,
              labelBuilder: (t) => t.name,
              enabled: catalog.types.isNotEmpty,
              disabledHint: catalog.typesError ??
                  (catalog.hasLoadedTypes
                      ? 'No vehicle types available'
                      : 'Loading vehicle types…'),
              onChanged: (t) {
                onFieldEdited('vehicle_type_id');
                if (t != null) onTypeChanged(t);
              },
              validator: (t) =>
                  serverError('vehicle_type_id') ??
                  serverError('vehicle_type') ??
                  (t == null ? 'Select the vehicle you will be riding' : null),
            ),
            if (typesUnavailable)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(HugeIcons.strokeRoundedRefresh),
                  label: const Text('Try again'),
                ),
              ),
            if (requiresPlate) ...[
              SizedBox(height: h * 0.02),
              AppTextField(
                label: 'License Plate Number',
                hint: 'e.g. GR-1234-22',
                prefixIcon: HugeIcons.strokeRoundedIdentityCard,
                controller: plateController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(32)],
                onChanged: (_) => onFieldEdited('plate_number'),
                validator: (v) =>
                    serverError('plate_number') ??
                    ((v ?? '').trim().isEmpty
                        ? 'Please enter the license plate number'
                        : null),
              ),
            ],
            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }
}
