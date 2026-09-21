import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_conversation_model.dart';
import 'package:delivery_boy/features/rider/chat/repositories/rider_chat_repository.dart';

enum RiderChatListStatus { initial, loading, loaded, error }

class RiderChatListState extends Equatable {
  final RiderChatListStatus status;
  final List<RiderConversationModel> conversations;
  final String? errorMessage;

  const RiderChatListState({
    this.status = RiderChatListStatus.initial,
    this.conversations = const [],
    this.errorMessage,
  });

  RiderChatListState copyWith({
    RiderChatListStatus? status,
    List<RiderConversationModel>? conversations,
    String? errorMessage,
    bool clearError = false,
  }) =>
      RiderChatListState(
        status: status ?? this.status,
        conversations: conversations ?? this.conversations,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, conversations, errorMessage];
}

/// The chat inbox — `GET /conversations`, filtered to threads whose order is
/// still in progress. Unlike a general messaging app this is not a
/// permanent archive: once an order is delivered/cancelled its thread drops
/// out of this list, matching how the customer/vendor app scopes chat to
/// active orders rather than a standing inbox.
class RiderChatListNotifier extends Notifier<RiderChatListState> {
  @override
  RiderChatListState build() => const RiderChatListState();

  RiderChatRepository get _repo => sl<RiderChatRepository>();

  Future<void> load() async {
    state = state.copyWith(status: RiderChatListStatus.loading, clearError: true);
    final result = await _repo.getConversations();
    result.fold(
      (f) => state = state.copyWith(
          status: RiderChatListStatus.error, errorMessage: f.message),
      (conversations) {
        final active = conversations.where((c) => c.order?.isActive ?? true).toList()
          ..sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt ?? DateTime(0);
            final bTime = b.lastMessageAt ?? b.createdAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
        state = state.copyWith(
            status: RiderChatListStatus.loaded, conversations: active);
      },
    );
  }
}

final riderChatListProvider =
    NotifierProvider<RiderChatListNotifier, RiderChatListState>(
        RiderChatListNotifier.new);
