import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/auth_user_model.dart';
import 'package:delivery_boy/features/rider/auth/repositories/rider_auth_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, success, error }

class RiderAuthState extends Equatable {
  final AuthStatus status;
  final AuthUserModel? user;
  final String? errorMessage;

  /// Per-field messages from the last 422, keyed by API field name
  /// (`email`, `phone`, `plate_number`, …). Lets a view put each message on
  /// the input that caused it instead of only in a snackbar.
  final Map<String, List<String>> fieldErrors;

  /// A verification code has been dispatched (either flow).
  final bool codeSent;
  final bool phoneVerified;
  final bool passwordReset;

  const RiderAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
    this.codeSent = false,
    this.phoneVerified = false,
    this.passwordReset = false,
  });

  bool get isLoading => status == AuthStatus.loading;

  RiderAuthState copyWith({
    AuthStatus? status,
    AuthUserModel? user,
    String? errorMessage,
    Map<String, List<String>>? fieldErrors,
    bool? codeSent,
    bool? phoneVerified,
    bool? passwordReset,
    bool clearError = false,
  }) {
    return RiderAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      // Cleared alongside errorMessage — otherwise inline field errors
      // linger after the snackbar is dismissed.
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
      codeSent: codeSent ?? this.codeSent,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      passwordReset: passwordReset ?? this.passwordReset,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        fieldErrors,
        codeSent,
        phoneVerified,
        passwordReset,
      ];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiderAuthNotifier extends Notifier<RiderAuthState> {
  @override
  RiderAuthState build() => const RiderAuthState();

  RiderAuthRepository get _repo => sl<RiderAuthRepository>();
  UserSessionManager get _session => sl<UserSessionManager>();

  /// Persists tokens + user before the caller is allowed to navigate.
  ///
  /// `/register` may not issue a token; in that case only the user is
  /// stored and the session stays unauthenticated until verify/login.
  Future<void> _persist(AuthResult data) async {
    final token = data.token;
    if (token != null && token.isNotEmpty) {
      await _session.saveSession(
        token: token,
        refreshToken: data.refreshToken,
        user: data.user.toJson(),
      );
    } else {
      await _session.saveUser(data.user.toJson());
    }
  }

  /// Returns true on success, so the view can navigate.
  ///
  /// Every parameter is required by the backend for `role: rider`, which is
  /// why this can only be called once the vehicle screens have run.
  Future<bool> register({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String city,
    required String vehicleType,
    required String plateNumber,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.register(
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      firstName: firstName,
      lastName: lastName,
      city: city,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );

    if (result.isLeft()) {
      final failure = _failureOf(result);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure?.message ?? 'Request failed',
        fieldErrors:
            failure is ValidationFailure ? failure.errors : const {},
      );
      return false;
    }

    final data = result.getOrElse(() => throw StateError('unreachable'));
    // Awaited BEFORE returning — the caller navigates the moment this
    // resolves, and the next screen's requests need the token in place.
    await _persist(data);
    state = state.copyWith(status: AuthStatus.success, user: data.user);
    return true;
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.login(phone: phone, password: password);

    if (result.isLeft()) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _messageOf(result),
      );
      return false;
    }

    final data = result.getOrElse(() => throw StateError('unreachable'));
    await _persist(data);
    state = state.copyWith(
      status: AuthStatus.success,
      user: data.user,
      phoneVerified: data.user.phoneVerified,
    );
    return true;
  }

  /// Phone verification for a signed-up account.
  Future<bool> sendPhoneCode(String phone) async {
    state = state.copyWith(
        status: AuthStatus.loading, clearError: true, codeSent: false);

    final result = await _repo.sendPhoneCode(phone: phone);
    return result.fold(
      (f) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.initial, codeSent: true);
        return true;
      },
    );
  }

  /// Forgot-password flow — a different endpoint from [sendPhoneCode].
  Future<bool> sendForgotPasswordCode(String phone) async {
    state = state.copyWith(
        status: AuthStatus.loading, clearError: true, codeSent: false);

    final result = await _repo.sendForgotPasswordCode(phone: phone);
    return result.fold(
      (f) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.initial, codeSent: true);
        return true;
      },
    );
  }

  /// Verifies the phone, then guarantees an authenticated session.
  ///
  /// If `/register` issued no token, this transparently logs in with
  /// [password] so the caller can rely on a Bearer token afterwards.
  Future<bool> verifyPhoneAndEnsureSession({
    required String phone,
    required String code,
    String? password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.verifyPhone(phone: phone, code: code);
    if (result.isLeft()) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _messageOf(result),
      );
      return false;
    }

    await _session.updateUser({'phone_verified': true});
    state = state.copyWith(
      status: AuthStatus.success,
      phoneVerified: true,
      user: state.user?.copyWith(phoneVerified: true),
    );

    // Registration didn't return a token — obtain one now.
    if (!_session.isLoggedIn && password != null && password.isNotEmpty) {
      return login(phone: phone, password: password);
    }
    return true;
  }

  Future<bool> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.resetPassword(
      phone: phone,
      code: code,
      password: password,
      confirmPassword: confirmPassword,
    );

    return result.fold(
      (f) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
            status: AuthStatus.initial, passwordReset: true);
        return true;
      },
    );
  }

  /// Refreshes the cached user from `/profile`.
  Future<void> refreshProfile() async {
    final result = await _repo.getProfile();
    result.fold(
      (_) {},
      (user) async {
        await _session.saveUser(user.toJson());
        state = state.copyWith(user: user, phoneVerified: user.phoneVerified);
      },
    );
  }

  /// Best-effort server logout; the local session is always cleared.
  Future<void> logout() async {
    await _repo.logout();
    await _session.clearSession();
    state = const RiderAuthState();
  }

  String _messageOf<T>(Either<Failure, T> result) =>
      result.fold((f) => f.message, (_) => 'Request failed');

  /// The [Failure] itself, so callers can inspect its subtype (e.g. to pull
  /// per-field errors out of a [ValidationFailure]).
  Failure? _failureOf<T>(Either<Failure, T> result) =>
      result.fold((f) => f, (_) => null);

  void clearError() => state = state.copyWith(clearError: true);
  void clearCodeSent() => state = state.copyWith(codeSent: false);
  void clearPasswordReset() => state = state.copyWith(passwordReset: false);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final riderAuthProvider =
    NotifierProvider<RiderAuthNotifier, RiderAuthState>(RiderAuthNotifier.new);
