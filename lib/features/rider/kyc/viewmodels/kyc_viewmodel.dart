import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_form_data.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';

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
  final bool isInitializing;
  final KycIdentityData identity;
  final KycLicenseData license;
  final KycVehicleData vehicle;
  final Map<String, UploadState> uploadStates;
  final KycSubmitStatus submitStatus;
  final String? errorMessage;

  const KycState({
    this.currentStep = 0,
    this.isInitializing = true,
    this.identity = const KycIdentityData(),
    this.license = const KycLicenseData(),
    this.vehicle = const KycVehicleData(),
    this.uploadStates = const {},
    this.submitStatus = KycSubmitStatus.idle,
    this.errorMessage,
  });

  KycState copyWith({
    int? currentStep,
    bool? isInitializing,
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
        isInitializing: isInitializing ?? this.isInitializing,
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
        isInitializing,
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

  RiderMeProfileRepository get _repo => sl<RiderMeProfileRepository>();

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

  /// Loads the rider's current `/rider/me` profile and pre-fills the wizard
  /// from it, then restores per-document upload status. Called once when
  /// the screen opens — the screen holds off building the step views until
  /// this completes, so each step's `initState` (which seeds its
  /// `TextEditingController`s synchronously and only once) reads already
  /// up-to-date state instead of racing this async load.
  Future<void> initializeFromProfile() async {
    state = state.copyWith(isInitializing: true);

    await ref.read(riderMeProfileProvider.notifier).load();
    final profile = ref.read(riderMeProfileProvider).profile;

    if (profile == null) {
      state = state.copyWith(isInitializing: false);
      return;
    }

    state = state.copyWith(
      identity: KycIdentityData(
        nationalId: profile.idNumber ?? '',
        dateOfBirth: _parseDate(profile.dateOfBirth),
        address: profile.residentialAddress ?? '',
      ),
      license: KycLicenseData(
        licenseNumber: profile.licenceNumber ?? '',
        expiryDate: _parseDate(profile.licenceExpiresAt),
      ),
      vehicle: KycVehicleData(
        vehicleType: profile.vehicleType ?? '',
        brand: profile.vehicleMake ?? '',
        model: profile.vehicleModel ?? '',
        plateNumber: profile.plateNumber ?? '',
        color: profile.vehicleColour ?? '',
      ),
    );

    await _restoreUploadStatuses(profile);
    state = state.copyWith(isInitializing: false);
  }

  Future<void> _restoreUploadStatuses(RiderMeProfileModel profile) async {
    final restored = <String, UploadState>{};

    if (profile.photoUrl != null) {
      restored[KycDocKey.selfie] = UploadState(
        progress: UploadProgress.done,
        remoteUrl: profile.photoUrl,
      );
    }

    for (final entry in KycDocKey.riderMeTypeSlug.entries) {
      final type = entry.value;
      if (type == null) continue; // selfie — handled above via photoUrl
      final result = await _repo.getDocument(type);
      result.fold(
        (_) {}, // not uploaded yet, or lookup failed — leave idle
        (doc) {
          if (doc.url != null) {
            restored[entry.key] = UploadState(
              progress: UploadProgress.done,
              remoteUrl: doc.url,
            );
          }
        },
      );
    }

    if (restored.isNotEmpty) {
      state = state.copyWith(
        uploadStates: {...state.uploadStates, ...restored},
      );
    }
  }

  DateTime? _parseDate(String? value) =>
      (value == null || value.isEmpty) ? null : DateTime.tryParse(value);

  Future<void> pickAndUploadFile(String docKey, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    _setUploadState(
      docKey,
      UploadState(progress: UploadProgress.uploading, localPath: picked.path),
    );

    if (docKey == KycDocKey.selfie) {
      final result = await _repo.uploadPhoto(picked.path);
      result.fold(
        (failure) => _setUploadState(
          docKey,
          UploadState(
            progress: UploadProgress.failed,
            localPath: picked.path,
            errorMessage: failure.message,
          ),
        ),
        (url) => _setUploadState(
          docKey,
          UploadState(
            progress: UploadProgress.done,
            localPath: picked.path,
            remoteUrl: url,
          ),
        ),
      );
      return;
    }

    final type = KycDocKey.riderMeTypeSlug[docKey];
    if (type == null) return; // no backend slug for this key

    final result = await _repo.uploadDocument(type: type, filePath: picked.path);
    result.fold(
      (failure) => _setUploadState(
        docKey,
        UploadState(
          progress: UploadProgress.failed,
          localPath: picked.path,
          errorMessage: failure.message,
        ),
      ),
      (doc) => _setUploadState(
        docKey,
        UploadState(
          progress: UploadProgress.done,
          localPath: picked.path,
          remoteUrl: doc.url,
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

    final updateResult = await _repo.updateProfile(_buildProfilePayload());
    final updateError = updateResult.fold((f) => f.message, (_) => null);
    if (updateError != null) {
      state = state.copyWith(
        submitStatus: KycSubmitStatus.error,
        errorMessage: updateError,
      );
      return;
    }

    final reviewResult = await _repo.submitForReview();
    final reviewError = reviewResult.fold((f) => f.message, (_) => null);
    if (reviewError != null) {
      state = state.copyWith(
        submitStatus: KycSubmitStatus.error,
        errorMessage: reviewError,
      );
      return;
    }

    state = state.copyWith(submitStatus: KycSubmitStatus.success);
    // Refresh the shared profile state so the dashboard's KYC banner picks
    // up the new verification_status without waiting for its own reload.
    await ref.read(riderMeProfileProvider.notifier).load();
  }

  /// Builds the `PUT rider/me` payload from the wizard's local form state.
  ///
  /// `vehicle_type`/`plate_number` are deliberately excluded — both were
  /// already set at `/register` (see rider_otp_screen.dart for the same
  /// exclusion and why), and the backend's `vehicle_type` picklist only
  /// accepts `"motorbike"`, not this wizard's free-form vehicle-type value.
  Map<String, dynamic> _buildProfilePayload() {
    const dateFormat = 'yyyy-MM-dd';
    return {
      // Not collected by any step; defaults to the ID type implied by the
      // National ID field's own placeholder ("GHA-000000000-0").
      'id_type': 'ghana_card',
      if (state.identity.nationalId.isNotEmpty)
        'id_number': state.identity.nationalId,
      if (state.identity.dateOfBirth != null)
        'date_of_birth':
            DateFormat(dateFormat).format(state.identity.dateOfBirth!),
      if (state.identity.address.isNotEmpty)
        'residential_address': state.identity.address,
      if (state.license.licenseNumber.isNotEmpty)
        'licence_number': state.license.licenseNumber,
      if (state.license.expiryDate != null)
        'licence_expires_at':
            DateFormat(dateFormat).format(state.license.expiryDate!),
      if (state.vehicle.brand.isNotEmpty) 'vehicle_make': state.vehicle.brand,
      if (state.vehicle.model.isNotEmpty)
        'vehicle_model': state.vehicle.model,
      if (state.vehicle.color.isNotEmpty)
        'vehicle_colour': state.vehicle.color,
    };
  }

  void reset() {
    state = const KycState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _setUploadState(String docKey, UploadState uploadState) {
    final newMap = Map<String, UploadState>.from(state.uploadStates);
    newMap[docKey] = uploadState;
    state = state.copyWith(uploadStates: newMap);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final kycProvider =
    NotifierProvider<KycNotifier, KycState>(KycNotifier.new);
