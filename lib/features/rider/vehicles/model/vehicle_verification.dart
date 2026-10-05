import 'package:equatable/equatable.dart';

import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/vehicles/model/rider_vehicle.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification_configuration.dart';

/// Where the rider's vehicle stands, as far as the app can tell.
///
/// `/rider/me` carries no vehicle-specific review status — only the
/// account's `status` and `rejection_reason` — so this is derived from those
/// plus which photos the server holds. It never reads "verified" just
/// because an upload succeeded: that takes the server approving the account.
enum VehicleVerificationStatus {
  /// One or more required photos aren't on the server.
  photosRequired,

  /// Every required photo is on the server; the account isn't approved yet.
  pendingReview,

  /// The server approved the account with these photos on file.
  verified,

  /// The server rejected the account — see the rejection reason.
  actionRequired;

  static VehicleVerificationStatus derive({
    required RiderMeProfileModel profile,
    required bool hasRequiredPhotos,
  }) {
    final approved = profile.canGoOnline || profile.status == 'approved';
    final rejected =
        profile.status == 'rejected' || profile.rejectionReason != null;
    if (rejected && !approved) return actionRequired;
    if (!hasRequiredPhotos) return photosRequired;
    return approved ? verified : pendingReview;
  }
}

enum VehicleCaptureProgress { captured, uploading, failed }

/// A photo taken in this session that the server doesn't have yet.
///
/// Only a file path is held — never image bytes — and the file is deleted
/// once the upload succeeds or the photo is retaken.
class VehicleCaptureDraft extends Equatable {
  final String localPath;
  final VehicleCaptureProgress progress;

  /// 0–1 while uploading, when the request reports it.
  final double? uploadFraction;
  final String? errorMessage;

  const VehicleCaptureDraft({
    required this.localPath,
    this.progress = VehicleCaptureProgress.captured,
    this.uploadFraction,
    this.errorMessage,
  });

  /// The same photo at a new stage; fraction and error describe only that
  /// stage, so they are cleared unless given.
  VehicleCaptureDraft withProgress(
    VehicleCaptureProgress progress, {
    double? uploadFraction,
    String? errorMessage,
  }) =>
      VehicleCaptureDraft(
        localPath: localPath,
        progress: progress,
        uploadFraction: uploadFraction,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [localPath, progress, uploadFraction, errorMessage];
}

enum VehicleCaptureStepState { missing, captured, uploading, failed, uploaded }

/// One capture requirement joined with the server's photo and any local
/// draft.
class VehicleCaptureStep extends Equatable {
  final VehicleCaptureRequirement requirement;

  /// The photo the server holds for this step, if any.
  final String? remoteUrl;
  final VehicleCaptureDraft? draft;

  const VehicleCaptureStep({
    required this.requirement,
    this.remoteUrl,
    this.draft,
  });

  VehicleCaptureType get type => requirement.type;

  /// A local draft outranks the server photo: it's the one about to replace
  /// it.
  VehicleCaptureStepState get state => switch (draft?.progress) {
        VehicleCaptureProgress.captured => VehicleCaptureStepState.captured,
        VehicleCaptureProgress.uploading => VehicleCaptureStepState.uploading,
        VehicleCaptureProgress.failed => VehicleCaptureStepState.failed,
        null => remoteUrl != null
            ? VehicleCaptureStepState.uploaded
            : VehicleCaptureStepState.missing,
      };

  @override
  List<Object?> get props => [requirement, remoteUrl, draft];
}

/// Everything the vehicle-verification screens show, derived from
/// `/rider/me` and the local drafts.
class VehicleVerificationView extends Equatable {
  final RiderVehicle vehicle;
  final List<VehicleCaptureStep> steps;
  final VehicleVerificationStatus status;
  final String? rejectionReason;
  final bool isUploading;

  const VehicleVerificationView({
    required this.vehicle,
    required this.steps,
    required this.status,
    this.rejectionReason,
    this.isUploading = false,
  });

  /// Joins the configuration for the rider's vehicle with what the server
  /// holds. Only [supportedTypes] become steps: asking for a photo the API
  /// can't store would only waste the rider's time.
  factory VehicleVerificationView.from({
    required RiderMeProfileModel profile,
    required Map<VehicleCaptureType, VehicleCaptureDraft> drafts,
    required Set<VehicleCaptureType> supportedTypes,
    bool isUploading = false,
  }) {
    final vehicle = RiderVehicle.fromProfile(profile);
    final config = VehicleVerificationConfiguration.forKind(vehicle.kind);
    final steps = [
      for (final requirement in config.requirements)
        if (supportedTypes.contains(requirement.type))
          VehicleCaptureStep(
            requirement: requirement,
            remoteUrl: vehicle.photos[requirement.type],
            draft: drafts[requirement.type],
          ),
    ];
    final hasRequiredPhotos = steps
        .where((s) => s.requirement.required)
        .every((s) => s.remoteUrl != null);

    return VehicleVerificationView(
      vehicle: vehicle,
      steps: steps,
      status: VehicleVerificationStatus.derive(
        profile: profile,
        hasRequiredPhotos: hasRequiredPhotos,
      ),
      rejectionReason: profile.rejectionReason,
      isUploading: isUploading,
    );
  }

  /// Steps with neither a server photo nor a local one.
  List<VehicleCaptureStep> get missingSteps =>
      steps.where((s) => s.state == VehicleCaptureStepState.missing).toList();

  /// Taken but not on the server yet — including failed uploads.
  List<VehicleCaptureStep> get pendingUploads => steps
      .where((s) =>
          s.state == VehicleCaptureStepState.captured ||
          s.state == VehicleCaptureStepState.failed)
      .toList();

  int get uploadedCount =>
      steps.where((s) => s.state == VehicleCaptureStepState.uploaded).length;

  /// 1-based position of [type] among all steps, for "Step 2 of 4".
  int stepNumberOf(VehicleCaptureType type) =>
      steps.indexWhere((s) => s.type == type) + 1;

  @override
  List<Object?> get props =>
      [vehicle, steps, status, rejectionReason, isUploading];
}
