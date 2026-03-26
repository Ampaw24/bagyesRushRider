import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, success, error }

class RiderAuthState extends Equatable {
  final AuthStatus status;
  final RiderUserModel? user;
  final String? errorMessage;
  final bool otpSent;
  final bool passwordReset;

  const RiderAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.otpSent = false,
    this.passwordReset = false,
  });

  RiderAuthState copyWith({
    AuthStatus? status,
    RiderUserModel? user,
    String? errorMessage,
    bool? otpSent,
    bool? passwordReset,
    bool clearError = false,
  }) {
    return RiderAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      otpSent: otpSent ?? this.otpSent,
      passwordReset: passwordReset ?? this.passwordReset,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, otpSent, passwordReset];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiderAuthNotifier extends Notifier<RiderAuthState> {
  @override
  RiderAuthState build() => const RiderAuthState();

  RiderAuthRepository get _repo => sl<RiderAuthRepository>();
  UserSessionManager get _session => sl<UserSessionManager>();

  /// Returns true on success (so the view can navigate).
  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.login(phone: phone, password: password);
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (data) async {
        await _session.saveSession(
          token: data.token,
          user: data.user.toJson(),
        );
        state = state.copyWith(status: AuthStatus.success, user: data.user);
        return true;
      },
    );
  }

  Future<void> sendOtp({required String phone}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.sendOtp(phoneNumber: phone);
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        status: AuthStatus.initial,
        otpSent: true,
      ),
    );
  }

  /// Returns true on success.
  Future<bool> signup({
    required String phone,
    required String password,
    required String otp,
    required String name,
    String? email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.signup(
      phone: phone,
      password: password,
      otp: otp,
      name: name,
      email: email,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (data) async {
        await _session.saveSession(
          token: data.token,
          user: data.user.toJson(),
        );
        state = state.copyWith(status: AuthStatus.success, user: data.user);
        return true;
      },
    );
  }

  /// Resets password using OTP-verified flow.
  /// Returns true on success.
  Future<bool> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final result = await _repo.resetPassword(
      phone: phone,
      newPassword: newPassword,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          status: AuthStatus.initial,
          passwordReset: true,
        );
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearPasswordReset() => state = state.copyWith(passwordReset: false);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final riderAuthProvider =
    NotifierProvider<RiderAuthNotifier, RiderAuthState>(RiderAuthNotifier.new);
