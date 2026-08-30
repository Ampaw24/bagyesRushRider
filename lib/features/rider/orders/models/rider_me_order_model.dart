import 'package:equatable/equatable.dart';

/// Statuses documented for `GET /rider/me/orders` — see
/// the "v1 / rider" Postman collection (order #4).
const List<String> kRiderMeOrderStatuses = [
  'pending_payment',
  'pending',
  'accepted',
  'preparing',
  'ready',
  'out_for_delivery',
  'delivered',
  'cancelled',
  'rejected',
  'refunded',
];

const List<String> _kRiderMeTerminalStatuses = [
  'delivered',
  'cancelled',
  'rejected',
  'refunded',
];

/// A delivery offer awaiting rider acceptance — `GET /rider/me/offers`.
class RiderMeOfferModel extends Equatable {
  final int id;
  final String? orderReference;
  final String? pickupAddress;
  final String? dropoffAddress;
  final num? distanceKm;
  final num? estimatedFare;
  final String? expiresAt;
  final String? createdAt;

  const RiderMeOfferModel({
    required this.id,
    this.orderReference,
    this.pickupAddress,
    this.dropoffAddress,
    this.distanceKm,
    this.estimatedFare,
    this.expiresAt,
    this.createdAt,
  });

  factory RiderMeOfferModel.fromJson(Map<String, dynamic> json) {
    return RiderMeOfferModel(
      id: json['id'] as int,
      orderReference: json['order_reference'] as String? ??
          json['reference'] as String?,
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      distanceKm: json['distance_km'] as num?,
      estimatedFare: json['estimated_fare'] as num?,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, orderReference, expiresAt];
}

/// One stop of a multi-stop delivery order.
class RiderMeOrderStopModel extends Equatable {
  final int id;
  final int? sequence;
  final String? address;
  final String? status;
  final String? deliveredToName;
  final String? deliveredAt;
  final String? failureReason;

  const RiderMeOrderStopModel({
    required this.id,
    this.sequence,
    this.address,
    this.status,
    this.deliveredToName,
    this.deliveredAt,
    this.failureReason,
  });

  bool get isDelivered => status == 'delivered';
  bool get isFailed => status == 'failed';

  factory RiderMeOrderStopModel.fromJson(Map<String, dynamic> json) {
    return RiderMeOrderStopModel(
      id: json['id'] as int,
      sequence: json['sequence'] as int?,
      address: json['address'] as String?,
      status: json['status'] as String?,
      deliveredToName: json['delivered_to_name'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      failureReason: json['failure_reason'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status];
}

/// A rider's order — `GET /rider/me/orders`, `GET /rider/me/orders/:id`.
class RiderMeOrderModel extends Equatable {
  final int id;
  final String? reference;
  final String status;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? customerName;
  final String? customerPhone;
  final num? amount;
  final List<RiderMeOrderStopModel> stops;
  final String? createdAt;
  final String? updatedAt;

  const RiderMeOrderModel({
    required this.id,
    this.reference,
    required this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.customerName,
    this.customerPhone,
    this.amount,
    this.stops = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => !_kRiderMeTerminalStatuses.contains(status);
  bool get isMultiStop => stops.length > 1;
  String get amountFormatted =>
      amount != null ? 'GHS ${amount!.toStringAsFixed(2)}' : '';

  factory RiderMeOrderModel.fromJson(Map<String, dynamic> json) {
    final stopsList = json['stops'] as List? ?? const [];
    return RiderMeOrderModel(
      id: json['id'] as int,
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'pending',
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      amount: json['amount'] as num?,
      stops: stopsList
          .map((e) =>
              RiderMeOrderStopModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, amount];
}
