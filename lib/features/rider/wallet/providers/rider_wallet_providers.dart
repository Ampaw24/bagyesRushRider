import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_wallet_repository.dart';

enum WalletStatus { initial, loading, loaded, error }

class RiderWalletState extends Equatable {
  final WalletStatus status;
  final RiderWalletModel? wallet;
  final String? errorMessage;

  const RiderWalletState({
    this.status = WalletStatus.initial,
    this.wallet,
    this.errorMessage,
  });

  RiderWalletState copyWith({
    WalletStatus? status,
    RiderWalletModel? wallet,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderWalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, wallet, errorMessage];
}

class RiderWalletNotifier extends Notifier<RiderWalletState> {
  @override
  RiderWalletState build() => const RiderWalletState();

  RiderWalletRepository get _repo => sl<RiderWalletRepository>();

  Future<void> load() async {
    final userId =
        sl<UserSessionManager>().currentUser?['_id'] as String? ?? '';
    state = state.copyWith(status: WalletStatus.loading, clearError: true);
    final result = await _repo.getEarnings(userId);
    result.fold(
      (f) => state =
          state.copyWith(status: WalletStatus.error, errorMessage: f.message),
      (wallet) =>
          state = state.copyWith(status: WalletStatus.loaded, wallet: wallet),
    );
  }
}

final riderWalletProvider =
    NotifierProvider<RiderWalletNotifier, RiderWalletState>(
        RiderWalletNotifier.new);
