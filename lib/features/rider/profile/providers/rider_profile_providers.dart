import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/profile/repositories/rider_profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, error }

class RiderProfileState extends Equatable {
  final ProfileStatus status;
  final RiderUserModel? user;
  final String? errorMessage;

  const RiderProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
  });

  RiderProfileState copyWith({
    ProfileStatus? status,
    RiderUserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, user, errorMessage];
}

class RiderProfileNotifier extends Notifier<RiderProfileState> {
  @override
  RiderProfileState build() {
    // Load user from session cache immediately
    final cachedUser = sl<UserSessionManager>().currentUser;
    if (cachedUser != null) {
      return RiderProfileState(
        status: ProfileStatus.loaded,
        user: RiderUserModel.fromJson(cachedUser),
      );
    }
    return const RiderProfileState();
  }

  RiderProfileRepository get _repo => sl<RiderProfileRepository>();
  UserSessionManager get _session => sl<UserSessionManager>();

  Future<void> load() async {
    final userId = _session.currentUser?['_id'] as String? ?? '';
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    final result = await _repo.getProfile(userId);
    result.fold(
      (f) => state =
          state.copyWith(status: ProfileStatus.error, errorMessage: f.message),
      (user) async {
        await _session.saveSession(
          token: _session.token!,
          user: user.toJson(),
        );
        state = state.copyWith(status: ProfileStatus.loaded, user: user);
      },
    );
  }

  Future<bool> updateCourier(Map<String, dynamic> data) async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    final result = await _repo.updateCourier(data);
    return result.fold(
      (f) {
        state =
            state.copyWith(status: ProfileStatus.error, errorMessage: f.message);
        return false;
      },
      (user) async {
        await _session.saveSession(
          token: _session.token!,
          user: user.toJson(),
        );
        state = state.copyWith(status: ProfileStatus.loaded, user: user);
        return true;
      },
    );
  }

  Future<bool> uploadDoc(FormData formData) async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    final result = await _repo.uploadDoc(formData);
    return result.fold(
      (f) {
        state =
            state.copyWith(status: ProfileStatus.error, errorMessage: f.message);
        return false;
      },
      (user) async {
        await _session.saveSession(
          token: _session.token!,
          user: user.toJson(),
        );
        state = state.copyWith(status: ProfileStatus.loaded, user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _session.clearSession();
  }
}

final riderProfileProvider =
    NotifierProvider<RiderProfileNotifier, RiderProfileState>(
        RiderProfileNotifier.new);
