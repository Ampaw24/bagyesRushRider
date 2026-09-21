import 'package:equatable/equatable.dart';

class RiderConversationParticipant extends Equatable {
  const RiderConversationParticipant({
    required this.userId,
    required this.role,
    required this.roleLabel,
    required this.name,
    required this.isMe,
    this.lastReadAt,
  });

  final int userId;
  final String role;
  final String roleLabel;
  final String name;
  final bool isMe;
  final DateTime? lastReadAt;

  factory RiderConversationParticipant.fromJson(Map<String, dynamic> json) =>
      RiderConversationParticipant(
        userId: json['user_id'] as int,
        role: json['role'] as String? ?? '',
        roleLabel: json['role_label'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isMe: json['is_me'] as bool? ?? false,
        lastReadAt: DateTime.tryParse(json['last_read_at'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [userId, role, name, isMe, lastReadAt];
}

class RiderConversationOrderSummary extends Equatable {
  const RiderConversationOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
  });

  final int id;
  final String orderNumber;
  final String status;
  final String statusLabel;

  factory RiderConversationOrderSummary.fromJson(Map<String, dynamic> json) =>
      RiderConversationOrderSummary(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String? ?? '',
        status: json['status'] as String? ?? '',
        statusLabel: json['status_label'] as String? ?? '',
      );

  static const _terminalStatuses = {
    'delivered',
    'cancelled',
    'canceled',
    'rejected',
    'refunded',
  };

  /// Coarse "order still in progress" signal, mirroring
  /// `RiderMeOrderModel.isActive` — kept as a small self-contained check
  /// here rather than an inter-feature import, since chat only needs this
  /// to decide whether a thread still belongs in the active inbox.
  bool get isActive => !_terminalStatuses.contains(status.toLowerCase());

  @override
  List<Object?> get props => [id, orderNumber, status, statusLabel];
}

/// `GET /conversations`, `GET /conversations/:id`, `GET /orders/:id/conversation`.
class RiderConversationModel extends Equatable {
  const RiderConversationModel({
    required this.id,
    required this.topic,
    required this.status,
    required this.isOpen,
    required this.participants,
    required this.unreadCount,
    required this.quickReplies,
    this.order,
    this.lastMessageAt,
    this.createdAt,
  });

  final int id;
  final String topic;
  final String status;
  final bool isOpen;
  final RiderConversationOrderSummary? order;
  final List<RiderConversationParticipant> participants;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final List<String> quickReplies;
  final DateTime? createdAt;

  factory RiderConversationModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    final replies = json['quick_replies'] as List? ?? const [];
    return RiderConversationModel(
      id: json['id'] as int,
      topic: json['topic'] as String? ?? '',
      status: json['status'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? true,
      order: order is Map
          ? RiderConversationOrderSummary.fromJson(order.cast<String, dynamic>())
          : null,
      participants: (json['participants'] as List? ?? const [])
          .map((e) => RiderConversationParticipant.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? ''),
      quickReplies: replies.map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  /// The other side of the thread (the customer, from this rider's point of
  /// view) — used for the thread header and inbox row. `null` for a group
  /// thread with no single counterpart (none of the documented topics are
  /// group chats today, but this keeps callers null-safe if that changes).
  RiderConversationParticipant? get counterpart {
    for (final p in participants) {
      if (!p.isMe) return p;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        topic,
        status,
        isOpen,
        order,
        participants,
        unreadCount,
        lastMessageAt,
        quickReplies,
      ];
}
