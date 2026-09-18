import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_progress.dart';
import 'package:delivery_boy/features/rider/kyc/models/upload_state.dart';
import 'package:delivery_boy/features/rider/profile/models/payout_provider_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';

/// The rider's checklist, or null until `/rider/me` has loaded.
///
/// Derived — never stored — so it can't drift from the profile it's built
/// from. Every "is the profile complete?" question in the app reads this.
final kycProgressProvider = Provider<KycProgress?>((ref) {
  final profile = ref.watch(riderMeProfileProvider.select((s) => s.profile));
  return profile == null ? null : KycProgress.fromProfile(profile);
});

/// Bank and mobile-money providers for the payout step. Errors surface as
/// the [Failure] itself.
final payoutProvidersProvider =
    FutureProvider.autoDispose<List<PayoutProviderModel>>((ref) async {
  final result = await sl<RiderMeProfileRepository>().getPayoutProviders();
  return result.fold((failure) => throw failure, (providers) => providers);
});

/// Upload key for the profile photo, alongside document slugs.
const kycPhotoUploadKey = 'profile_photo';

/// In-flight and failed uploads, keyed by document slug (or
/// [kycPhotoUploadKey]).
///
/// Only tracks what the server can't tell us — progress, failures, the
/// local file for a preview. Whether a document counts as uploaded comes
/// from `/rider/me`, which is reloaded after every successful upload.
class KycUploadsNotifier extends Notifier<Map<String, UploadState>> {
  @override
  Map<String, UploadState> build() {
    _resetWhenRiderChanges(ref);
    return const {};
  }

  RiderMeProfileRepository get _repo => sl<RiderMeProfileRepository>();

  Future<Failure?> uploadDocument(String slug, String filePath) =>
      _upload(slug, filePath, () async {
        final result = await _repo.uploadDocument(type: slug, filePath: filePath);
        return result.fold((f) => f, (_) => null);
      });

  Future<Failure?> uploadPhoto(String filePath) =>
      _upload(kycPhotoUploadKey, filePath, () async {
        final result = await _repo.uploadPhoto(filePath);
        return result.fold((f) => f, (_) => null);
      });

  Future<Failure?> _upload(
    String key,
    String filePath,
    Future<Failure?> Function() send,
  ) async {
    _set(key, UploadState(progress: UploadProgress.uploading, localPath: filePath));
    final failure = await send();
    if (failure != null) {
      _set(
        key,
        UploadState(
          progress: UploadProgress.failed,
          localPath: filePath,
          errorMessage: failure.message,
        ),
      );
      return failure;
    }
    _set(key, UploadState(progress: UploadProgress.done, localPath: filePath));
    await ref.read(riderMeProfileProvider.notifier).load();
    return null;
  }

  void _set(String key, UploadState upload) =>
      state = {...state, key: upload};
}

final kycUploadsProvider =
    NotifierProvider<KycUploadsNotifier, Map<String, UploadState>>(
        KycUploadsNotifier.new);

class KycActionsState extends Equatable {
  final bool isSaving;
  final bool isSubmitting;

  /// Submitted during this session. `/rider/me` reports `pending_review`
  /// both before and after submission, so this is the only signal that the
  /// rider has already sent it.
  final bool hasSubmitted;

  const KycActionsState({
    this.isSaving = false,
    this.isSubmitting = false,
    this.hasSubmitted = false,
  });

  KycActionsState copyWith({
    bool? isSaving,
    bool? isSubmitting,
    bool? hasSubmitted,
  }) =>
      KycActionsState(
        isSaving: isSaving ?? this.isSaving,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      );

  @override
  List<Object?> get props => [isSaving, isSubmitting, hasSubmitted];
}

/// Saves checklist sections and submits the profile for review. Callers
/// disable their buttons on [KycActionsState] while a call is in flight.
///
/// Each method returns the [Failure], or null on success — a
/// [ValidationFailure] carries per-field messages for the form to place.
/// On success `/rider/me` is reloaded, so the checklist reflects the
/// server's new view of what's outstanding.
class KycActionsNotifier extends Notifier<KycActionsState> {
  @override
  KycActionsState build() {
    _resetWhenRiderChanges(ref);
    return const KycActionsState();
  }

  RiderMeProfileRepository get _repo => sl<RiderMeProfileRepository>();

  /// Partial `PUT /rider/me` — pass only the section's fields.
  Future<Failure?> saveProfile(Map<String, dynamic> fields) => _save(() async {
        final result = await _repo.updateProfile(fields);
        return result.fold((f) => f, (_) => null);
      });

  /// `PUT /rider/me/payout`. Pass either the bank or the mobile-money pair.
  Future<Failure?> savePayout({
    required String currentPassword,
    required String accountName,
    int? payoutProviderId,
    String? accountNumber,
    int? momoProviderId,
    String? mobileMoneyNumber,
  }) =>
      _save(() async {
        final result = await _repo.updatePayout(
          currentPassword: currentPassword,
          accountName: accountName,
          payoutProviderId: payoutProviderId,
          accountNumber: accountNumber,
          momoProviderId: momoProviderId,
          mobileMoneyNumber: mobileMoneyNumber,
        );
        return result.fold((f) => f, (_) => null);
      });

  Future<Failure?> submitForReview() async {
    state = state.copyWith(isSubmitting: true);
    final result = await _repo.submitForReview();
    final failure = result.fold((f) => f, (_) => null);
    if (failure == null) {
      await ref.read(riderMeProfileProvider.notifier).load();
    }
    state = state.copyWith(
      isSubmitting: false,
      hasSubmitted: failure == null ? true : null,
    );
    return failure;
  }

  Future<Failure?> _save(Future<Failure?> Function() send) async {
    state = state.copyWith(isSaving: true);
    final failure = await send();
    if (failure == null) {
      await ref.read(riderMeProfileProvider.notifier).load();
    }
    state = state.copyWith(isSaving: false);
    return failure;
  }
}

/// Rebuilds the calling notifier — clearing its state — when a different
/// rider's profile loads, so one account's uploads or submission never show
/// for the next person to sign in on the device.
void _resetWhenRiderChanges(Ref ref) =>
    ref.watch(riderMeProfileProvider.select((s) => s.profile?.id));

final kycActionsProvider =
    NotifierProvider<KycActionsNotifier, KycActionsState>(
        KycActionsNotifier.new);
