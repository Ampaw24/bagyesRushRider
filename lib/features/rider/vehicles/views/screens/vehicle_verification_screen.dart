import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_hub_widgets.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/viewmodel/vehicle_kyc_viewmodel.dart';
import 'package:delivery_boy/features/rider/vehicles/views/screens/vehicle_verification_camera.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_capture_step_list.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_verification_widgets.dart';

/// Route target for `/dashboard/vehicle-verification`: the rider's vehicle,
/// its verification status, and each photo — take, review, upload, retake.
class VehicleVerificationScreen extends ConsumerStatefulWidget {
  const VehicleVerificationScreen({super.key});

  @override
  ConsumerState<VehicleVerificationScreen> createState() =>
      _VehicleVerificationScreenState();
}

class _VehicleVerificationScreenState
    extends ConsumerState<VehicleVerificationScreen> {
  /// Photos went up during this visit — a rejected account then needs a
  /// resubmission, not another round of photos.
  bool _uploadedThisVisit = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(riderMeProfileProvider).profile == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(riderMeProfileProvider.notifier).load(),
      );
    }
  }

  Future<void> _capture(List<VehicleCaptureStep> steps) async {
    final view = ref.read(vehicleVerificationProvider);
    if (view == null || view.isUploading || steps.isEmpty) return;
    final notifier = ref.read(vehicleKycProvider.notifier);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VehicleVerificationCamera(
          kind: view.vehicle.kind,
          totalSteps: view.steps.length,
          shots: [
            for (final step in steps)
              VehicleCameraShot(
                requirement: step.requirement,
                number: view.stepNumberOf(step.type),
              ),
          ],
          onCaptured: notifier.recordCapture,
        ),
      ),
    );
  }

  Future<void> _upload({VehicleCaptureType? only}) async {
    final failure = await ref
        .read(vehicleKycProvider.notifier)
        .uploadPending(only: only == null ? null : {only});
    if (!mounted) return;
    if (failure == null) {
      HapticFeedback.lightImpact();
      setState(() => _uploadedThisVisit = true);
      return;
    }
    // The router is already on its way to the login screen.
    if (failure is SessionExpiredFailure) return;
    CustomDialog.showError(
      context: context,
      title: 'Upload Failed',
      subtitle: '${failure.message}\n\nYour photo is still saved on this '
          'phone — retry the upload or retake it.',
    );
  }

  /// The one obvious next step for where the rider is.
  (String, VoidCallback) _primaryAction(VehicleVerificationView view) {
    final missing = view.missingSteps;
    if (missing.isNotEmpty) {
      return (
        missing.length == view.steps.length
            ? 'Take photos'
            : 'Take remaining photos',
        () => _capture(missing),
      );
    }
    final pending = view.pendingUploads.length;
    if (pending > 0) {
      return ('Upload $pending ${pending == 1 ? 'photo' : 'photos'}', _upload);
    }
    if (view.status == VehicleVerificationStatus.actionRequired &&
        !_uploadedThisVisit) {
      return ('Retake photos', () => _capture(view.steps));
    }
    return ('Done', () => Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(vehicleVerificationProvider);
    if (view == null) return const _LoadingProfile();

    final m = KycMetrics.of(context);
    final vehicle = view.vehicle;
    final (label, onPressed) = _primaryAction(view);

    return PopScope(
      canPop: !view.isUploading,
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Vehicle verification'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: m.gutter,
                    vertical: m.gap,
                  ),
                  child: KycContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KycInfoRow(
                          icon: vehicle.kind.icon,
                          label: vehicle.details.isEmpty
                              ? vehicle.kind.label
                              : vehicle.details,
                          value: vehicle.displayName,
                          note: vehicle.plateNumber == null
                              ? null
                              : 'Plate ${vehicle.plateNumber}',
                        ),
                        SizedBox(height: m.gap),
                        VehicleStatusNotice(view: view),
                        SizedBox(height: m.gap),
                        const VehicleLiveCaptureNote(),
                        SizedBox(height: m.gap),
                        KycSubheading(
                          'Photos',
                          caption: '${view.uploadedCount} of '
                              '${view.steps.length} uploaded',
                        ),
                        SizedBox(height: m.gap * 0.5),
                        VehicleCaptureStepList(
                          view: view,
                          onCapture: (step) => _capture([step]),
                          onRetry: (type) => _upload(only: type),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              KycActionBar(
                label: label,
                onPressed: onPressed,
                isBusy: view.isUploading,
                metrics: m,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Before `/rider/me` arrives, or when it couldn't be loaded.
class _LoadingProfile extends ConsumerWidget {
  const _LoadingProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riderMeProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Vehicle verification'),
      ),
      body: state.status == RiderMeProfileStatus.error
          ? KycLoadError(
              message: state.errorMessage,
              onRetry: () => ref.read(riderMeProfileProvider.notifier).load(),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
