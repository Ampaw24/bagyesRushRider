/// Typed payloads for the events documented in the realtime spec — one
/// model per event, all parsed from the `Map` a bound `pusher_client_socket`
/// channel listener receives. Kept deliberately minimal: fields the app has
/// no current consumer for (e.g. `order.status`'s `status_label`, which the
/// UI already derives from `status` via `riderMeOrderStatusLabel`) are left
/// unparsed rather than modeled speculatively.
library;

/// `order.status` — carried on `private-order.{order_id}`.
class RealtimeOrderStatusEvent {
  final int orderId;
  final String status;

  const RealtimeOrderStatusEvent({required this.orderId, required this.status});

  factory RealtimeOrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeOrderStatusEvent(
        orderId: json['order_id'] as int,
        status: json['status'] as String,
      );
}

/// `rider.location` — carried on both `private-order.{order_id}` and
/// `private-admin.riders`. This app only subscribes to the former (there is
/// no admin/dispatch surface here); see `RealtimeService`.
class RealtimeRiderLocationEvent {
  final int riderId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKph;
  final DateTime? recordedAt;

  const RealtimeRiderLocationEvent({
    required this.riderId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKph,
    this.recordedAt,
  });

  factory RealtimeRiderLocationEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeRiderLocationEvent(
        riderId: json['rider_id'] as int,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        speedKph: (json['speed_kph'] as num?)?.toDouble(),
        recordedAt: DateTime.tryParse(json['recorded_at'] as String? ?? ''),
      );
}

/// The `message` object nested in `message.sent` — documented as the same
/// shape as `GET /conversations/{id}/messages`, so a future REST-backed chat
/// feature can reuse this model for both the live event and history loads.
class RealtimeChatMessage {
  final int id;
  final int conversationId;
  final String type;
  final String body;
  final int? senderId;
  final String? senderName;
  final bool isMine;
  final String? clientUuid;
  final DateTime? createdAt;

  const RealtimeChatMessage({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.body,
    this.senderId,
    this.senderName,
    required this.isMine,
    this.clientUuid,
    this.createdAt,
  });

  factory RealtimeChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return RealtimeChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      type: json['type'] as String? ?? 'text',
      body: json['body'] as String? ?? '',
      senderId: sender is Map ? sender['id'] as int? : null,
      senderName: sender is Map ? sender['name'] as String? : null,
      isMine: json['is_mine'] as bool? ?? false,
      clientUuid: json['client_uuid'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class RealtimeMessageSentEvent {
  final int conversationId;
  final RealtimeChatMessage message;

  const RealtimeMessageSentEvent({
    required this.conversationId,
    required this.message,
  });

  factory RealtimeMessageSentEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeMessageSentEvent(
        conversationId: json['conversation_id'] as int,
        message: RealtimeChatMessage.fromJson(
          (json['message'] as Map).cast<String, dynamic>(),
        ),
      );
}

class RealtimeConversationReadEvent {
  final int conversationId;
  final int userId;
  final DateTime? readAt;

  const RealtimeConversationReadEvent({
    required this.conversationId,
    required this.userId,
    this.readAt,
  });

  factory RealtimeConversationReadEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeConversationReadEvent(
        conversationId: json['conversation_id'] as int,
        userId: json['user_id'] as int,
        readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      );
}

/// `conversation.typing` — no "stopped typing" counterpart is sent; callers
/// are expected to expire the indicator on a client-side timer.
class RealtimeTypingEvent {
  final int conversationId;
  final int userId;

  const RealtimeTypingEvent({
    required this.conversationId,
    required this.userId,
  });

  factory RealtimeTypingEvent.fromJson(Map<String, dynamic> json) =>
      RealtimeTypingEvent(
        conversationId: json['conversation_id'] as int,
        userId: json['user_id'] as int,
      );
}

/// A private channel's `/broadcasting/auth` call failed with [statusCode]
/// 403 — authenticated, but not a participant in this channel's subject
/// (wrong id, or genuinely not theirs). A 401 is handled separately by
/// [RealtimeService] as an expired session rather than surfaced here.
class RealtimeChannelAuthError {
  final String channelName;
  final int? statusCode;

  const RealtimeChannelAuthError({required this.channelName, this.statusCode});
}
