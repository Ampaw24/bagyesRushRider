import 'package:equatable/equatable.dart';

import 'package:delivery_boy/core/utils/json_utils.dart';

/// A bank or mobile-money provider from the public `GET /payout-providers`.
class PayoutProviderModel extends Equatable {
  final int id;
  final String type; // bank | mobile_money
  final String name;
  final String? shortName;
  final String? logoUrl;
  final int displayOrder;

  const PayoutProviderModel({
    required this.id,
    required this.type,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.displayOrder = 0,
  });

  bool get isMobileMoney => type == 'mobile_money';

  factory PayoutProviderModel.fromJson(Map<String, dynamic> json) {
    return PayoutProviderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: nonEmptyString(json['short_name']),
      logoUrl: nonEmptyString(json['logo_url']),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, type, name];
}
