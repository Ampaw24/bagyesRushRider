import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_me_wallet_repository.dart';

enum RiderMeWalletStatus { initial, loading, loaded, error }

enum RiderMeWithdrawalsStatus { initial, loading, loaded, error }

/// Wallet balance + withdrawals + the money-write actions on them — kept
/// together because a successful request/cancel changes both the balance
/// and the withdrawals list at once. Transactions are a separate provider
/// (`rider_me_wallet_transactions_providers.dart`) since they have their
/// own independent load/empty/error lifecycle and page.
class RiderMeWalletState extends Equatable {
  final RiderMeWalletStatus status;
  final RiderMeWalletModel? wallet;
  final String? errorMessage;

  final RiderMeWithdrawalsStatus withdrawalsStatus;
  final List<RiderMeWithdrawalModel> withdrawals;
  final String? withdrawalsErrorMessage;

  final RiderMeActionStatus actionStatus;
  final String? actionMessage;
  final Map<String, List<String>>? actionFieldErrors;

  const RiderMeWalletState({
    this.status = RiderMeWalletStatus.initial,
    this.wallet,
    this.errorMessage,
    this.withdrawalsStatus = RiderMeWithdrawalsStatus.initial,
    this.withdrawals = const [],
    this.withdrawalsErrorMessage,
    this.actionStatus = RiderMeActionStatus.idle,
    this.actionMessage,
    this.actionFieldErrors,
  });

  RiderMeWalletState copyWith({
    RiderMeWalletStatus? status,
    RiderMeWalletModel? wallet,
    String? errorMessage,
    bool clearError = false,
    RiderMeWithdrawalsStatus? withdrawalsStatus,
    List<RiderMeWithdrawalModel>? withdrawals,
    String? withdrawalsErrorMessage,
    bool clearWithdrawalsError = false,
    RiderMeActionStatus? actionStatus,
    String? actionMessage,
    bool clearActionMessage = false,
    Map<String, List<String>>? actionFieldErrors,
    bool clearActionFieldErrors = false,
  }) =>
      RiderMeWalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        withdrawalsStatus: withdrawalsStatus ?? this.withdrawalsStatus,
        withdrawals: withdrawals ?? this.withdrawals,
        withdrawalsErrorMessage: clearWithdrawalsError
            ? null
            : (withdrawalsErrorMessage ?? this.withdrawalsErrorMessage),
        actionStatus: actionStatus ?? this.actionStatus,
        actionMessage:
            clearActionMessage ? null : (actionMessage ?? this.actionMessage),
        actionFieldErrors: clearActionFieldErrors
            ? null
            : (actionFieldErrors ?? this.actionFieldErrors),
      );

  @override
  List<Object?> get props => [
        status,
        wallet,
        errorMessage,
        withdrawalsStatus,
        withdrawals,
        withdrawalsErrorMessage,
        actionStatus,
        actionMessage,
        actionFieldErrors,
      ];
}

class RiderMeWalletNotifier extends Notifier<RiderMeWalletState> {
  @override
  RiderMeWalletState build() => const RiderMeWalletState();

  RiderMeWalletRepository get _repo => sl<RiderMeWalletRepository>();

  /// Loads the balance and withdrawals independently — a failure on one
  /// must not blank out the other (previously any single failure put the
  /// whole screen into an error state even if the rest had already loaded).
  Future<void> load() async {
    state = state.copyWith(
      status: RiderMeWalletStatus.loading,
      clearError: true,
      withdrawalsStatus: RiderMeWithdrawalsStatus.loading,
      clearWithdrawalsError: true,
    );

    final walletFuture = _repo.getWallet();
    final withdrawalsFuture = _repo.getWithdrawals();

    final walletResult = await walletFuture;
    walletResult.fold(
      (f) => state = state.copyWith(
          status: RiderMeWalletStatus.error, errorMessage: f.message),
      (w) => state = state.copyWith(
          status: RiderMeWalletStatus.loaded, wallet: w, clearError: true),
    );

    final withdrawalsResult = await withdrawalsFuture;
    withdrawalsResult.fold(
      (f) => state = state.copyWith(
          withdrawalsStatus: RiderMeWithdrawalsStatus.error,
          withdrawalsErrorMessage: f.message),
      (w) => state = state.copyWith(
          withdrawalsStatus: RiderMeWithdrawalsStatus.loaded,
          withdrawals: w,
          clearWithdrawalsError: true),
    );
  }

  Future<void> _refreshWithdrawals() async {
    final result = await _repo.getWithdrawals();
    result.fold(
      (_) {}, // best-effort background refresh — stays silent on failure
      (w) => state = state.copyWith(
          withdrawalsStatus: RiderMeWithdrawalsStatus.loaded,
          withdrawals: w,
          clearWithdrawalsError: true),
    );
  }

  /// Requests a withdrawal. There's no idempotency key on this endpoint, so
  /// on any failure we also refresh withdrawals in the background in case
  /// the request actually landed server-side despite a client-perceived
  /// error (per rider-wallet-apis.md #4).
  Future<bool> requestWithdrawal(num amount) async {
    state = state.copyWith(
      actionStatus: RiderMeActionStatus.inProgress,
      clearActionMessage: true,
      clearActionFieldErrors: true,
    );
    final result = await _repo.requestWithdrawal(amount);
    final success = result.fold(
      (f) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.error,
          actionMessage: f.message,
          actionFieldErrors: f is ValidationFailure ? f.errors : null,
        );
        return false;
      },
      (_) {
        state = state.copyWith(actionStatus: RiderMeActionStatus.success);
        return true;
      },
    );
    if (success) {
      // Refetch rather than append locally so the balance the rider sees
      // immediately reflects the server, not a stale pre-withdrawal number.
      await load();
    } else {
      unawaited(_refreshWithdrawals());
    }
    return success;
  }

  Future<bool> cancelWithdrawal(int withdrawalId) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.cancelWithdrawal(withdrawalId);
    final success = result.fold(
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
    // Refetch rather than mutate locally so status/balance always reflect
    // the server, not a client-guessed 'cancelled' value.
    if (success) await load();
    return success;
  }

  void clearActionStatus() => state = state.copyWith(
      actionStatus: RiderMeActionStatus.idle, clearActionFieldErrors: true);
}

final riderMeWalletProvider =
    NotifierProvider<RiderMeWalletNotifier, RiderMeWalletState>(
        RiderMeWalletNotifier.new);
