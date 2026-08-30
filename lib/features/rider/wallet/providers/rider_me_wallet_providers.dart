import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_me_wallet_repository.dart';

enum RiderMeWalletStatus { initial, loading, loaded, error }

class RiderMeWalletState extends Equatable {
  final RiderMeWalletStatus status;
  final RiderMeWalletModel? wallet;
  final List<RiderMeWalletTransactionModel> transactions;
  final List<RiderMeWithdrawalModel> withdrawals;
  final String? errorMessage;
  final RiderMeActionStatus actionStatus;
  final String? actionMessage;

  const RiderMeWalletState({
    this.status = RiderMeWalletStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.withdrawals = const [],
    this.errorMessage,
    this.actionStatus = RiderMeActionStatus.idle,
    this.actionMessage,
  });

  RiderMeWalletState copyWith({
    RiderMeWalletStatus? status,
    RiderMeWalletModel? wallet,
    List<RiderMeWalletTransactionModel>? transactions,
    List<RiderMeWithdrawalModel>? withdrawals,
    String? errorMessage,
    bool clearError = false,
    RiderMeActionStatus? actionStatus,
    String? actionMessage,
    bool clearActionMessage = false,
  }) =>
      RiderMeWalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        transactions: transactions ?? this.transactions,
        withdrawals: withdrawals ?? this.withdrawals,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        actionStatus: actionStatus ?? this.actionStatus,
        actionMessage: clearActionMessage
            ? null
            : (actionMessage ?? this.actionMessage),
      );

  @override
  List<Object?> get props => [
        status,
        wallet,
        transactions,
        withdrawals,
        errorMessage,
        actionStatus,
        actionMessage,
      ];
}

class RiderMeWalletNotifier extends Notifier<RiderMeWalletState> {
  @override
  RiderMeWalletState build() => const RiderMeWalletState();

  RiderMeWalletRepository get _repo => sl<RiderMeWalletRepository>();

  Future<void> load() async {
    state = state.copyWith(
        status: RiderMeWalletStatus.loading, clearError: true);

    final walletResult = await _repo.getWallet();
    final txResult = await _repo.getTransactions();
    final withdrawalsResult = await _repo.getWithdrawals();

    String? errorMessage;
    walletResult.fold((f) => errorMessage ??= f.message, (_) {});
    txResult.fold((f) => errorMessage ??= f.message, (_) {});
    withdrawalsResult.fold((f) => errorMessage ??= f.message, (_) {});

    if (errorMessage != null) {
      state = state.copyWith(
          status: RiderMeWalletStatus.error, errorMessage: errorMessage);
      return;
    }

    state = state.copyWith(
      status: RiderMeWalletStatus.loaded,
      wallet: walletResult.fold((_) => null, (w) => w),
      transactions: txResult.fold((_) => const [], (t) => t),
      withdrawals: withdrawalsResult.fold((_) => const [], (w) => w),
    );
  }

  Future<bool> requestWithdrawal(num amount) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.requestWithdrawal(amount);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (withdrawal) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.success,
          withdrawals: [withdrawal, ...state.withdrawals],
        );
        return true;
      },
    );
  }

  Future<bool> cancelWithdrawal(int withdrawalId) async {
    state = state.copyWith(
        actionStatus: RiderMeActionStatus.inProgress, clearActionMessage: true);
    final result = await _repo.cancelWithdrawal(withdrawalId);
    return result.fold(
      (f) {
        state = state.copyWith(
            actionStatus: RiderMeActionStatus.error, actionMessage: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          actionStatus: RiderMeActionStatus.success,
          withdrawals: state.withdrawals
              .map((w) => w.id == withdrawalId
                  ? RiderMeWithdrawalModel(
                      id: w.id,
                      amount: w.amount,
                      status: 'cancelled',
                      createdAt: w.createdAt,
                      processedAt: w.processedAt,
                    )
                  : w)
              .toList(),
        );
        return true;
      },
    );
  }

  void clearActionStatus() =>
      state = state.copyWith(actionStatus: RiderMeActionStatus.idle);
}

final riderMeWalletProvider =
    NotifierProvider<RiderMeWalletNotifier, RiderMeWalletState>(
        RiderMeWalletNotifier.new);
