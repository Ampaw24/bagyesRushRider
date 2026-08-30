/// Helpers for reading the API's error envelope:
/// `{success: false, message: "Validation failed", errors: {field: ["msg"]}}`
///
/// Kept as top-level functions so every repository shares one implementation
/// and they can be unit-tested without Dio.
library;

/// The most actionable message in an error body.
///
/// Prefers the first field error over the top-level `message`: a 422 says
/// "Validation failed" at the top and "The phone has already been taken."
/// under `errors` — only the latter tells the user what to do.
String? apiMessageFrom(dynamic data) {
  if (data is! Map) return null;

  final errors = data['errors'];
  if (errors is Map && errors.isNotEmpty) {
    final first = errors.values.first;
    if (first is List && first.isNotEmpty) return first.first.toString();
    if (first is String) return first;
  }

  final message = data['message'];
  return message is String ? message : null;
}

/// Per-field errors, normalised to `Map<String, List<String>>`.
///
/// Tolerates a bare-String value (`{"phone": "msg"}`) as well as the usual
/// list form. Returns null when the body carries no field errors — which is
/// how callers distinguish a validation failure from any other error.
Map<String, List<String>>? apiFieldErrorsFrom(dynamic data) {
  if (data is! Map) return null;

  final errors = data['errors'];
  if (errors is! Map || errors.isEmpty) return null;

  final parsed = <String, List<String>>{};
  errors.forEach((key, value) {
    final field = key.toString();
    if (value is List) {
      parsed[field] = value.map((e) => e.toString()).toList();
    } else if (value is String) {
      parsed[field] = [value];
    }
  });

  return parsed.isEmpty ? null : parsed;
}
