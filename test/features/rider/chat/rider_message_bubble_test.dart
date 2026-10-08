import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_avatar.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_timeline.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_message_bubble.dart';

RiderChatMessageModel _message({required bool isMine, String body = 'hello'}) =>
    RiderChatMessageModel(
      id: 1,
      conversationId: 1,
      type: 'text',
      body: body,
      sender: const RiderChatMessageSender(id: 7, name: 'Ampaw S.'),
      isMine: isMine,
      createdAt: DateTime(2026, 10, 7, 10, 25),
    );

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('peer bubble shows the customer avatar on the left, mine does not',
      (tester) async {
    await tester.pumpWidget(_host(Column(children: [
      RiderMessageBubble(
        message: _message(isMine: false, body: 'Top floor ' * 20),
        peerName: 'Ampaw S.',
      ),
      RiderMessageBubble(message: _message(isMine: true), peerName: 'Ampaw S.'),
    ])));

    expect(tester.takeException(), isNull);
    expect(find.byType(RiderChatAvatar), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('typing indicator renders with the customer avatar', (tester) async {
    await tester.pumpWidget(_host(const RiderTypingIndicator(peerName: 'Ampaw S.')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(RiderChatAvatar), findsOneWidget);
  });
}
