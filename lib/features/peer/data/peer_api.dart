import '../../../core/api/api_client.dart';
import 'peer_models.dart';

/// REST slice of peer speaking: room creation. All the live traffic goes over
/// the signaling WebSocket ([PeerSignaling]) instead.
class PeerApi {
  PeerApi(this._client);

  final ApiClient _client;

  Future<PeerRoom> createRoom() async {
    final data = await _client.post('/peer/rooms');
    return PeerRoom.fromJson(
      Map<String, dynamic>.from(data['room'] as Map),
    );
  }

  Future<PeerHub> history() async {
    final data = await _client.get('/peer/history');
    return PeerHub(
      calls: (data['calls'] as List? ?? const [])
          .map((e) => PeerCallLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      online: (data['online'] as num?)?.toInt() ?? 0,
    );
  }
}
