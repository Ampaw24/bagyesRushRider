import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class RiderCoords extends Equatable {
  final double latitude;
  final double longitude;

  const RiderCoords({required this.latitude, required this.longitude});

  factory RiderCoords.fromJson(Map<String, dynamic> json) => RiderCoords(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  List<Object?> get props => [latitude, longitude];
}

class RiderCustomer extends Equatable {
  final String? name;
  final String? phone;

  const RiderCustomer({this.name, this.phone});

  factory RiderCustomer.fromJson(Map<String, dynamic>? json) => RiderCustomer(
        name: json?['name'] as String?,
        phone: json?['phone'] as String?,
      );

  @override
  List<Object?> get props => [name, phone];
}

class RiderOrderModel extends Equatable {
  final String id;
  final String orderId;
  final String paymentMode;
  final num amount;
  final num charges;
  final num totalAmount;
  final String pickUpLocation;
  final String deliveryLocation;
  final RiderCoords? pickupLocationCoords;
  final RiderCoords? deliveryLocationCoords;
  final String? packageType;
  final String? weight;
  final String? image;
  final String? status;
  final String? tripType;
  final RiderCustomer? customer;
  final String? createdAt;

  const RiderOrderModel({
    required this.id,
    required this.orderId,
    required this.paymentMode,
    required this.amount,
    required this.charges,
    required this.totalAmount,
    required this.pickUpLocation,
    required this.deliveryLocation,
    this.pickupLocationCoords,
    this.deliveryLocationCoords,
    this.packageType,
    this.weight,
    this.image,
    this.status,
    this.tripType,
    this.customer,
    this.createdAt,
  });

  String get amountFormatted => 'GHS ${amount.toStringAsFixed(2)}';
  String get totalFormatted => 'GHS ${totalAmount.toStringAsFixed(2)}';
  bool get isStarted => status == 'started';

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt!);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return createdAt ?? '';
    }
  }

  factory RiderOrderModel.fromJson(Map<String, dynamic> json) {
    return RiderOrderModel(
      id: json['_id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      paymentMode: json['paymentMode'] as String? ?? '',
      amount: json['amount'] as num? ?? 0,
      charges: json['charges'] as num? ?? 0,
      totalAmount: json['totalAmount'] as num? ?? 0,
      pickUpLocation: json['pickUpLocation'] as String? ?? '',
      deliveryLocation: json['deliveryLocation'] as String? ?? '',
      pickupLocationCoords: json['pickupLocationCoords'] != null
          ? RiderCoords.fromJson(
              json['pickupLocationCoords'] as Map<String, dynamic>)
          : null,
      deliveryLocationCoords: json['deliveryLocationCoords'] != null
          ? RiderCoords.fromJson(
              json['deliveryLocationCoords'] as Map<String, dynamic>)
          : null,
      packageType: json['packageType'] as String?,
      weight: json['weight'] as String?,
      image: json['image'] as String?,
      status: json['status'] as String?,
      tripType: json['tripType'] as String?,
      customer: json['customer'] != null
          ? RiderCustomer.fromJson(json['customer'] as Map<String, dynamic>?)
          : null,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'orderId': orderId,
        'paymentMode': paymentMode,
        'amount': amount,
        'charges': charges,
        'totalAmount': totalAmount,
        'pickUpLocation': pickUpLocation,
        'deliveryLocation': deliveryLocation,
        'pickupLocationCoords': pickupLocationCoords?.toJson(),
        'deliveryLocationCoords': deliveryLocationCoords?.toJson(),
        'packageType': packageType,
        'weight': weight,
        'image': image,
        'status': status,
        'tripType': tripType,
        'customer': {'name': customer?.name, 'phone': customer?.phone},
        'createdAt': createdAt,
      };

  RiderOrderModel copyWith({
    String? id,
    String? orderId,
    String? paymentMode,
    num? amount,
    num? charges,
    num? totalAmount,
    String? pickUpLocation,
    String? deliveryLocation,
    RiderCoords? pickupLocationCoords,
    RiderCoords? deliveryLocationCoords,
    String? packageType,
    String? weight,
    String? image,
    String? status,
    String? tripType,
    RiderCustomer? customer,
    String? createdAt,
  }) {
    return RiderOrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      paymentMode: paymentMode ?? this.paymentMode,
      amount: amount ?? this.amount,
      charges: charges ?? this.charges,
      totalAmount: totalAmount ?? this.totalAmount,
      pickUpLocation: pickUpLocation ?? this.pickUpLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      pickupLocationCoords: pickupLocationCoords ?? this.pickupLocationCoords,
      deliveryLocationCoords:
          deliveryLocationCoords ?? this.deliveryLocationCoords,
      packageType: packageType ?? this.packageType,
      weight: weight ?? this.weight,
      image: image ?? this.image,
      status: status ?? this.status,
      tripType: tripType ?? this.tripType,
      customer: customer ?? this.customer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, orderId, status, amount];
}
