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
  /// param (the server verifies it exactly like a bearer header). [lang] rides
  /// along for the same reason: the handshake would otherwise carry the
  /// browser's own locale, not the one the learner picked in the app, and the
  /// role-play card would come back in the wrong language.
  static Uri wsUri({
    required String token,
    required String name,
    String avatar = '',
    String pref = '',
    String room = '',
    String mode = '',
    String game = '',
    String lang = '',
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
        if (avatar.isNotEmpty) 'avatar': avatar,
        // Only sent when it narrows something. An absent param and "any" mean
        // the same thing, and the server defaults to the wider of the two.
        if (pref.isNotEmpty && pref != 'any') 'pref': pref,
        if (room.isNotEmpty) 'room': room,
        if (mode.isNotEmpty) 'mode': mode,
        if (game.isNotEmpty) 'game': game,
        if (lang.isNotEmpty) 'lang': lang,
      },
    );
  }

  static PeerSignaling connect({
    required String token,
    required String name,
    String avatar = '',
    String pref = '',
    String room = '',
    String mode = '',
    String game = '',
    String lang = '',
  }) => PeerSignaling._(
    WebSocketChannel.connect(
      wsUri(
        token: token,
        name: name,
        avatar: avatar,
        pref: pref,
        room: room,
        mode: mode,
        game: game,
        lang: lang,
      ),
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

  /// Why the server hung up, once it has.
  ///
  /// A closed socket is otherwise indistinguishable from a dropped connection,
  /// so without this a learner who has simply used up their daily live-
  /// conversation minutes is told the call "failed" — and tries again, and is
  /// told the same thing.
  int? get closeCode => _channel.closeCode;
}
