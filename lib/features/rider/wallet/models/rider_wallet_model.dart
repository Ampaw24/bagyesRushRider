import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class RiderEarningItem extends Equatable {
  final String? description;
  final num? amount;
  final String? createdAt;

  const RiderEarningItem({this.description, this.amount, this.createdAt});

  String get formattedDate {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return createdAt!;
    }
  }

  DateTime? get date {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!).toLocal();
    } catch (_) {
      return null;
    }
  }

  factory RiderEarningItem.fromJson(Map<String, dynamic> json) =>
      RiderEarningItem(
        description: json['description'] as String?,
        amount: json['amount'] as num?,
        createdAt: json['createdAt'] as String?,
      );

  @override
  List<Object?> get props => [description, amount, createdAt];
}

class RiderWalletModel extends Equatable {
  final String total;
  final List<RiderEarningItem> earnings;

  const RiderWalletModel({this.total = '0', this.earnings = const []});

  factory RiderWalletModel.fromJson(Map<String, dynamic> json) {
    final earningsList = json['earnings'] as List? ?? [];
    return RiderWalletModel(
      total: json['total']?.toString() ?? '0',
      earnings: earningsList
          .map((e) => RiderEarningItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [total, earnings];
}
