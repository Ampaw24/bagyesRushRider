import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A real 422 from POST /register, captured from the live backend.
  const validation422 = {
    'success': false,
    'message': 'Validation failed',
    'errors': {
      'plate_number': ['The plate number has already been taken.'],
      'city': ['City is required for vendor registration'],
    },
  };

  group('apiMessageFrom', () {
    test('prefers the field error over the boilerplate top-level message', () {
      // "Validation failed" tells the user nothing actionable.
      expect(
        apiMessageFrom(validation422),
        'The plate number has already been taken.',
      );
    });

    test('falls back to the top-level message when there are no field errors',
        () {
      expect(
        apiMessageFrom({'success': false, 'message': 'Unauthenticated.'}),
        'Unauthenticated.',
      );
    });

    test('returns null for a non-Map body rather than throwing', () {
      // An HTML error page used to blow up on data['message'].
      expect(apiMessageFrom('<html>502 Bad Gateway</html>'), isNull);
      expect(apiMessageFrom(null), isNull);
    });
  });

  group('apiFieldErrorsFrom', () {
    test('normalises the list form', () {
      final parsed = apiFieldErrorsFrom(validation422);
      expect(parsed, isNotNull);
      expect(parsed!['plate_number'],
          ['The plate number has already been taken.']);
      expect(parsed.keys, containsAll(['plate_number', 'city']));
    });

    test('tolerates a bare string value', () {
      final parsed = apiFieldErrorsFrom({
        'errors': {'phone': 'Phone number is required'}
      });
      expect(parsed!['phone'], ['Phone number is required']);
    });

    test('returns null when there are no field errors', () {
      expect(apiFieldErrorsFrom({'message': 'Unauthenticated.'}), isNull);
      expect(apiFieldErrorsFrom({'errors': {}}), isNull);
      expect(apiFieldErrorsFrom('not a map'), isNull);
    });
  });

  group('ValidationFailure', () {
    final failure = ValidationFailure(
      apiMessageFrom(validation422)!,
      apiFieldErrorsFrom(validation422)!,
    );

    test('exposes per-field lookup', () {
      expect(failure.firstFor('plate_number'),
          'The plate number has already been taken.');
      expect(failure.firstFor('email'), isNull);
    });

    test('detects uniqueness violations, which route to "Sign in"', () {
      expect(failure.isTaken('plate_number'), isTrue);
      expect(failure.isTaken('city'), isFalse);
      expect(failure.isTaken('email'), isFalse);
    });

    test('is a Failure, so existing f.message call sites still work', () {
      expect(failure, isA<Failure>());
      expect(failure.message, 'The plate number has already been taken.');
    });
  });
}
