import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for the shared `/conversations` chat API — see
/// `chat-apis.md` on the customer/vendor app; every endpoint here is
/// role-agnostic, the server resolves the caller from the bearer token.
class RiderChatApiService {
  final Dio _dio;

  RiderChatApiService(this._dio);

  Future<Response<dynamic>> getConversations() =>
      _dio.get(ApiEndpoints.conversations);

  Future<Response<dynamic>> getConversation(int conversationId) =>
      _dio.get(ApiEndpoints.conversationById(conversationId));

  /// [orderId] is the **order** id — resolves the thread attached to it,
  /// the entry point from an order detail sheet's "Chat" button.
  Future<Response<dynamic>> getConversationForOrder(int orderId) =>
      _dio.get(ApiEndpoints.orderConversation(orderId));

  /// Cursor-paginated — pass [cursor] back from a previous page's
  /// `RiderMessagesPageModel.nextCursor` to page older messages.
  Future<Response<dynamic>> getMessages(
    int conversationId, {
    String? cursor,
    int perPage = 30,
  }) =>
      _dio.get(
        ApiEndpoints.conversationMessages(conversationId),
        queryParameters: {
          'per_page': perPage,
          if (cursor != null) 'cursor': cursor,
        },
      );

  /// [clientUuid] is the optimistic-send/dedupe key — generate a UUID v4
  /// client-side and omit the key entirely if not sending one (never send
  /// an empty string, it fails the backend's `uuid` rule).
  Future<Response<dynamic>> sendMessage(
    int conversationId, {
    required String body,
    String? clientUuid,
  }) =>
      _dio.post(
        ApiEndpoints.conversationMessages(conversationId),
        data: {'body': body, if (clientUuid != null) 'client_uuid': clientUuid},
      );

  Future<Response<dynamic>> markRead(int conversationId) =>
      _dio.post(ApiEndpoints.conversationRead(conversationId));

  Future<Response<dynamic>> sendTyping(int conversationId) =>
      _dio.post(ApiEndpoints.conversationTyping(conversationId));
}
