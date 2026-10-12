import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/core/utils/phone_mask.dart';

void main() {
  test('keeps the first three and last two digits', () {
    expect(maskPhone('0240000000'), '024•••••00');
    expect(maskPhone('+233504123746'), '+233•••••••46');
  });

  test('keeps spacing in place', () {
    expect(maskPhone('024 123 4567'), '024 ••• ••67');
  });

  test('a short number shows only its last two digits', () {
    expect(maskPhone('12345'), '•••45');
    expect(maskPhone(''), '');
  });
}
