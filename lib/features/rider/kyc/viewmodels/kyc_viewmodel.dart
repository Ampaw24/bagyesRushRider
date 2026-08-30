import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/kyc/repositories/kyc_repository.dart';

// ── Upload state ───────────────────────────────────────────────────────────

enum UploadProgress { idle, uploading, done, failed }

class UploadState extends Equatable {
  final UploadProgress progress;
  final String? localPath;
  final String? remoteUrl;
  final String? errorMessage;

  const UploadState({
    this.progress = UploadProgress.idle,
    this.localPath,
    this.remoteUrl,
    this.errorMessage,
  });

  UploadState copyWith({
    UploadProgress? progress,
    String? localPath,
    String? remoteUrl,
    String? errorMessage,
  }) =>
      UploadState(
        progress: progress ?? this.progress,
        localPath: localPath ?? this.localPath,
        remoteUrl: remoteUrl ?? this.remoteUrl,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isDone => progress == UploadProgress.done;

  @override
  List<Object?> get props => [progress, localPath, remoteUrl, errorMessage];
}

// ── KYC state ─────────────────────────────────────────────────────────────

enum KycSubmitStatus { idle, loading, success, error }

class KycState extends Equatable {
  final int currentStep;
  final KycIdentityData identity;
  final KycLicenseData license;
  final KycVehicleData vehicle;
  final Map<String, UploadState> uploadStates;
  final KycSubmitStatus submitStatus;
  final String? errorMessage;

  const KycState({
    this.currentStep = 0,
    this.identity = const KycIdentityData(),
    this.license = const KycLicenseData(),
    this.vehicle = const KycVehicleData(),
    this.uploadStates = const {},
    this.submitStatus = KycSubmitStatus.idle,
    this.errorMessage,
  });

  KycState copyWith({
    int? currentStep,
    KycIdentityData? identity,
    KycLicenseData? license,
    KycVehicleData? vehicle,
    Map<String, UploadState>? uploadStates,
    KycSubmitStatus? submitStatus,
    String? errorMessage,
    bool clearError = false,
  }) =>
      KycState(
        currentStep: currentStep ?? this.currentStep,
        identity: identity ?? this.identity,
        license: license ?? this.license,
        vehicle: vehicle ?? this.vehicle,
        uploadStates: uploadStates ?? this.uploadStates,
        submitStatus: submitStatus ?? this.submitStatus,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  UploadState uploadStateFor(String docKey) =>
      uploadStates[docKey] ?? const UploadState();

  /// Returns the remote URLs for all completed uploads.
  Map<String, String> get completedUploadUrls {
    final result = <String, String>{};
    for (final entry in uploadStates.entries) {
      if (entry.value.isDone && entry.value.remoteUrl != null) {
        result[entry.key] = entry.value.remoteUrl!;
      }
    }
    return result;
  }

  int get uploadedDocCount =>
      uploadStates.values.where((s) => s.isDone).length;

  int get totalDocCount => KycDocKey.all.length;

  bool get hasMinimumUploads => KycDocKey.required
      .every((k) => uploadStates[k]?.isDone == true);

  @override
  List<Object?> get props => [
        currentStep,
        identity,
        license,
        vehicle,
        uploadStates,
        submitStatus,
        errorMessage,
      ];
}

// ── Notifier ──────────────────────────────────────────────────────────────

class KycNotifier extends Notifier<KycState> {
  @override
  KycState build() => const KycState();

  KycRepository get _repo => sl<KycRepository>();
  UserSessionManager get _session => sl<UserSessionManager>();

  void goToStep(int step) {
    assert(step >= 0 && step <= 4);
    state = state.copyWith(currentStep: step);
  }

  void updateIdentity(KycIdentityData data) {
    state = state.copyWith(identity: data);
  }

  void updateLicense(KycLicenseData data) {
    state = state.copyWith(license: data);
  }

  void updateVehicle(KycVehicleData data) {
    state = state.copyWith(vehicle: data);
  }

  Future<void> pickAndUploadFile(String docKey, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    // Update to uploading with local path
    _setUploadState(
      docKey,
      UploadState(progress: UploadProgress.uploading, localPath: picked.path),
    );

    final result = await _repo.uploadDoc(
      docKey: docKey,
      filePath: picked.path,
    );

    result.fold(
      (failure) => _setUploadState(
        docKey,
        UploadState(
          progress: UploadProgress.failed,
          localPath: picked.path,
          errorMessage: failure.message,
        ),
      ),
      (remoteUrl) => _setUploadState(
        docKey,
        UploadState(
          progress: UploadProgress.done,
          localPath: picked.path,
          remoteUrl: remoteUrl,
        ),
      ),
    );
  }

  void removeUpload(String docKey) {
    final newMap = Map<String, UploadState>.from(state.uploadStates);
    newMap.remove(docKey);
    state = state.copyWith(uploadStates: newMap);
  }

  Future<void> submit() async {
    state = state.copyWith(
      submitStatus: KycSubmitStatus.loading,
      clearError: true,
    );

    final result = await _repo.submitKyc(
      formData: KycFormData(
        identity: state.identity,
        license: state.license,
        vehicle: state.vehicle,
      ),
      uploadedDocUrls: state.completedUploadUrls,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          submitStatus: KycSubmitStatus.error,
          errorMessage: failure.message,
        );
      },
      (submissionResult) async {
        // Persist updated kycStatus in the user session
        await _persistKycStatus(submissionResult.status);
        state = state.copyWith(submitStatus: KycSubmitStatus.success);
      },
    );
  }

  void reset() {
    state = const KycState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _setUploadState(String docKey, UploadState uploadState) {
    final newMap = Map<String, UploadState>.from(state.uploadStates);
    newMap[docKey] = uploadState;
    state = state.copyWith(uploadStates: newMap);
  }

  Future<void> _persistKycStatus(KycStatus newStatus) async {
    // Optimistic local echo so the UI reflects a just-submitted KYC before
    // the next GET /rider/me. The authoritative value is that endpoint's
    // `verification_status` — see _kycStatusFrom in the dashboard.
    await _session.updateUser({'kycStatus': newStatus.name});
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final kycProvider =
    NotifierProvider<KycNotifier, KycState>(KycNotifier.new);
