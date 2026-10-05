import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/vehicles/capture/vehicle_photo_inspector.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification.dart';
import 'package:delivery_boy/features/rider/vehicles/repository/vehicle_verification_repository.dart';

class VehicleKycState extends Equatable {
  /// Photos taken this session that the server doesn't have yet.
  final Map<VehicleCaptureType, VehicleCaptureDraft> drafts;
  final bool isUploading;
  final bool isClearing;

  const VehicleKycState({
    this.drafts = const {},
    this.isUploading = false,
    this.isClearing = false,
  });

  bool get isBusy => isUploading || isClearing;

  VehicleKycState copyWith({
    Map<VehicleCaptureType, VehicleCaptureDraft>? drafts,
    bool? isUploading,
    bool? isClearing,
  }) =>
      VehicleKycState(
        drafts: drafts ?? this.drafts,
        isUploading: isUploading ?? this.isUploading,
        isClearing: isClearing ?? this.isClearing,
      );

  @override
  List<Object?> get props => [drafts, isUploading, isClearing];
}

/// Vehicle-photo captures and their uploads.
///
/// Only tracks what the server can't tell us: photos taken but not yet
/// uploaded, upload progress and failures. Which photos the server holds,
/// and what that means for verification, comes from `/rider/me` — see
/// [vehicleVerificationProvider].
///
/// Uploads run one at a time. A failed one keeps its photo for a retry and
/// never undoes the others.
class VehicleKycNotifier extends Notifier<VehicleKycState> {
  /// Bumped on every rebuild — i.e. whenever a different rider's profile
  /// loads.
  int _generation = 0;

  /// Temporary capture files this notifier is responsible for deleting.
  final _ownedFiles = <String>{};

  @override
  VehicleKycState build() {
    ref.watch(riderMeProfileProvider.select((s) => s.profile?.id));
    _generation++;
    ref.onDispose(_deleteOwnedFiles);
    return const VehicleKycState();
  }

  VehicleVerificationRepository get _repo =>
      sl<VehicleVerificationRepository>();

  /// Who a piece of work was started for. Async work stops as soon as this
  /// changes, so one rider's photos are never sent — or their profile
  /// applied — under the next rider's sign-in. The rider id is read
  /// directly because the rebuild that bumps [_generation] can lag behind.
  (int, int?) get _session =>
      (_generation, ref.read(riderMeProfileProvider).profile?.id);

  /// Keeps a photo the rider accepted in the camera, replacing (and
  /// deleting) any earlier one for the same step.
  void recordCapture(VehicleCaptureType type, String path) {
    final previous = state.drafts[type];
    if (previous?.progress == VehicleCaptureProgress.uploading) {
      _deleteFile(path);
      return;
    }
    if (previous != null && previous.localPath != path) {
      _deleteFile(previous.localPath);
    }
    _ownedFiles.add(path);
    _setDraft(type, VehicleCaptureDraft(localPath: path));
    _log('capture_completed', type);
  }

  /// Uploads every photo not yet on the server (or just [only]), in capture
  /// order. Returns the first failure, or null when all succeeded. A second
  /// call while one is running does nothing.
  Future<Failure?> uploadPending({Set<VehicleCaptureType>? only}) async {
    if (state.isBusy) return null;
    final session = _session;
    final pending = [
      for (final type in VehicleCaptureType.values)
        if (state.drafts.containsKey(type) && (only?.contains(type) ?? true))
          type,
    ];
    if (pending.isEmpty) return null;

    state = state.copyWith(isUploading: true);
    Failure? first;
    try {
      for (final type in pending) {
        final failure = await _uploadOne(type, session);
        if (session != _session) return failure;
        first ??= failure;
        // The interceptor has signed the rider out; the rest would 401 too.
        if (failure is SessionExpiredFailure) break;
      }
    } finally {
      // Never leave the screen locked behind a spinner.
      if (session == _session) state = state.copyWith(isUploading: false);
    }
    return first;
  }

  Future<Failure?> _uploadOne(
    VehicleCaptureType type,
    (int, int?) session,
  ) async {
    final draft = state.drafts[type];
    if (draft == null) return null;
    _setDraft(type, draft.withProgress(VehicleCaptureProgress.uploading));
    _log('upload_started', type);

    final problem = await VehiclePhotoInspector.fileProblem(draft.localPath);
    if (session != _session) return null;
    if (problem != null) {
      _setDraft(
          type,
          draft.withProgress(
            VehicleCaptureProgress.failed,
            errorMessage: problem,
          ));
      return ValidationFailure(problem, {
        'photo': [problem]
      });
    }

    var shown = 0.0;
    final result = await _repo.uploadPhoto(
      type,
      draft.localPath,
      onProgress: (fraction) {
        // Every 5% is plenty on screen and spares a rebuild per packet.
        if (session != _session || fraction - shown < 0.05) return;
        shown = fraction;
        _setDraft(
            type,
            draft.withProgress(
              VehicleCaptureProgress.uploading,
              uploadFraction: fraction,
            ));
      },
    );
    if (session != _session) return null;

    final (failure, profile) = result.fold<(Failure?, RiderMeProfileModel?)>(
      (f) => (f, null),
      (p) => (null, p),
    );
    if (failure != null) {
      _setDraft(
          type,
          draft.withProgress(
            VehicleCaptureProgress.failed,
            errorMessage: failure.message,
          ));
      _log('upload_failed', type);
      return failure;
    }

    // Adopt the server's view before dropping the draft, so the step goes
    // straight from "uploading" to the new photo.
    await _adopt(profile);
    if (session != _session) return null;
    _removeDraft(type);
    _log('upload_succeeded', type);
    return null;
  }

  /// Removes the photos of a vehicle the rider has just replaced, so its
  /// verification can't carry over to the new one. Returns the failure, or
  /// null when nothing remains.
  Future<Failure?> clearPhotosForVehicleChange() async {
    if (state.isBusy) return null;
    final session = _session;
    for (final type in [...state.drafts.keys]) {
      _removeDraft(type);
    }
    final profile = ref.read(riderMeProfileProvider).profile;
    if (profile == null) return null;

    final onServer = [
      for (final type in VehicleVerificationRepository.supportedCaptureTypes)
        if (profile.vehiclePhotos.containsKey(type.apiKey)) type,
    ];
    if (onServer.isEmpty) return null;

    state = state.copyWith(isClearing: true);
    Failure? failure;
    try {
      for (final type in onServer) {
        final result = await _repo.deletePhoto(type);
        if (session != _session) return null;
        final (f, updated) = result.fold<(Failure?, RiderMeProfileModel?)>(
          (f) => (f, null),
          (p) => (null, p),
        );
        if (f != null) {
          failure = f;
          break;
        }
        await _adopt(updated);
        if (session != _session) return null;
      }
    } finally {
      if (session == _session) state = state.copyWith(isClearing: false);
    }
    _log(failure == null ? 'photos_cleared' : 'photos_clear_failed');
    return failure;
  }

  /// Uses the profile a call returned, or re-reads `/rider/me` when the body
  /// wasn't one.
  Future<void> _adopt(RiderMeProfileModel? profile) async {
    final profiles = ref.read(riderMeProfileProvider.notifier);
    if (profile != null) {
      profiles.applyProfile(profile);
    } else {
      await profiles.load();
    }
  }

  void _setDraft(VehicleCaptureType type, VehicleCaptureDraft draft) =>
      state = state.copyWith(drafts: {...state.drafts, type: draft});

  void _removeDraft(VehicleCaptureType type) {
    final draft = state.drafts[type];
    if (draft == null) return;
    _deleteFile(draft.localPath);
    state = state.copyWith(drafts: {...state.drafts}..remove(type));
  }

  void _deleteFile(String path) {
    _ownedFiles.remove(path);
    File(path).delete().ignore();
  }

  void _deleteOwnedFiles() {
    for (final path in [..._ownedFiles]) {
      _deleteFile(path);
    }
  }

  /// Safe-to-log milestones: the step's name only — never a path, URL or
  /// image data.
  void _log(String event, [VehicleCaptureType? type]) => appLogger.i(
        'vehicle_kyc_$event${type == null ? '' : ' (${type.apiKey})'}',
      );
}

final vehicleKycProvider =
    NotifierProvider<VehicleKycNotifier, VehicleKycState>(
        VehicleKycNotifier.new);

/// The rider's vehicle, its verification status and each capture step —
/// null until `/rider/me` has loaded.
final vehicleVerificationProvider = Provider<VehicleVerificationView?>((ref) {
  final profile = ref.watch(riderMeProfileProvider.select((s) => s.profile));
  if (profile == null) return null;
  final kyc = ref.watch(vehicleKycProvider);
  return VehicleVerificationView.from(
    profile: profile,
    drafts: kyc.drafts,
    supportedTypes: VehicleVerificationRepository.supportedCaptureTypes,
    isUploading: kyc.isBusy,
  );
});
