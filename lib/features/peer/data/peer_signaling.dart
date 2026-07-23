import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config.dart';

/// The signaling WebSocket: a thin JSON pipe to `/api/v1/peer/ws`. The server
/// relays offer/answer/ICE between the two sides of a room; media itself never
/// touches it.
class PeerSignaling {
  PeerSignaling._(this._channel);

  final WebSocketChannel _channel;

  /// Browsers can't set headers on a WebSocket, so the JWT rides a query
  /// param (the server verifies it exactly like a bearer header).
  static Uri wsUri({
    required String token,
    required String name,
    String room = '',
    String mode = '',
    String game = '',
  }) {
    var base = Uri.parse(AppConfig.apiBaseUrl);
    if (!base.hasScheme) {
      // Web build uses a relative API base ('/api/v1') — resolve against the
      // page origin so ws(s):// points at the same host.
      base = Uri.base.resolveUri(base);
    }
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/peer/ws',
      queryParameters: {
        'token': token,
        'name': name,
        if (room.isNotEmpty) 'room': room,
        if (mode.isNotEmpty) 'mode': mode,
        if (game.isNotEmpty) 'game': game,
      },
    );
  }

  static PeerSignaling connect({
    required String token,
    required String name,
    String room = '',
    String mode = '',
    String game = '',
  }) => PeerSignaling._(
    WebSocketChannel.connect(
      wsUri(token: token, name: name, room: room, mode: mode, game: game),
    ),
  );

  Stream<Map<String, dynamic>> get messages =>
      _channel.stream.map((raw) {
        final decoded = jsonDecode(raw as String);
        return decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
      });

  void send(Map<String, dynamic> message) =>
      _channel.sink.add(jsonEncode(message));

  Future<void> close() => _channel.sink.close();
}
