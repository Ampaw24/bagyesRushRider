import 'package:equatable/equatable.dart';

/// Client-side send lifecycle for a message. The API itself has no such
/// field — this exists purely to drive the optimistic bubble UI while
/// [RiderChatMessageModel.clientUuid] round-trips through
/// `RiderChatRepository.sendMessage`.
enum MessageDeliveryStatus { sending, sent, failed }

class RiderChatMessageSender extends Equatable {
  const RiderChatMessageSender({required this.id, required this.name});

  final int? id;
  final String name;

  factory RiderChatMessageSender.fromJson(Map<String, dynamic> json) =>
      RiderChatMessageSender(
        id: json['id'] as int?,
        name: json['name'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, name];
}

/// A single chat message — `GET /conversations/:id/messages` items and the
/// nested `message` object of the realtime `message.sent` event share this
/// exact shape (see `RealtimeChatMessage` in `core/realtime/models`).
class RiderChatMessageModel extends Equatable {
  const RiderChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.body,
    required this.sender,
    required this.isMine,
    required this.createdAt,
    this.clientUuid,
    this.deliveryStatus = MessageDeliveryStatus.sent,
  });

  final int id;
  final int conversationId;
  final String type;
  final String body;
  final RiderChatMessageSender sender;
  final bool isMine;
  final String? clientUuid;
  final DateTime createdAt;
  final MessageDeliveryStatus deliveryStatus;

  factory RiderChatMessageModel.fromJson(Map<String, dynamic> json) =>
      RiderChatMessageModel(
        id: json['id'] as int,
        conversationId: json['conversation_id'] as int,
        type: json['type'] as String? ?? 'text',
        body: json['body'] as String? ?? '',
        sender: RiderChatMessageSender.fromJson(
          (json['sender'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        isMine: json['is_mine'] as bool? ?? false,
        clientUuid: json['client_uuid'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  /// A not-yet-confirmed bubble shown immediately on send, before the
  /// server echoes the real row back. Reconciled by [clientUuid] — see
  /// `RiderChatThreadNotifier.sendMessage`. `id` uses a negative,
  /// clearly-non-server value so it can never collide with a real message id.
  factory RiderChatMessageModel.optimistic({
    required int conversationId,
    required String body,
    required String clientUuid,
  }) =>
      RiderChatMessageModel(
        id: -DateTime.now().microsecondsSinceEpoch,
        conversationId: conversationId,
        type: 'text',
        body: body,
        sender: const RiderChatMessageSender(id: null, name: 'You'),
        isMine: true,
        clientUuid: clientUuid,
        createdAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
      );

  RiderChatMessageModel copyWith({MessageDeliveryStatus? deliveryStatus}) =>
      RiderChatMessageModel(
        id: id,
        conversationId: conversationId,
        type: type,
        body: body,
        sender: sender,
        isMine: isMine,
        createdAt: createdAt,
        clientUuid: clientUuid,
        deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      );

  @override
  List<Object?> get props => [
        id,
        conversationId,
        body,
        isMine,
        clientUuid,
        createdAt,
        deliveryStatus,
      ];
}
