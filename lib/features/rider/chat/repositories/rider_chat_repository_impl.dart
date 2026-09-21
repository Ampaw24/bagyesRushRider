import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/network/api_error_parser.dart';
import 'package:delivery_boy/core/network/request_error_message.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_conversation_model.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_messages_page_model.dart';
import 'package:delivery_boy/features/rider/chat/repositories/rider_chat_repository.dart';
import 'package:delivery_boy/features/rider/chat/services/rider_chat_api_service.dart';

class RiderChatRepositoryImpl implements RiderChatRepository {
  final RiderChatApiService _api;

  RiderChatRepositoryImpl(this._api);

  @override
  Future<Either<Failure, List<RiderConversationModel>>> getConversations() =>
      _run(() async {
        final response = await _api.getConversations();
        return _asList(response.data)
            .map((e) => RiderConversationModel.fromJson(e))
            .toList();
      });

  @override
  Future<Either<Failure, RiderConversationModel>> getConversation(
    int conversationId,
  ) =>
      _run(() async {
        final response = await _api.getConversation(conversationId);
        return RiderConversationModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, RiderConversationModel>> getConversationForOrder(
    int orderId,
  ) async {
    try {
      final response = await _api.getConversationForOrder(orderId);
      return Right(RiderConversationModel.fromJson(_asMap(response.data)));
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final backendMessage = apiMessageFrom(e.response?.data);
        return Left(ConversationUnavailableFailure(
          backendMessage ?? 'Chat opens once a rider is assigned.',
        ));
      }
      return Left(ServerFailure(dioErrorMessage(e)));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }

  @override
  Future<Either<Failure, RiderMessagesPageModel>> getMessages(
    int conversationId, {
    String? cursor,
    int perPage = 30,
  }) =>
      _run(() async {
        final response = await _api.getMessages(
          conversationId,
          cursor: cursor,
          perPage: perPage,
        );
        return RiderMessagesPageModel.fromJson(_asMap(response.data));
      });

  @override
  Future<Either<Failure, RiderChatMessageModel>> sendMessage(
    int conversationId, {
    required String body,
    String? clientUuid,
  }) =>
      _run(() async {
        final response = await _api.sendMessage(
          conversationId,
          body: body,
          clientUuid: clientUuid,
        );
        return RiderChatMessageModel.fromJson(_asMap(response.data));
      });

  @override
  Future<void> markRead(int conversationId) async {
    try {
      await _api.markRead(conversationId);
    } catch (e) {
      appLogger.w('RiderChatRepository.markRead → failed (ignored): $e');
    }
  }

  @override
  Future<void> sendTyping(int conversationId) async {
    try {
      await _api.sendTyping(conversationId);
    } catch (e) {
      appLogger.w('RiderChatRepository.sendTyping → failed (ignored): $e');
    }
  }

  /// Unwraps a Laravel API Resource envelope (`{"data": {...}}`); falls
  /// back to the raw body if it isn't wrapped.
  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>;
    }
    return (raw as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Unwraps a Laravel collection envelope — a plain list (`{"data": [...]}`)
  /// or an `items`-wrapped one — falling back to a bare JSON array.
  List<Map<String, dynamic>> _asList(dynamic raw) {
    dynamic data = raw is Map<String, dynamic> ? raw['data'] : raw;
    if (data is Map<String, dynamic>) {
      data = data['items'];
    }
    final list = data as List?;
    return (list ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      final fieldErrors = apiFieldErrorsFrom(e.response?.data);
      if (fieldErrors != null) {
        return Left(ValidationFailure(dioErrorMessage(e), fieldErrors));
      }
      return Left(ServerFailure(dioErrorMessage(e)));
    } catch (e, s) {
      return Left(ServerFailure(unexpectedErrorMessage(e, s)));
    }
  }
}
