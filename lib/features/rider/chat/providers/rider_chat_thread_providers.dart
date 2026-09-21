import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/core/realtime/models/realtime_events.dart';
import 'package:delivery_boy/core/realtime/realtime_service.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_conversation_model.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_thread_args.dart';
import 'package:delivery_boy/features/rider/chat/repositories/rider_chat_repository.dart';

enum RiderChatThreadStatus { loading, loaded, unavailable, error }

/// [messages] is always kept **ascending** (oldest first) for a
/// bottom-anchored view — the API itself returns newest-first, reversed on
/// the way in.
class RiderChatThreadState extends Equatable {
  final RiderChatThreadStatus status;
  final RiderConversationModel? conversation;
  final List<RiderChatMessageModel> messages;
  final bool hasMoreOlder;
  final bool isLoadingOlder;

  /// True for a few seconds after a `conversation.typing` event — there is
  /// no "stopped typing" event, so this expires client-side on a timer.
  final bool peerTyping;

  /// Set from `conversation.read` — own messages at/before this timestamp
  /// show a "read" tick.
  final DateTime? peerReadAt;

  /// Used for both [RiderChatThreadStatus.error] and
  /// [RiderChatThreadStatus.unavailable].
  final String? message;

  const RiderChatThreadState({
    this.status = RiderChatThreadStatus.loading,
    this.conversation,
    this.messages = const [],
    this.hasMoreOlder = false,
    this.isLoadingOlder = false,
    this.peerTyping = false,
    this.peerReadAt,
    this.message,
  });

  RiderChatThreadState copyWith({
    RiderChatThreadStatus? status,
    RiderConversationModel? conversation,
    List<RiderChatMessageModel>? messages,
    bool? hasMoreOlder,
    bool? isLoadingOlder,
    bool? peerTyping,
    DateTime? peerReadAt,
    String? message,
  }) =>
      RiderChatThreadState(
        status: status ?? this.status,
        conversation: conversation ?? this.conversation,
        messages: messages ?? this.messages,
        hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
        isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
        peerTyping: peerTyping ?? this.peerTyping,
        peerReadAt: peerReadAt ?? this.peerReadAt,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [
        status,
        conversation,
        messages,
        hasMoreOlder,
        isLoadingOlder,
        peerTyping,
        peerReadAt,
        message,
      ];
}

/// One instance per distinct [RiderChatThreadArgs] (`.family`), disposed the
/// moment nothing watches it any more (`.autoDispose`) — unlike the rest of
/// this app's feature notifiers, a thread is genuinely screen-scoped rather
/// than an app-session singleton, so its channel subscription and stream
/// listeners need to go away with the sheet that opened it.
///
/// New messages, typing indicators and read receipts arrive via
/// `RealtimeService`'s `private-conversation.{id}` channel; sending a
/// message/typing-ping/read-receipt stays a REST call — only the receive
/// side is realtime.
class RiderChatThreadNotifier
    extends AutoDisposeFamilyNotifier<RiderChatThreadState, RiderChatThreadArgs> {
  static const _typingThrottle = Duration(seconds: 3);
  static const _typingIndicatorTtl = Duration(seconds: 3);
  static const _readDebounce = Duration(seconds: 3);
  static const _maxBodyLength = 2000;
  static const _uuid = Uuid();

  RiderChatRepository get _repo => sl<RiderChatRepository>();
  RealtimeService get _realtime => sl<RealtimeService>();

  int? _subscribedConversationId;
  StreamSubscription<RealtimeMessageSentEvent>? _messageSub;
  StreamSubscription<RealtimeTypingEvent>? _typingSub;
  StreamSubscription<RealtimeConversationReadEvent>? _readSub;
  StreamSubscription<RealtimeChannelAuthError>? _channelErrorSub;
  Timer? _typingTimer;
  Timer? _typingIndicatorTimer;
  DateTime? _lastMarkedReadAt;

  @override
  RiderChatThreadState build(RiderChatThreadArgs args) {
    ref.onDispose(_teardown);
    _init(args);
    return const RiderChatThreadState();
  }

  /// Re-runs the initial conversation + first-page-of-messages fetch —
  /// exposed for the error state's "Retry" / unavailable state's "Check
  /// again" actions.
  Future<void> retryLoad() => _init(arg);

  Future<void> _init(RiderChatThreadArgs args) async {
    state = state.copyWith(status: RiderChatThreadStatus.loading, message: null);

    final conversationResult = args.conversationId != null
        ? await _repo.getConversation(args.conversationId!)
        : await _repo.getConversationForOrder(args.orderId!);

    final conversation = conversationResult.fold((f) {
      state = state.copyWith(
        status: f is ConversationUnavailableFailure
            ? RiderChatThreadStatus.unavailable
            : RiderChatThreadStatus.error,
        message: f.message,
      );
      return null;
    }, (c) => c);
    if (conversation == null) return;

    final messagesResult = await _repo.getMessages(conversation.id);
    messagesResult.fold(
      (f) => state = state.copyWith(status: RiderChatThreadStatus.error, message: f.message),
      (page) {
        state = state.copyWith(
          status: RiderChatThreadStatus.loaded,
          conversation: conversation,
          messages: page.items.reversed.toList(),
          hasMoreOlder: page.hasMore,
          message: null,
        );
        _nextCursor = page.nextCursor;
        _markReadDebounced();
        _subscribeRealtime(conversation.id);
      },
    );
  }

  String? _nextCursor;

  void _subscribeRealtime(int conversationId) {
    _subscribedConversationId = conversationId;
    _realtime.subscribeToConversation(conversationId);
    _messageSub = _realtime.messages$.listen(_onIncomingMessageEvent);
    _typingSub = _realtime.typing$.listen(_onPeerTyping);
    _readSub = _realtime.conversationRead$.listen(_onPeerRead);
    _channelErrorSub = _realtime.channelAuthErrors$.listen(_onChannelError);
  }

  /// A 403 here means this account isn't a participant in this conversation
  /// — shown distinctly from a generic error via
  /// [RiderChatThreadStatus.unavailable]. A 401 needs no handling here:
  /// `RealtimeService` already turns that into a session-clear + disconnect
  /// app-wide.
  void _onChannelError(RealtimeChannelAuthError error) {
    final conversationId = _subscribedConversationId;
    if (conversationId == null ||
        error.channelName != _realtime.conversationChannelName(conversationId)) {
      return;
    }
    if (error.statusCode != 403) return;
    state = state.copyWith(
      status: RiderChatThreadStatus.unavailable,
      message: "You don't have access to this conversation.",
    );
  }

  /// `messages$` is a single stream shared by whichever conversation
  /// channel(s) are currently subscribed — filtering by conversation id is
  /// required, not decorative. Dedupes by `id`/`clientUuid`, since a push
  /// notification and this socket event can both fire for the same message.
  void _onIncomingMessageEvent(RealtimeMessageSentEvent event) {
    final conversation = state.conversation;
    if (conversation == null || event.conversationId != conversation.id) return;
    _onIncomingMessage(_toModel(event.message));
  }

  void _onIncomingMessage(RiderChatMessageModel message) {
    final existingIds = state.messages.map((m) => m.id).toSet();
    final existingClientUuids =
        state.messages.map((m) => m.clientUuid).whereType<String>().toSet();
    final isDuplicate = existingIds.contains(message.id) ||
        (message.clientUuid != null && existingClientUuids.contains(message.clientUuid));
    if (isDuplicate) return;

    final merged = [...state.messages, message]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = state.copyWith(messages: merged);
    _markReadDebounced();
  }

  RiderChatMessageModel _toModel(RealtimeChatMessage e) => RiderChatMessageModel(
        id: e.id,
        conversationId: e.conversationId,
        type: e.type,
        body: e.body,
        sender: RiderChatMessageSender(id: e.senderId, name: e.senderName ?? ''),
        isMine: e.isMine,
        clientUuid: e.clientUuid,
        createdAt: e.createdAt ?? DateTime.now(),
      );

  void _onPeerTyping(RealtimeTypingEvent event) {
    final conversation = state.conversation;
    if (conversation == null || event.conversationId != conversation.id) return;
    if (event.userId != conversation.counterpart?.userId) return;

    state = state.copyWith(peerTyping: true);
    _typingIndicatorTimer?.cancel();
    _typingIndicatorTimer = Timer(_typingIndicatorTtl, () {
      state = state.copyWith(peerTyping: false);
    });
  }

  void _onPeerRead(RealtimeConversationReadEvent event) {
    final conversation = state.conversation;
    if (conversation == null || event.conversationId != conversation.id) return;
    if (event.userId != conversation.counterpart?.userId) return;
    state = state.copyWith(peerReadAt: event.readAt ?? DateTime.now());
  }

  Future<void> loadOlderMessages() async {
    final conversation = state.conversation;
    if (conversation == null || !state.hasMoreOlder || state.isLoadingOlder) return;

    state = state.copyWith(isLoadingOlder: true);
    final result = await _repo.getMessages(conversation.id, cursor: _nextCursor);
    result.fold(
      (f) {
        appLogger.w('RiderChatThreadNotifier.loadOlderMessages → failed: ${f.message}');
        state = state.copyWith(isLoadingOlder: false);
      },
      (page) {
        _nextCursor = page.nextCursor;
        state = state.copyWith(
          messages: [...page.items.reversed, ...state.messages],
          hasMoreOlder: page.hasMore,
          isLoadingOlder: false,
        );
      },
    );
  }

  /// Optimistically appends [text] as a `sending` bubble, then reconciles it
  /// (by `client_uuid`) with the server row on success, or marks it
  /// `failed` — tap-to-retry — on failure.
  Future<void> sendMessage(String text) async {
    final body = text.trim();
    final conversation = state.conversation;
    if (body.isEmpty || body.length > _maxBodyLength) return;
    if (conversation == null || !conversation.isOpen) return;

    final clientUuid = _uuid.v4();
    final optimistic = RiderChatMessageModel.optimistic(
      conversationId: conversation.id,
      body: body,
      clientUuid: clientUuid,
    );
    state = state.copyWith(messages: [...state.messages, optimistic]);

    final result =
        await _repo.sendMessage(conversation.id, body: body, clientUuid: clientUuid);
    result.fold(
      (f) {
        appLogger.w('RiderChatThreadNotifier.sendMessage → failed: ${f.message}');
        _markFailed(clientUuid);
      },
      (sent) => _replaceByClientUuid(clientUuid, sent),
    );
  }

  /// Re-sends a bubble stuck in [MessageDeliveryStatus.failed].
  Future<void> retry(RiderChatMessageModel failedMessage) async {
    final conversation = state.conversation;
    final clientUuid = failedMessage.clientUuid;
    if (conversation == null || clientUuid == null) return;

    _replaceByClientUuid(
      clientUuid,
      failedMessage.copyWith(deliveryStatus: MessageDeliveryStatus.sending),
    );
    final result = await _repo.sendMessage(
      conversation.id,
      body: failedMessage.body,
      clientUuid: clientUuid,
    );
    result.fold(
      (f) {
        appLogger.w('RiderChatThreadNotifier.retry → failed: ${f.message}');
        _markFailed(clientUuid);
      },
      (sent) => _replaceByClientUuid(clientUuid, sent),
    );
  }

  void _replaceByClientUuid(String clientUuid, RiderChatMessageModel replacement) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.clientUuid == clientUuid) replacement else m,
      ],
    );
  }

  void _markFailed(String clientUuid) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.clientUuid == clientUuid)
            m.copyWith(deliveryStatus: MessageDeliveryStatus.failed)
          else
            m,
      ],
    );
  }

  /// Throttled to roughly one call per [_typingThrottle] window while the
  /// composer has focus. Ignores failures itself (see
  /// `RiderChatRepository.sendTyping`).
  void notifyTyping() {
    if (_typingTimer != null) return;
    final conversation = state.conversation;
    if (conversation == null || !conversation.isOpen) return;
    _repo.sendTyping(conversation.id);
    _typingTimer = Timer(_typingThrottle, () => _typingTimer = null);
  }

  /// Debounced — call whenever the thread is visible (init, new-message
  /// arrival) but never per-message; the endpoint returns no state worth
  /// re-fetching for.
  void _markReadDebounced() {
    final now = DateTime.now();
    if (_lastMarkedReadAt != null && now.difference(_lastMarkedReadAt!) < _readDebounce) {
      return;
    }
    _lastMarkedReadAt = now;
    final conversation = state.conversation;
    if (conversation == null) return;
    _repo.markRead(conversation.id);
  }

  void _teardown() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _channelErrorSub?.cancel();
    _typingTimer?.cancel();
    _typingIndicatorTimer?.cancel();
    final conversationId = _subscribedConversationId;
    if (conversationId != null) {
      _realtime.unsubscribeFromConversation(conversationId);
    }
  }
}

final riderChatThreadProvider = NotifierProvider.autoDispose
    .family<RiderChatThreadNotifier, RiderChatThreadState, RiderChatThreadArgs>(
  RiderChatThreadNotifier.new,
);
