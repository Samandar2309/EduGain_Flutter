import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config.dart';

/// The signaling WebSocket for a group room: a thin JSON pipe to
/// `/api/v1/group/ws`. The server relays directed offer/answer/ICE between
/// every pair in the mesh; media itself never touches it.
class GroupSignaling {
  GroupSignaling._(this._channel);

  final WebSocketChannel _channel;

  /// The JWT rides a query param because a browser cannot set headers on a
  /// WebSocket; [lang] rides along for the same reason — the handshake would
  /// otherwise carry the browser's own locale rather than the one the learner
  /// picked, and the room's topic card would come back in the wrong language.
  static Uri wsUri({
    required String token,
    required String name,
    required String code,
    String lang = '',
    String avatar = '',
  }) {
    var base = Uri.parse(AppConfig.apiBaseUrl);
    if (!base.hasScheme) {
      base = Uri.base.resolveUri(base);
    }
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/group/ws',
      queryParameters: {
        'token': token,
        'name': name,
        'code': code,
        if (lang.isNotEmpty) 'lang': lang,
        // The learner's Telegram photo, so every other phone in the room can
        // draw it. Passed here rather than looked up per member: the room only
        // knows user ids, and a lookup per participant would be 50 requests to
        // render one screen.
        if (avatar.isNotEmpty) 'avatar': avatar,
      },
    );
  }

  static GroupSignaling connect({
    required String token,
    required String name,
    required String code,
    String lang = '',
    String avatar = '',
  }) => GroupSignaling._(
    WebSocketChannel.connect(
      wsUri(token: token, name: name, code: code, lang: lang, avatar: avatar),
    ),
  );

  Stream<Map<String, dynamic>> get messages => _channel.stream.map((raw) {
    final decoded = jsonDecode(raw as String);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  });

  void send(Map<String, dynamic> message) =>
      _channel.sink.add(jsonEncode(message));

  Future<void> close() => _channel.sink.close();
}
