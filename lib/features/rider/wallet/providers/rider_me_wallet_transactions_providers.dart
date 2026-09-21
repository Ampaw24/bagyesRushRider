import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_me_wallet_repository.dart';

enum RiderMeWalletTransactionsStatus { initial, loading, loaded, error }

/// Read-only ledger state — `GET /rider/me/wallet/transactions`. Kept
/// separate from [RiderMeWalletState] (balance/withdrawals) so the wallet
/// overview and the dedicated transactions page each get an independent
/// load/empty/error lifecycle without one screen's fetch affecting the
/// other's spinner.
class RiderMeWalletTransactionsState extends Equatable {
  final RiderMeWalletTransactionsStatus status;
  final List<RiderMeWalletTransactionModel> transactions;
  final String? errorMessage;

  const RiderMeWalletTransactionsState({
    this.status = RiderMeWalletTransactionsStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  RiderMeWalletTransactionsState copyWith({
    RiderMeWalletTransactionsStatus? status,
    List<RiderMeWalletTransactionModel>? transactions,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderMeWalletTransactionsState(
        status: status ?? this.status,
        transactions: transactions ?? this.transactions,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, transactions, errorMessage];
}

class RiderMeWalletTransactionsNotifier
    extends Notifier<RiderMeWalletTransactionsState> {
  @override
  RiderMeWalletTransactionsState build() =>
      const RiderMeWalletTransactionsState();

  RiderMeWalletRepository get _repo => sl<RiderMeWalletRepository>();

  Future<void> load() async {
    state = state.copyWith(
        status: RiderMeWalletTransactionsStatus.loading, clearError: true);
    final result = await _repo.getTransactions();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderMeWalletTransactionsStatus.error,
          errorMessage: f.message),
      (transactions) => state = state.copyWith(
          status: RiderMeWalletTransactionsStatus.loaded,
          transactions: transactions),
    );
  }
}

final riderMeWalletTransactionsProvider = NotifierProvider<
    RiderMeWalletTransactionsNotifier,
    RiderMeWalletTransactionsState>(RiderMeWalletTransactionsNotifier.new);
