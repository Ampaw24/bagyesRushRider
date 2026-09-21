/// `GET /realtime/config` — connection details for the Reverb/Pusher-protocol
/// websocket. Fetched fresh on every connect rather than cached across app
/// sessions, since host/port/key can change between environments and the
/// backend is the single source of truth for them.
class RealtimeConfigModel {
  final String key;
  final String host;
  final int port;
  final bool useTls;
  final String authEndpoint;

  /// Channel name templates keyed by family, e.g.
  /// `{"order": "private-order.{order_id}"}`. Interpolated at subscribe
  /// time by [RealtimeService]. Not every family the app knows about is
  /// guaranteed to be present here (the API's example response only lists
  /// `order`/`conversation`) — [RealtimeService] falls back to the literal
  /// templates from the API spec when a key is missing.
  final Map<String, String> channelTemplates;

  const RealtimeConfigModel({
    required this.key,
    required this.host,
    required this.port,
    required this.useTls,
    required this.authEndpoint,
    required this.channelTemplates,
  });

  factory RealtimeConfigModel.fromJson(Map<String, dynamic> json) {
    final channels = json['channels'];
    final useTls = json['use_tls'] as bool? ?? true;
    return RealtimeConfigModel(
      key: json['key'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? (useTls ? 443 : 80),
      useTls: useTls,
      authEndpoint: json['auth_endpoint'] as String,
      channelTemplates: channels is Map
          ? channels.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}
