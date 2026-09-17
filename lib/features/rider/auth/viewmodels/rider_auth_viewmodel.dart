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

  /// The rider has accepted the terms/verification agreement — either
  /// confirmed with the server already, or queued for the moment a session
  /// token exists (see [RiderAuthNotifier.registerAndAcceptAgreement]).
  final bool agreementAccepted;

  const RiderAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
    this.codeSent = false,
    this.phoneVerified = false,
    this.passwordReset = false,
    this.agreementAccepted = false,
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
    bool? agreementAccepted,
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
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
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
        agreementAccepted,
      ];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiderAuthNotifier extends Notifier<RiderAuthState> {
  @override
  RiderAuthState build() => const RiderAuthState();

  RiderAuthRepository get _repo => sl<RiderAuthRepository>();
  UserSessionManager get _session => sl<UserSessionManager>();

  /// Consent captured on the terms screen but not yet sent, because
  /// `/register` deferred issuing a token. Flushed the moment a session
  /// exists — see [registerAndAcceptAgreement] and [verifyPhoneAndEnsureSession].
  ({bool acceptTerms, bool consentToVerification, String? termsVersion})?
      _pendingAgreement;

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

  /// Orchestrates the terms screen's "Accept & Continue": creates the
  /// account, then records the rider's consent.
  ///
  /// `/rider/me/agreement` requires Bearer auth, so it cannot fire before
  /// `/register` the way the UI presents it — this runs `register` first
  /// to obtain the session, then submits the consent the rider already
  /// gave on the terms screen. If `/register` doesn't return a token
  /// immediately, the consent is queued and sent the moment
  /// [verifyPhoneAndEnsureSession] establishes one. Either way, the caller
  /// can navigate to phone verification as soon as this returns true.
  Future<bool> registerAndAcceptAgreement({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String city,
    required String vehicleType,
    required String plateNumber,
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) async {
    final registered = await register(
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
    if (!registered) return false;

    if (!_session.isLoggedIn) {
      // register() already left state.status at AuthStatus.success.
      _pendingAgreement = (
        acceptTerms: acceptTerms,
        consentToVerification: consentToVerification,
        termsVersion: termsVersion,
      );
      return true;
    }

    // Best-effort from here: the rider is already registered, so a failure
    // recording consent must not strand them mid-signup — they can accept
    // again from their profile. Navigation to phone verification proceeds
    // either way, hence the unconditional `return true` below.
    await _submitAgreement(
      acceptTerms: acceptTerms,
      consentToVerification: consentToVerification,
      termsVersion: termsVersion,
    );
    return true;
  }

  /// Records terms/verification consent directly and surfaces failure via
  /// [RiderAuthState.errorMessage]. Requires an authenticated session.
  /// Prefer [registerAndAcceptAgreement] from the terms screen, which
  /// sequences this correctly against `/register` and never blocks
  /// navigation on it.
  Future<bool> acceptAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final accepted = await _submitAgreement(
      acceptTerms: acceptTerms,
      consentToVerification: consentToVerification,
      termsVersion: termsVersion,
    );
    if (!accepted) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _lastAgreementError,
      );
    }
    return accepted;
  }

  /// Sends [_pendingAgreement] once a session exists. Best-effort: a
  /// failure here must not block the rider, who is already past OTP.
  Future<void> _flushPendingAgreement() async {
    final pending = _pendingAgreement;
    if (pending == null) return;
    _pendingAgreement = null;
    await _submitAgreement(
      acceptTerms: pending.acceptTerms,
      consentToVerification: pending.consentToVerification,
      termsVersion: pending.termsVersion,
    );
  }

  String? _lastAgreementError;

  /// Shared call behind [acceptAgreement], [registerAndAcceptAgreement] and
  /// [_flushPendingAgreement] — updates [RiderAuthState.agreementAccepted]
  /// on success and stashes the message in [_lastAgreementError] on
  /// failure, without touching [RiderAuthState.status] itself; callers
  /// decide how loudly to surface a failure.
  Future<bool> _submitAgreement({
    required bool acceptTerms,
    required bool consentToVerification,
    String? termsVersion,
  }) async {
    final result = await _repo.acceptAgreement(
      acceptTerms: acceptTerms,
      consentToVerification: consentToVerification,
      termsVersion: termsVersion,
    );
    return result.fold(
      (f) {
        _lastAgreementError = f.message;
        return false;
      },
      (_) {
        state = state.copyWith(agreementAccepted: true);
        return true;
      },
    );
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
      final loggedIn = await login(phone: phone, password: password);
      if (loggedIn) await _flushPendingAgreement();
      return loggedIn;
    }

    await _flushPendingAgreement();
    return true;
  }

  /// Verifies an OTP with no session side-effects — proves ownership of the
  /// rider's *current* phone before changing it. Distinct from
  /// [verifyPhoneAndEnsureSession], which verifies a newly-registered phone
  /// and may log the caller in; a phone-change flow starts already
  /// authenticated and must not touch `phone_verified` for a number that's
  /// about to be replaced.
  Future<bool> verifyPhoneOwnership({
    required String phone,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.verifyPhone(phone: phone, code: code);
    return result.fold(
      (f) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.initial);
        return true;
      },
    );
  }

  /// Changes the signed-in rider's password. Distinct from
  /// [sendForgotPasswordCode]/[resetPassword] — keeps the rider signed in
  /// and needs their current password rather than an OTP.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
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

    state = state.copyWith(status: AuthStatus.initial, clearError: true);
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
