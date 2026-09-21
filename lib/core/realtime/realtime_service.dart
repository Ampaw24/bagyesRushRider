import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:pusher_client_socket/utils/connection_state.dart';

import 'package:delivery_boy/core/realtime/models/realtime_config_model.dart';
import 'package:delivery_boy/core/realtime/models/realtime_events.dart';
import 'package:delivery_boy/core/realtime/services/realtime_config_api_service.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/core/utils/network_utility.dart' show sessionRevision;

enum RealtimeConnectionState { disconnected, connecting, connected, reconnecting }

/// Realtime (WebSocket) layer over Laravel Reverb.
///
/// Deliberately not built on `pusher_channels_flutter` — the package the
/// realtime spec suggests. That plugin's `init()` only accepts a
/// Pusher-hosted `cluster`; it has no `host`/`port` override in either its
/// Dart API or its native Android/iOS glue, so it cannot reach a
/// self-hosted Reverb server at all. `pusher_client_socket` is a pure-Dart
/// Pusher-protocol client built for exactly this case (custom host/port,
/// async auth headers), which also sidesteps native pod/gradle setup.
///
/// One instance for the whole app session (registered in the service
/// locator, never disposed — same lifetime as `sl<Dio>()`). [connect]
/// fetches `/realtime/config` fresh every call rather than caching it,
/// since the spec calls for re-fetching after login and on app resume.
///
/// Channel scoping: the order-tracking and admin/dispatch map screens the
/// spec describes don't exist in this app (see rider_tracking_providers.dart
/// and app_router.dart — there's no map UI, and this is the rider app, not
/// a staff/dispatch one), so `private-admin.riders` is not implemented here.
/// `private-order.{id}` is instead kept in sync with whichever orders
/// `RiderMeOrdersNotifier` currently has loaded as active — see that class.
class RealtimeService {
  RealtimeService(this._configApi, this._sessionManager);

  final RealtimeConfigApiService _configApi;
  final UserSessionManager _sessionManager;

  PusherClient? _client;
  RealtimeConfigModel? _config;
  Future<void>? _connecting;

  final Set<int> _orderChannels = {};
  final Set<int> _conversationChannels = {};
  bool _riderChannelSubscribed = false;

  final _connectionStateController =
      StreamController<RealtimeConnectionState>.broadcast();
  final _orderStatusController =
      StreamController<RealtimeOrderStatusEvent>.broadcast();
  final _riderLocationController =
      StreamController<RealtimeRiderLocationEvent>.broadcast();
  final _messageController =
      StreamController<RealtimeMessageSentEvent>.broadcast();
  final _conversationReadController =
      StreamController<RealtimeConversationReadEvent>.broadcast();
  final _typingController = StreamController<RealtimeTypingEvent>.broadcast();
  final _riderChannelEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _channelAuthErrorController =
      StreamController<RealtimeChannelAuthError>.broadcast();

  Stream<RealtimeConnectionState> get connectionState$ =>
      _connectionStateController.stream;
  Stream<RealtimeOrderStatusEvent> get orderStatus$ => _orderStatusController.stream;
  Stream<RealtimeRiderLocationEvent> get riderLocation$ =>
      _riderLocationController.stream;
  Stream<RealtimeMessageSentEvent> get messages$ => _messageController.stream;
  Stream<RealtimeConversationReadEvent> get conversationRead$ =>
      _conversationReadController.stream;
  Stream<RealtimeTypingEvent> get typing$ => _typingController.stream;

  /// Raw payloads from this rider's own `private-rider.{id}` channel — job
  /// offers, whose shape the spec explicitly leaves undocumented. Consumers
  /// (see `RiderMeOffersNotifier`) treat any event here as "refresh", not as
  /// a typed payload.
  Stream<Map<String, dynamic>> get riderChannelEvents$ =>
      _riderChannelEventController.stream;

  /// 403s only — a 401 is handled internally as an expired session (see
  /// [_bindAuthError]) rather than surfaced here.
  Stream<RealtimeChannelAuthError> get channelAuthErrors$ =>
      _channelAuthErrorController.stream;

  bool get isConnected => _client?.connected ?? false;

  /// The exact channel name [subscribeToConversation] uses for
  /// [conversationId] — lets a caller filter [channelAuthErrors$] down to
  /// just its own channel instead of reacting to every open conversation's
  /// errors.
  String conversationChannelName(int conversationId) =>
      _channelName('conversation', {'conversation_id': '$conversationId'});

  static const _defaultChannelTemplates = {
    'order': 'private-order.{order_id}',
    'conversation': 'private-conversation.{conversation_id}',
    'rider': 'private-rider.{user_id}',
  };

  /// Fetches `/realtime/config` and opens the socket. Safe to call while a
  /// previous call is still in flight (login, app resume and the cold-start
  /// bootstrap each call this independently) — callers share one in-flight
  /// attempt instead of racing.
  Future<void> connect() {
    final inFlight = _connecting;
    if (inFlight != null) return inFlight;
    final future = _connect();
    _connecting = future;
    return future.whenComplete(() => _connecting = null);
  }

  /// Reconnects only if the socket isn't already connected — cheap to call
  /// from an app-resume hook; a no-op otherwise.
  Future<void> ensureConnected() async {
    if (isConnected || _connecting != null) return;
    await connect();
  }

  Future<void> _connect() async {
    if (!_sessionManager.isLoggedIn) return;

    try {
      _connectionStateController.add(RealtimeConnectionState.connecting);

      final response = await _configApi.getConfig();
      final raw = response.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      _config = RealtimeConfigModel.fromJson(
        (data as Map).cast<String, dynamic>(),
      );

      await _teardownClient();

      final options = PusherOptions(
        key: _config!.key,
        host: _config!.host,
        wsPort: _config!.port,
        wssPort: _config!.port,
        encrypted: _config!.useTls,
        enableLogging: kDebugMode,
        autoConnect: false,
        authOptions: PusherAuthOptions(
          _config!.authEndpoint,
          headers: () async {
            final token = _sessionManager.token;
            return {
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            };
          },
        ),
      );

      final client = PusherClient(options: options);
      _client = client;

      client.onConnectionStateChange((state) {
        appLogger.d('[Realtime] connection state: ${state.name}');
        _connectionStateController.add(_mapConnectionState(state));
      });
      client.onError((error) => appLogger.w('[Realtime] error: $error'));
      client.onConnectionError(
        (error) => appLogger.w('[Realtime] connection error: $error'),
      );

      client.connect();

      // Re-open whatever this session already cared about — covers both a
      // fresh login (both sets are empty, so these are no-ops) and an
      // app-resume reconnect, where the previous PusherClient (and its
      // channel objects) was just discarded above and needs rebuilding.
      for (final orderId in _orderChannels.toList()) {
        _openOrderChannel(orderId);
      }
      for (final conversationId in _conversationChannels.toList()) {
        _openConversationChannel(conversationId);
      }
      _riderChannelSubscribed = false;
      _subscribeToOwnChannel();
    } catch (e, s) {
      appLogger.e('[Realtime] connect failed', error: e, stackTrace: s);
      _connectionStateController.add(RealtimeConnectionState.disconnected);
    }
  }

  RealtimeConnectionState _mapConnectionState(ConnectionState state) {
    if (state.isReconnecting) return RealtimeConnectionState.reconnecting;
    if (state.isConnected) return RealtimeConnectionState.connected;
    if (state.isConnecting) return RealtimeConnectionState.connecting;
    return RealtimeConnectionState.disconnected;
  }

  Future<void> disconnect() async {
    await _teardownClient();
    _orderChannels.clear();
    _conversationChannels.clear();
    _riderChannelSubscribed = false;
    _connectionStateController.add(RealtimeConnectionState.disconnected);
  }

  Future<void> _teardownClient() async {
    try {
      _client?.disconnect();
    } catch (e) {
      // Never actually connected — nothing to tear down.
    }
    _client = null;
  }

  String _channelName(String templateKey, Map<String, String> params) {
    var template =
        _config?.channelTemplates[templateKey] ?? _defaultChannelTemplates[templateKey]!;
    for (final entry in params.entries) {
      template = template.replaceAll('{${entry.key}}', entry.value);
    }
    return template;
  }

  /// A 401 here means the access token itself has expired — this backend
  /// has no working refresh-token endpoint (see `RiderDioInterceptor`'s own
  /// comment on the same limitation), so the correct move is exactly what
  /// a REST 401 already does app-wide: clear the session and let the
  /// router's `sessionRevision` guard send the rider back to login. A 403
  /// means the token is fine but this rider has no stake in the channel —
  /// surfaced via [channelAuthErrors$] instead, not treated as a failure.
  void _bindAuthError(Channel channel) {
    channel.bind('pusher:error', (dynamic data) {
      final match = RegExp(r'status code:\s*(\d+)').firstMatch(data.toString());
      final statusCode = match != null ? int.tryParse(match.group(1)!) : null;
      appLogger.w('[Realtime] channel auth failed: ${channel.name} ($data)');

      if (statusCode == 401) {
        _sessionManager.clearSession();
        sessionRevision.value++;
        disconnect();
        return;
      }

      _channelAuthErrorController.add(
        RealtimeChannelAuthError(channelName: channel.name, statusCode: statusCode),
      );
    });
  }

  // ── Orders — private-order.{id}: order.status, rider.location ─────────

  void subscribeToOrder(int orderId) {
    if (!_orderChannels.add(orderId)) return;
    _openOrderChannel(orderId);
  }

  void unsubscribeFromOrder(int orderId) {
    if (!_orderChannels.remove(orderId)) return;
    _client?.unsubscribe(_channelName('order', {'order_id': '$orderId'}));
  }

  void _openOrderChannel(int orderId) {
    final client = _client;
    if (client == null) return;

    final channel = client.private(_channelName('order', {'order_id': '$orderId'}));
    _bindAuthError(channel);

    channel.bind('order.status', (dynamic data) {
      try {
        _orderStatusController.add(
          RealtimeOrderStatusEvent.fromJson((data as Map).cast<String, dynamic>()),
        );
      } catch (e, s) {
        appLogger.e('[Realtime] bad order.status payload', error: e, stackTrace: s);
      }
    });

    channel.bind('rider.location', (dynamic data) {
      try {
        _riderLocationController.add(
          RealtimeRiderLocationEvent.fromJson((data as Map).cast<String, dynamic>()),
        );
      } catch (e, s) {
        appLogger.e('[Realtime] bad rider.location payload', error: e, stackTrace: s);
      }
    });

    channel.subscribe();
  }

  // ── Conversations — private-conversation.{id} ──────────────────────────
  // No screen consumes these yet (this app has no chat UI), but the
  // channel plumbing and typed events are ready for one — see
  // RealtimeChatMessage in realtime_events.dart.

  void subscribeToConversation(int conversationId) {
    if (!_conversationChannels.add(conversationId)) return;
    _openConversationChannel(conversationId);
  }

  void unsubscribeFromConversation(int conversationId) {
    if (!_conversationChannels.remove(conversationId)) return;
    _client?.unsubscribe(
      _channelName('conversation', {'conversation_id': '$conversationId'}),
    );
  }

  void _openConversationChannel(int conversationId) {
    final client = _client;
    if (client == null) return;

    final channel = client.private(
      _channelName('conversation', {'conversation_id': '$conversationId'}),
    );
    _bindAuthError(channel);

    channel.bind('message.sent', (dynamic data) {
      try {
        _messageController.add(
          RealtimeMessageSentEvent.fromJson((data as Map).cast<String, dynamic>()),
        );
      } catch (e, s) {
        appLogger.e('[Realtime] bad message.sent payload', error: e, stackTrace: s);
      }
    });

    channel.bind('conversation.read', (dynamic data) {
      try {
        _conversationReadController.add(
          RealtimeConversationReadEvent.fromJson(
            (data as Map).cast<String, dynamic>(),
          ),
        );
      } catch (e, s) {
        appLogger.e('[Realtime] bad conversation.read payload', error: e, stackTrace: s);
      }
    });

    channel.bind('conversation.typing', (dynamic data) {
      try {
        _typingController.add(
          RealtimeTypingEvent.fromJson((data as Map).cast<String, dynamic>()),
        );
      } catch (e, s) {
        appLogger.e('[Realtime] bad conversation.typing payload', error: e, stackTrace: s);
      }
    });

    channel.subscribe();
  }

  // ── This rider's own channel — private-rider.{id}: job offers ─────────
  // Session-scoped rather than screen-scoped (there's no dedicated screen
  // it belongs to, unlike order/conversation channels) — subscribed once
  // per connection, alongside the rest of this rider's session.

  void _subscribeToOwnChannel() {
    final client = _client;
    final userId = _sessionManager.userId;
    if (client == null || userId == null || _riderChannelSubscribed) return;
    _riderChannelSubscribed = true;

    final channel = client.private(_channelName('rider', {'user_id': userId}));
    _bindAuthError(channel);

    // Payload isn't documented yet (see the realtime spec's channel table)
    // — forward every event rather than asserting a shape.
    channel.bind('*', (dynamic payload) {
      if (payload is Map) {
        _riderChannelEventController.add(payload.cast<String, dynamic>());
      } else {
        appLogger.d('[Realtime] rider channel event (non-map): $payload');
      }
    });

    channel.subscribe();
  }
}
