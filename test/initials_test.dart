import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gopady_rider/core/utils/initials.dart';
import 'package:gopady_rider/features/rider/orders/views/widgets/rider_order_detail_sections.dart';

void main() {
  group('initialsOf', () {
    test('takes the first and last words', () {
      expect(initialsOf('Kofi Asante'), 'KA');
      expect(initialsOf('kofi ama asante'), 'KA');
      expect(initialsOf('  Ama  '), 'A');
    });

    test('falls back for a blank name', () {
      expect(initialsOf(null), '?');
      expect(initialsOf('   '), '?');
      expect(initialsOf('', fallback: 'R'), 'R');
    });

    test('keeps characters outside the BMP whole', () {
      // `word[0]` would return half a surrogate pair for each of these.
      expect(initialsOf('😊 Ama'), '😊A');
      expect(initialsOf('𝐀𝐦𝐚 Mensah'), '𝐀M');
      expect(initialsOf('Kofi 🇬🇭'), 'K🇬🇭');
    });
  });

  // The crash this guards against: "string is not well-formed UTF-16",
  // thrown laying out the order sheet's customer avatar.
  testWidgets('the customer tile renders a name that starts with an emoji',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OrderCustomerTile(
          name: '😊 Ama Mensah',
          phone: '0240000000',
          onCall: () {},
          onChat: () {},
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('😊M'), findsOneWidget);
  });
}
