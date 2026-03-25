import 'package:equatable/equatable.dart';

class RiderEarningItem extends Equatable {
  final String? description;

  const RiderEarningItem({this.description});

  factory RiderEarningItem.fromJson(Map<String, dynamic> json) =>
      RiderEarningItem(description: json['description'] as String?);

  @override
  List<Object?> get props => [description];
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
