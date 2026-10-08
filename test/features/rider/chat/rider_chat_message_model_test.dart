import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';

RiderChatMessageModel _message({required int? senderId, required bool isMine}) =>
    RiderChatMessageModel(
      id: 1,
      conversationId: 1,
      type: 'text',
      body: 'hi',
      sender: RiderChatMessageSender(id: senderId, name: 'x'),
      isMine: isMine,
      createdAt: DateTime(2026, 10, 7),
    );

void main() {
  group('RiderChatMessageModel.resolvedFor', () {
    test('flips a peer message the broadcast wrongly flagged as mine', () {
      final resolved = _message(senderId: 7, isMine: true).resolvedFor(42);
      expect(resolved.isMine, isFalse);
    });

    test('keeps own messages as mine', () {
      final resolved = _message(senderId: 42, isMine: false).resolvedFor(42);
      expect(resolved.isMine, isTrue);
    });

    test('keeps the payload flag when an id is unknown', () {
      expect(_message(senderId: null, isMine: true).resolvedFor(42).isMine, isTrue);
      expect(_message(senderId: 7, isMine: true).resolvedFor(null).isMine, isTrue);
    });
  });
}
