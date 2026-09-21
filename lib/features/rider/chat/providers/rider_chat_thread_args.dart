import 'package:equatable/equatable.dart';

/// Navigation payload for the chat thread sheet.
///
/// A thread can be entered two ways: already knowing [conversationId]
/// (tapping an inbox row) or only [orderId] (an order detail sheet's "Chat"
/// button, which must resolve the thread via `GET /orders/:id/conversation`
/// first). Exactly one of the two must be provided. [peerName]/[peerPhone]
/// are optional best-effort values shown while the real conversation is
/// still loading — the chat API never returns a phone number itself, so
/// [peerPhone] only ever comes from a caller that already had it locally
/// (e.g. the order's cached customer phone).
///
/// [Equatable] so this can key a Riverpod `.family` provider — one thread
/// notifier instance per distinct (conversationId, orderId) pair.
class RiderChatThreadArgs extends Equatable {
  const RiderChatThreadArgs({
    this.conversationId,
    this.orderId,
    this.peerName,
    this.peerPhone,
  }) : assert(
          conversationId != null || orderId != null,
          'Provide a conversationId or an orderId',
        );

  final int? conversationId;
  final int? orderId;
  final String? peerName;
  final String? peerPhone;

  @override
  List<Object?> get props => [conversationId, orderId, peerName, peerPhone];
}
