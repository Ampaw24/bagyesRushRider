import 'package:dartz/dartz.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_conversation_model.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_messages_page_model.dart';

abstract class RiderChatRepository {
  Future<Either<Failure, List<RiderConversationModel>>> getConversations();

  Future<Either<Failure, RiderConversationModel>> getConversation(
      int conversationId);

  /// Left is a [ConversationUnavailableFailure] on the documented 422 (no
  /// rider assigned to this order yet) — never a generic [ServerFailure]
  /// for that specific case.
  Future<Either<Failure, RiderConversationModel>> getConversationForOrder(
      int orderId);

  Future<Either<Failure, RiderMessagesPageModel>> getMessages(
    int conversationId, {
    String? cursor,
    int perPage,
  });

  Future<Either<Failure, RiderChatMessageModel>> sendMessage(
    int conversationId, {
    required String body,
    String? clientUuid,
  });

  /// Best-effort — never fails loud. See `RiderChatRepositoryImpl.markRead`.
  Future<void> markRead(int conversationId);

  /// Best-effort, fire-and-forget — the API has no stop-typing endpoint and
  /// failures must never surface to the composer.
  Future<void> sendTyping(int conversationId);
}
