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
      balance: _num(json['balance']) ?? 0,
      availableBalance: _num(json['available_balance']),
      pendingBalance: _num(json['pending_balance']),
      currency: json['currency'] as String? ?? 'GHS',
    );
  }

  @override
  List<Object?> get props => [balance, availableBalance, pendingBalance];
}

/// Which side of the ledger a transaction falls on. `unknown` covers a
/// `type` value outside the documented sets (rider earning/withdrawal-debit
/// types aren't documented at all — see doc note 7) so the UI never guesses.
enum RiderMeWalletTxDirection { credit, debit, unknown }

const _creditTxTypes = {'credit', 'admin_credit', 'bonus', 'compensation'};
const _debitTxTypes = {'debit', 'admin_debit'};

/// A single wallet ledger entry — `GET /rider/me/wallet/transactions`.
class RiderMeWalletTransactionModel extends Equatable {
  final int id;

  /// Open string — only admin-initiated types are documented
  /// (`admin_credit`, `admin_debit`, `bonus`, `compensation`, `adjustment`).
  /// Rider earning/withdrawal-debit types exist but aren't documented.
  final String? type;
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

  RiderMeWalletTxDirection get direction {
    if (type != null) {
      if (_creditTxTypes.contains(type)) return RiderMeWalletTxDirection.credit;
      if (_debitTxTypes.contains(type)) return RiderMeWalletTxDirection.debit;
    }
    if (amount != null && amount != 0) {
      return amount! > 0
          ? RiderMeWalletTxDirection.credit
          : RiderMeWalletTxDirection.debit;
    }
    return RiderMeWalletTxDirection.unknown;
  }

  bool get isCredit => direction != RiderMeWalletTxDirection.debit;

  factory RiderMeWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return RiderMeWalletTransactionModel(
      id: _int(json['id']) ?? 0,
      type: json['type'] as String?,
      amount: _num(json['amount']),
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

  /// `pending | approved | paid | rejected | cancelled | reversed` — the
  /// enum documented in the admin `withdrawals` folder (the rider folder
  /// itself never states it). Only `pending` is plausibly cancellable.
  final String? status;
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
      id: _int(json['id']) ?? 0,
      amount: _num(json['amount']) ?? 0,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      processedAt: json['processed_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, amount, status];
}

/// Amounts are documented as `numeric` major units and may arrive as either
/// a JSON number or a numeric string — never cast directly.
num? _num(Object? value) =>
    value is num ? value : num.tryParse('${value ?? ''}');

int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');
