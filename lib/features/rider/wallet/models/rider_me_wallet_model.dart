import 'package:equatable/equatable.dart';

/// Rider wallet balance — `GET /rider/me/wallet`.
class RiderMeWalletModel extends Equatable {
  final num balance;
  final num? availableBalance;
  final num? pendingBalance;
  final String currency;

  const RiderMeWalletModel({
    this.balance = 0,
    this.availableBalance,
    this.pendingBalance,
    this.currency = 'GHS',
  });

  String get balanceFormatted => '$currency ${balance.toStringAsFixed(2)}';

  factory RiderMeWalletModel.fromJson(Map<String, dynamic> json) {
    return RiderMeWalletModel(
      balance: json['balance'] as num? ?? 0,
      availableBalance: json['available_balance'] as num?,
      pendingBalance: json['pending_balance'] as num?,
      currency: json['currency'] as String? ?? 'GHS',
    );
  }

  @override
  List<Object?> get props => [balance, availableBalance, pendingBalance];
}

/// A single wallet ledger entry — `GET /rider/me/wallet/transactions`.
class RiderMeWalletTransactionModel extends Equatable {
  final int id;
  final String? type; // credit | debit
  final num? amount;
  final String? description;
  final String? status;
  final String? createdAt;

  const RiderMeWalletTransactionModel({
    required this.id,
    this.type,
    this.amount,
    this.description,
    this.status,
    this.createdAt,
  });

  bool get isCredit => type == 'credit';

  factory RiderMeWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return RiderMeWalletTransactionModel(
      id: json['id'] as int,
      type: json['type'] as String?,
      amount: json['amount'] as num?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, type, amount, createdAt];
}

/// A withdrawal request — `GET|POST /rider/me/withdrawals`.
class RiderMeWithdrawalModel extends Equatable {
  final int id;
  final num amount;
  final String? status; // pending | approved | rejected | cancelled
  final String? createdAt;
  final String? processedAt;

  const RiderMeWithdrawalModel({
    required this.id,
    required this.amount,
    this.status,
    this.createdAt,
    this.processedAt,
  });

  bool get isCancellable => status == 'pending';

  factory RiderMeWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return RiderMeWithdrawalModel(
      id: json['id'] as int,
      amount: json['amount'] as num? ?? 0,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      processedAt: json['processed_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, amount, status];
}
