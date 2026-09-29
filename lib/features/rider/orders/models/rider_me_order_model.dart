import 'package:equatable/equatable.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_json.dart';

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
    // An offer may carry its order inline (`order{…}`) rather than
    // flattening the order's fields onto itself.
    final order = jsonMap(json['order']) ?? const <String, dynamic>{};
    final fields = RiderMeOrderFields(json, fallback: order);
    return RiderMeOfferModel(
      id: jsonInt(json['id']) ?? 0,
      orderReference: firstString([
        json['order_reference'],
        json['order_number'],
        json['reference'],
        order['order_number'],
        order['reference'],
      ]),
      pickupAddress: fields.pickupAddress,
      dropoffAddress: fields.dropoffAddress,
      distanceKm: firstNum([
        json['distance_km'],
        json['delivery_distance_km'],
        order['distance_km'],
        order['delivery_distance_km'],
      ]),
      estimatedFare: firstNum([
        json['estimated_fare'],
        json['fare'],
        json['rider_earning'],
        json['earning'],
        json['delivery_fee'],
        order['rider_earning'],
        order['delivery_fee'],
        jsonMap(order['totals'])?['delivery_fee'],
      ]),
      expiresAt: jsonString(json['expires_at']),
      createdAt: jsonString(json['created_at']),
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

  /// Who this stop is being delivered to — on parcel orders the person the
  /// rider actually deals with at the drop-off.
  final String? recipientName;
  final String? recipientPhone;
  final double? latitude;
  final double? longitude;
  final String? deliveredToName;
  final String? deliveredAt;
  final String? failureReason;

  const RiderMeOrderStopModel({
    required this.id,
    this.sequence,
    this.address,
    this.status,
    this.recipientName,
    this.recipientPhone,
    this.latitude,
    this.longitude,
    this.deliveredToName,
    this.deliveredAt,
    this.failureReason,
  });

  bool get isDelivered => status == 'delivered';
  bool get isFailed => status == 'failed';

  factory RiderMeOrderStopModel.fromJson(Map<String, dynamic> json) {
    final recipient = jsonMap(json['recipient']);
    final coords = jsonLatLng(json) ??
        jsonLatLng(jsonMap(json['location'])) ??
        jsonLatLng(jsonMap(json['address']));
    return RiderMeOrderStopModel(
      id: jsonInt(json['id']) ?? 0,
      sequence: jsonInt(json['sequence'] ?? json['position']),
      address: jsonAddress(json['address']) ??
          jsonAddress(json['dropoff']) ??
          jsonAddress(json['delivery']) ??
          jsonAddress(json['location']) ??
          jsonString(json['dropoff_address']),
      status: jsonString(json['status']),
      recipientName:
          jsonString(json['recipient_name']) ?? jsonPersonName(recipient),
      recipientPhone: jsonString(json['recipient_phone']) ??
          jsonString(recipient?['phone']),
      latitude: coords?.lat,
      longitude: coords?.lng,
      deliveredToName: jsonString(json['delivered_to_name']),
      deliveredAt: jsonString(json['delivered_at']),
      failureReason: jsonString(json['failure_reason']),
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

  /// Server coordinates, when sent — exact pins and navigation targets,
  /// preferred over geocoding the address text.
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
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
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
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

  RiderMeOrderModel copyWith({
    int? id,
    String? reference,
    String? status,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? customerName,
    String? customerPhone,
    num? amount,
    List<RiderMeOrderStopModel>? stops,
    String? createdAt,
    String? updatedAt,
  }) =>
      RiderMeOrderModel(
        id: id ?? this.id,
        reference: reference ?? this.reference,
        status: status ?? this.status,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        dropoffAddress: dropoffAddress ?? this.dropoffAddress,
        pickupLatitude: pickupLatitude ?? this.pickupLatitude,
        pickupLongitude: pickupLongitude ?? this.pickupLongitude,
        dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
        dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        amount: amount ?? this.amount,
        stops: stops ?? this.stops,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory RiderMeOrderModel.fromJson(Map<String, dynamic> json) {
    final stopsList = json['stops'] as List? ?? const [];
    final stops = stopsList
        .whereType<Map>()
        .map((e) => RiderMeOrderStopModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    final fields = RiderMeOrderFields(json);
    // Parcel orders carry no `customer`: the contact is the recipient of
    // the stop being worked — `next_stop`, else the first open stop.
    final nextStop = jsonMap(json['next_stop']);
    final contactStop = nextStop != null
        ? RiderMeOrderStopModel.fromJson(nextStop)
        : stops.where((s) => !s.isDelivered && !s.isFailed).firstOrNull ??
            stops.firstOrNull;
    return RiderMeOrderModel(
      id: jsonInt(json['id']) ?? 0,
      reference: firstString([
        json['reference'],
        json['order_number'],
        json['order_reference'],
      ]),
      status: jsonString(json['status']) ?? 'pending',
      pickupAddress: fields.pickupAddress,
      dropoffAddress: fields.dropoffAddress ??
          (stops.length == 1 ? stops.first.address : null),
      pickupLatitude: fields.pickupCoords?.lat,
      pickupLongitude: fields.pickupCoords?.lng,
      dropoffLatitude: fields.dropoffCoords?.lat ??
          (stops.length == 1 ? stops.first.latitude : null),
      dropoffLongitude: fields.dropoffCoords?.lng ??
          (stops.length == 1 ? stops.first.longitude : null),
      customerName: fields.customerName ?? contactStop?.recipientName,
      customerPhone: fields.customerPhone ?? contactStop?.recipientPhone,
      amount: fields.amount,
      stops: stops,
      createdAt: jsonString(json['created_at']),
      updatedAt: jsonString(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, status, amount];
}

/// Reads the order fields shared by orders and offers from either the flat
/// or the nested payload shape — see `rider_me_order_json.dart`.
class RiderMeOrderFields {
  final Map<String, dynamic> _json;
  final Map<String, dynamic> _fallback;

  RiderMeOrderFields(this._json, {Map<String, dynamic>? fallback})
      : _fallback = fallback ?? const {};

  Map<String, dynamic>? _nested(String key) =>
      jsonMap(_json[key]) ?? jsonMap(_fallback[key]);

  Object? _flat(String key) => _json[key] ?? _fallback[key];

  String? get pickupAddress {
    final vendor = _nested('vendor') ?? _nested('restaurant');
    return jsonString(_flat('pickup_address')) ??
        jsonAddress(_nested('pickup')) ??
        jsonAddress(_nested('collection')) ??
        jsonAddress(vendor) ??
        jsonString(_flat('vendor_address')) ??
        // No address on file: the vendor's name still tells the rider
        // where to go.
        jsonString(vendor?['name']) ??
        jsonString(_flat('vendor_name'));
  }

  ({double lat, double lng})? get pickupCoords {
    final flat = jsonLatLng({
      'latitude': _flat('pickup_latitude'),
      'longitude': _flat('pickup_longitude'),
    });
    return flat ??
        jsonLatLng(_nested('pickup')) ??
        jsonLatLng(_nested('collection')) ??
        jsonLatLng(_nested('vendor') ?? _nested('restaurant'));
  }

  ({double lat, double lng})? get dropoffCoords {
    final flat = jsonLatLng({
      'latitude': _flat('dropoff_latitude') ?? _flat('delivery_latitude'),
      'longitude': _flat('dropoff_longitude') ?? _flat('delivery_longitude'),
    });
    return flat ?? jsonLatLng(_nested('dropoff')) ?? jsonLatLng(_nested('delivery'));
  }

  String? get dropoffAddress =>
      jsonString(_flat('dropoff_address')) ??
      jsonString(_flat('delivery_address')) ??
      jsonAddress(_nested('dropoff')) ??
      jsonAddress(_nested('delivery'));

  // `GET /rider/me/orders/:id` puts the customer on the drop-off itself —
  // `dropoff: {name, phone, address, …}` — with no top-level `customer`.
  String? get customerName =>
      jsonString(_flat('customer_name')) ??
      jsonPersonName(_nested('customer')) ??
      jsonPersonName(_nested('dropoff')) ??
      jsonString(_nested('delivery')?['contact_name']) ??
      jsonString(_nested('delivery')?['recipient_name']);

  String? get customerPhone => _dialable(
        jsonString(_flat('customer_phone')) ??
            jsonString(_nested('customer')?['phone']) ??
            jsonString(_nested('dropoff')?['phone']) ??
            jsonString(_nested('delivery')?['contact_phone']) ??
            jsonString(_nested('delivery')?['recipient_phone']),
      );

  /// The API sends international numbers without the `+` (`233504123746`).
  /// A `tel:` link needs it — without it the dialer treats the digits as a
  /// local number. A local-format number (`0504…`, 10 digits) is left as is.
  static String? _dialable(String? phone) {
    if (phone == null) return null;
    final trimmed = phone.trim();
    final isBareInternational =
        RegExp(r'^\d{11,15}$').hasMatch(trimmed) && !trimmed.startsWith('0');
    return isBareInternational ? '+$trimmed' : trimmed;
  }

  /// What the rider earns where the payload says so, else the delivery
  /// fee, else the order total.
  num? get amount {
    final totals = _nested('totals');
    return firstNum([
      _flat('rider_earning'),
      _flat('rider_earnings'),
      _flat('earning'),
      _flat('amount'),
      _flat('delivery_fee'),
      totals?['delivery_fee'],
      _flat('total'),
      totals?['total'],
    ]);
  }
}
