import 'package:delivery_boy/features/rider/shared_widgets/password_strength_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluatePasswordStrength', () {
    test('anything under 8 chars is weak, however complex', () {
      // The regression this guards: "Ab1!" satisfies uppercase + digit +
      // special, which used to score 3/4 → medium → cleared the signup gate,
      // then failed the backend's min:8.
      expect(evaluatePasswordStrength('Ab1!'), PasswordStrength.weak);
      expect(evaluatePasswordStrength('Aa1!Bb2'), PasswordStrength.weak); // 7
      expect(evaluatePasswordStrength(''), PasswordStrength.weak);
    });

    test('8+ chars with no variety is still weak', () {
      expect(evaluatePasswordStrength('abcdefgh'), PasswordStrength.weak);
    });

    test('8+ chars with some variety is medium', () {
      expect(evaluatePasswordStrength('abcdefg1'), PasswordStrength.medium);
      expect(evaluatePasswordStrength('Abcdefg1'), PasswordStrength.medium);
    });

    test('8+ chars meeting every criterion is strong', () {
      expect(evaluatePasswordStrength('Abcd1234!'), PasswordStrength.strong);
    });

    test('non-weak implies the backend length rule is met', () {
      // The property the signup gate relies on.
      for (final p in ['abcdefg1', 'Abcd1234!', 'Passw0rd']) {
        if (evaluatePasswordStrength(p) != PasswordStrength.weak) {
          expect(p.length, greaterThanOrEqualTo(8), reason: p);
        }
      }
    });
  });
}
