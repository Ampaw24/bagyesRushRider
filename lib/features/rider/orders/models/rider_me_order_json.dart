/// Lenient readers for `/rider/me` order and offer payloads.
///
/// The Laravel API resources nest most order data (`order_number`,
/// `vendor{name,address}`, `delivery{address}`, `customer{name,phone}`,
/// `totals{…}`) and serialise decimal columns as strings, while the
/// original Postman examples used flat keys (`pickup_address`, `amount`).
/// Reading only the flat keys left every card showing "-", so each field
/// here tries the nested shape and the flat one.
library;

String? jsonString(Object? value) {
  if (value == null || value is Map || value is List) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

num? jsonNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(jsonString(value) ?? '');
}

int? jsonInt(Object? value) => jsonNum(value)?.toInt();

Map<String, dynamic>? jsonMap(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : null;

/// First non-empty string among [values].
String? firstString(Iterable<Object?> values) {
  for (final v in values) {
    final s = jsonString(v);
    if (s != null) return s;
  }
  return null;
}

/// First value among [values] that parses as a number.
num? firstNum(Iterable<Object?> values) {
  for (final v in values) {
    final n = jsonNum(v);
    if (n != null) return n;
  }
  return null;
}

/// An address that may be a plain string or an object such as
/// `{address, formatted_address, address_line, street, …}`.
String? jsonAddress(Object? value) {
  final plain = jsonString(value);
  if (plain != null) return plain;
  final map = jsonMap(value);
  if (map == null) return null;
  return firstString([
        map['address'],
        map['formatted_address'],
        map['address_line'],
        map['address_line_1'],
        map['street_address'],
        map['street'],
        map['location_name'],
      ]) ??
      jsonAddress(map['address']);
}

/// A person's display name from `{name}` or `{first_name, last_name}`.
String? jsonPersonName(Map<String, dynamic>? person) {
  if (person == null) return null;
  final name = jsonString(person['name']) ?? jsonString(person['full_name']);
  if (name != null) return name;
  final parts = [person['first_name'], person['last_name']]
      .map(jsonString)
      .whereType<String>();
  return parts.isEmpty ? null : parts.join(' ');
}

/// Coordinates from `{latitude, longitude}` or `{lat, lng}`, or `null` when
/// either half is missing — a lone latitude is useless for a map pin.
({double lat, double lng})? jsonLatLng(Map<String, dynamic>? map) {
  if (map == null) return null;
  final lat = jsonNum(map['latitude'] ?? map['lat'])?.toDouble();
  final lng =
      jsonNum(map['longitude'] ?? map['lng'] ?? map['lon'])?.toDouble();
  return (lat != null && lng != null) ? (lat: lat, lng: lng) : null;
}
