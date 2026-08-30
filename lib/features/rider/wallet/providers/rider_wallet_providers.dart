import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/wallet/models/rider_wallet_model.dart';
import 'package:delivery_boy/features/rider/wallet/repositories/rider_wallet_repository.dart';

enum WalletStatus { initial, loading, loaded, error }

enum EarningsPeriod { all, today, thisWeek, thisMonth }

class RiderWalletState extends Equatable {
  final WalletStatus status;
  final RiderWalletModel? wallet;
  final String? errorMessage;
  final EarningsPeriod period;

  const RiderWalletState({
    this.status = WalletStatus.initial,
    this.wallet,
    this.errorMessage,
    this.period = EarningsPeriod.all,
  });

  RiderWalletState copyWith({
    WalletStatus? status,
    RiderWalletModel? wallet,
    String? errorMessage,
    EarningsPeriod? period,
    bool clearError = false,
  }) =>
      RiderWalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        period: period ?? this.period,
      );

  List<RiderEarningItem> get filteredEarnings {
    final all = wallet?.earnings ?? [];
    if (period == EarningsPeriod.all) return all;

    final now = DateTime.now();
    return all.where((item) {
      final d = item.date;
      if (d == null) return false;
      return switch (period) {
        EarningsPeriod.today =>
          d.year == now.year && d.month == now.month && d.day == now.day,
        EarningsPeriod.thisWeek => now.difference(d).inDays < 7,
        EarningsPeriod.thisMonth =>
          d.year == now.year && d.month == now.month,
        EarningsPeriod.all => true,
      };
    }).toList();
  }

  double _subtotal(EarningsPeriod p) {
    final now = DateTime.now();
    return (wallet?.earnings ?? []).fold(0.0, (sum, item) {
      final d = item.date;
      if (d == null) return sum;
      final matches = switch (p) {
        EarningsPeriod.today =>
          d.year == now.year && d.month == now.month && d.day == now.day,
        EarningsPeriod.thisWeek => now.difference(d).inDays < 7,
        EarningsPeriod.thisMonth =>
          d.year == now.year && d.month == now.month,
        EarningsPeriod.all => true,
      };
      return matches ? sum + (item.amount?.toDouble() ?? 0) : sum;
    });
  }

  double get todayTotal => _subtotal(EarningsPeriod.today);
  double get weekTotal => _subtotal(EarningsPeriod.thisWeek);
  double get monthTotal => _subtotal(EarningsPeriod.thisMonth);

  @override
  List<Object?> get props => [status, wallet, errorMessage, period];
}

class RiderWalletNotifier extends Notifier<RiderWalletState> {
  @override
  RiderWalletState build() => const RiderWalletState();

  RiderWalletRepository get _repo => sl<RiderWalletRepository>();

  Future<void> load() async {
    final userId =
        sl<UserSessionManager>().userId ?? '';
    state = state.copyWith(status: WalletStatus.loading, clearError: true);
    final result = await _repo.getEarnings(userId);
    result.fold(
      (f) => state =
          state.copyWith(status: WalletStatus.error, errorMessage: f.message),
      (wallet) =>
          state = state.copyWith(status: WalletStatus.loaded, wallet: wallet),
    );
  }

  void setPeriod(EarningsPeriod p) => state = state.copyWith(period: p);
}

final riderWalletProvider =
    NotifierProvider<RiderWalletNotifier, RiderWalletState>(
        RiderWalletNotifier.new);
