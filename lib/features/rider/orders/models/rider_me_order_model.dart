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

  /// Whether this is a parcel delivery rather than a normal order. The offers
  /// response isn't documented, so this is inferred — see [_looksLikeParcel].
  final bool isParcel;

  const RiderMeOfferModel({
    required this.id,
    this.orderReference,
    this.pickupAddress,
    this.dropoffAddress,
    this.distanceKm,
    this.estimatedFare,
    this.expiresAt,
    this.createdAt,
    this.isParcel = false,
  });

  /// Best guess, since the offers payload is undocumented: a parcel if the
  /// offer or its inline order names itself one (`type`, `order_type`,
  /// `kind` or `service_type` containing "parcel"), carries a `parcel`
  /// object / `parcel_id`, or lists `stops` (multi-stop is the parcel API's
  /// model — see the "Parcel orders carry no `customer`" note in
  /// [RiderMeOrderModel.fromJson]). Check against a real offer and tighten.
  static bool _looksLikeParcel(
    Map<String, dynamic> json,
    Map<String, dynamic> order,
  ) {
    for (final source in [json, order]) {
      for (final key in const ['type', 'order_type', 'kind', 'service_type']) {
        if (jsonString(source[key])?.toLowerCase().contains('parcel') ?? false) {
          return true;
        }
      }
      if (source['parcel'] != null || source['parcel_id'] != null) return true;
      final stops = source['stops'];
      if (stops is List && stops.isNotEmpty) return true;
    }
    return false;
  }

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
      isParcel: _looksLikeParcel(json, order),
    );
  }

  /// [expiresAt] as a point in time, or null when absent or unparseable.
  DateTime? get expiresAtTime =>
      expiresAt == null ? null : DateTime.tryParse(expiresAt!);

  @override
  List<Object?> get props => [id, orderReference, expiresAt, isParcel];
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

  /// `waiting` — set once the rider has arrived at this stop; null before.
  final RiderMeOrderWait? wait;

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
    this.wait,
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
      wait: RiderMeOrderWait.fromJson(jsonMap(json['waiting'])),
    );
  }

  @override
  List<Object?> get props => [id, status, wait];
}

/// The wait window that starts when the rider arrives — the order-level
/// `wait` object (`POST …/arrived-at-dropoff`, `GET …/orders/:id`) or a
/// stop's `waiting` object (`POST …/stops/:id/arrived`). Once it runs out the
/// rider may give up (`POST …/unreachable`, or `…/stops/:id/fail`).
class RiderMeOrderWait extends Equatable {
  final DateTime? startedAt;
  final DateTime? expiresAt;

  /// Server-computed seconds left at the moment the response was built.
  final int? secondsLeft;
  final bool hasExpired;

  /// When this payload reached the device. [secondsLeft] is counted down from
  /// here, so the countdown follows the server's clock rather than a phone
  /// clock that may be set wrong.
  final DateTime receivedAt;

  const RiderMeOrderWait({
    this.startedAt,
    this.expiresAt,
    this.secondsLeft,
    this.hasExpired = false,
    required this.receivedAt,
  });

  /// Null when the payload has no `wait` object (not arrived yet).
  static RiderMeOrderWait? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return RiderMeOrderWait(
      // A stop's `waiting` object calls the start `since`.
      startedAt: DateTime.tryParse(
          firstString([json['started_at'], json['since']]) ?? ''),
      expiresAt: DateTime.tryParse(jsonString(json['expires_at']) ?? ''),
      secondsLeft: jsonInt(json['seconds_left']),
      hasExpired: RiderMeOrderModel._isTrue(json['has_expired']),
      receivedAt: DateTime.now(),
    );
  }

  /// Full length of the window, when the server sent both ends of it.
  Duration? get total => (startedAt != null && expiresAt != null)
      ? expiresAt!.difference(startedAt!)
      : null;

  /// Time left at [now]; [Duration.zero] once the window is over.
  Duration remainingAt(DateTime now) {
    if (hasExpired) return Duration.zero;
    final Duration left;
    if (secondsLeft != null) {
      left = Duration(seconds: secondsLeft!) - now.difference(receivedAt);
    } else if (expiresAt != null) {
      left = expiresAt!.difference(now);
    } else {
      return Duration.zero;
    }
    return left.isNegative ? Duration.zero : left;
  }

  @override
  List<Object?> get props =>
      [startedAt, expiresAt, secondsLeft, hasExpired, receivedAt];
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

  /// `parcel.requires_pickup_code` — true on a parcel the *customer is
  /// receiving*. The sender was texted a 4-digit collection code, and the
  /// rider typing it into `pick-up` (as `pickup_pin`) proves they are the
  /// courier that message named. False for food and for parcels the customer
  /// is sending, where the server ignores the field.
  final bool requiresPickupCode;

  /// `timeline.arrived_at_dropoff` — when the rider reached the drop-off.
  final String? arrivedAtDropoffAt;

  /// The customer wait window; null until the rider arrives at the drop-off.
  final RiderMeOrderWait? wait;

  /// `can_give_up` — the server says the rider may mark the customer
  /// unreachable now. Null when the payload doesn't say.
  final bool? canGiveUp;

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
    this.requiresPickupCode = false,
    this.arrivedAtDropoffAt,
    this.wait,
    this.canGiveUp,
  });

  bool get isActive => !_kRiderMeTerminalStatuses.contains(status);
  bool get isMultiStop => stops.length > 1;

  /// The payload says the rider already reached a single drop-off. Multi-stop
  /// orders arrive per stop, so this doesn't describe them.
  bool get hasArrivedAtDropoff =>
      !isMultiStop && (arrivedAtDropoffAt != null || wait != null);
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
    bool? requiresPickupCode,
    String? arrivedAtDropoffAt,
    RiderMeOrderWait? wait,
    bool? canGiveUp,
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
        requiresPickupCode: requiresPickupCode ?? this.requiresPickupCode,
        arrivedAtDropoffAt: arrivedAtDropoffAt ?? this.arrivedAtDropoffAt,
        wait: wait ?? this.wait,
        canGiveUp: canGiveUp ?? this.canGiveUp,
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
      requiresPickupCode:
          _isTrue(jsonMap(json['parcel'])?['requires_pickup_code']),
      arrivedAtDropoffAt:
          jsonString(jsonMap(json['timeline'])?['arrived_at_dropoff']),
      wait: RiderMeOrderWait.fromJson(jsonMap(json['wait'])),
      canGiveUp:
          json['can_give_up'] == null ? null : _isTrue(json['can_give_up']),
    );
  }

  /// Laravel booleans arrive as `true`, `1` or `"1"` depending on the cast.
  static bool _isTrue(Object? value) =>
      value == true || value == 1 || value == '1' || value == 'true';

  @override
  List<Object?> get props =>
      [id, status, amount, requiresPickupCode, wait, canGiveUp];
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
