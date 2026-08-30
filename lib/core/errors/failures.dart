abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// A 422 carrying per-field messages, e.g.
/// `{phone: ["The phone has already been taken."]}`.
///
/// Still a [Failure], so existing `f.message` call sites are unaffected —
/// callers that want to place an error on a specific input opt in by
/// checking `is ValidationFailure`.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, this.errors);

  final Map<String, List<String>> errors;

  /// First message for [field], or null when the field wasn't rejected.
  String? firstFor(String field) {
    final list = errors[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  /// True when [field] failed a uniqueness rule — the useful recovery for
  /// these is signing in, not editing.
  bool isTaken(String field) {
    final msg = firstFor(field);
    return msg != null && RegExp(r'already been taken', caseSensitive: false).hasMatch(msg);
  }
}
