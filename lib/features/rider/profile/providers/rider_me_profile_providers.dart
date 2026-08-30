import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_me_profile_repository.dart';

enum RiderMeProfileStatus { initial, loading, loaded, error }

class RiderMeProfileState extends Equatable {
  final RiderMeProfileStatus status;
  final RiderMeProfileModel? profile;
  final String? errorMessage;
  final RiderMeActionStatus actionStatus;
  final String? actionMessage;

  const RiderMeProfileState({
    this.status = RiderMeProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.actionStatus = RiderMeActionStatus.idle,
    this.actionMessage,
  });

  RiderMeProfileState copyWith({
    RiderMeProfileStatus? status,
    RiderMeProfileModel? profile,
    String? errorMessage,
    bool clearError = false,
    RiderMeActionStatus? actionStatus,
    String? actionMessage,
    bool clearActionMessage = false,
  }) =>
      RiderMeProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        actionStatus: actionStatus ?? this.actionStatus,
        actionMessage: clearActionMessage
            ? null
            : (actionMessage ?? this.actionMessage),
      );

  @override
  List<Object?> get props =>
      [status, profile, errorMessage, actionStatus, actionMessage];
}

class RiderMeProfileNotifier extends Notifier<RiderMeProfileState> {
  @override
  RiderMeProfileState build() => const RiderMeProfileState();

  RiderMeProfileRepository get _repo => sl<RiderMeProfileRepository>();

  Future<void> load() async {
    state = state.copyWith(
        status: RiderMeProfileStatus.loading, clearError: true);
    final result = await _repo.getMe();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderMeProfileStatus.error, errorMessage: f.message),
      (profile) => state = state.copyWith(
          status: RiderMeProfileStatus.loaded, profile: profile),
    );
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    try {
      await action();
      state = state.copyWith(actionStatus: RiderMeActionStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        actionStatus: RiderMeActionStatus.error,
        actionMessage: e.toString(),
      );
      return false;
    }
  }

  /// Partial update — pass only the fields being changed.
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.updateProfile(data);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (profile) {
        state = state.copyWith(
          status: RiderMeProfileStatus.loaded,
          profile: profile,
          actionStatus: RiderMeActionStatus.success,
        );
        return true;
      },
    );
  }

  Future<bool> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.acceptAgreement(
      acceptTerms: acceptTerms,
      consentToVerification: consentToVerification,
      termsVersion: termsVersion,
    );
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(actionStatus: RiderMeActionStatus.success);
        return true;
      },
    );
  }

  Future<bool> setAvailability(bool isOnline) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.setAvailability(isOnline);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.success,
          profile: state.profile?.copyWith(isOnline: isOnline),
        );
        return true;
      },
    );
  }

  Future<RiderMeDocumentModel?> uploadDocument({
    required String type,
    required String filePath,
  }) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result =
        await _repo.uploadDocument(type: type, filePath: filePath);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return null;
      },
      (doc) {
        state = state.copyWith(actionStatus: RiderMeActionStatus.success);
        return doc;
      },
    );
  }

  Future<RiderMeDocumentModel?> getDocument(String type) async {
    final result = await _repo.getDocument(type);
    return result.fold((_) => null, (doc) => doc);
  }

  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final result =
        await _repo.updateLocation(latitude: latitude, longitude: longitude);
    return result.fold((_) => false, (_) => true);
  }

  Future<bool> updatePayout({
    int? payoutProviderId,
    String? accountNumber,
    String? accountName,
    int? momoProviderId,
    String? mobileMoneyNumber,
  }) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.updatePayout(
      payoutProviderId: payoutProviderId,
      accountNumber: accountNumber,
      accountName: accountName,
      momoProviderId: momoProviderId,
      mobileMoneyNumber: mobileMoneyNumber,
    );
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (profile) {
        state = state.copyWith(
          profile: profile,
          actionStatus: RiderMeActionStatus.success,
        );
        return true;
      },
    );
  }

  Future<bool> uploadPhoto(String filePath) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.uploadPhoto(filePath);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (photoUrl) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.success,
          profile: photoUrl != null
              ? state.profile?.copyWith(photoUrl: photoUrl)
              : state.profile,
        );
        return true;
      },
    );
  }

  Future<bool> submitForReview() =>
      _runAction(() async {
        final result = await _repo.submitForReview();
        result.fold(
          (f) => throw Exception(f.message),
          (_) {},
        );
      });

  void clearActionStatus() =>
      state = state.copyWith(actionStatus: RiderMeActionStatus.idle);
}

final riderMeProfileProvider =
    NotifierProvider<RiderMeProfileNotifier, RiderMeProfileState>(
        RiderMeProfileNotifier.new);
