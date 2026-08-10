import '../../../core/api/api_client.dart';
import 'group_models.dart';

/// REST for group speaking: topics, room creation, and the public lobby.
/// The live call itself runs over the signaling WebSocket ([GroupSignaling]).
class GroupApi {
  GroupApi(this._client);
  final ApiClient _client;

  /// Topics plus the room cap, which the create sheet has to show before a
  /// room exists to read it from.
  ///
  /// The cap comes from the server rather than a constant in the app: the two
  /// were mirrored before, and drifted the moment the SFU raised the ceiling —
  /// the sheet went on offering rooms "for up to 8" while the server allowed
  /// 50. It also stops being one number once room size follows the
  /// subscription tier.
  Future<GroupConfig> listTopics() async {
    final data = await _client.get('/group/topics');
    return GroupConfig(
      topics: (data['topics'] as List? ?? const [])
          .map((e) => GroupTopic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      maxParticipants: (data['max_participants'] as num?)?.toInt() ?? 8,
    );
  }

  /// The lobby — live PUBLIC rooms, newest first.
  Future<List<GroupRoom>> listRooms() async {
    final data = await _client.get('/group/rooms');
    return (data['rooms'] as List? ?? const [])
        .map((e) => GroupRoom.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<GroupRoom> createRoom({
    required String topicId,
    required bool isPublic,
    required int maxParticipants,
    required String name,
    String title = '',
    String level = '',
  }) async {
    final data = await _client.post('/group/rooms', body: {
      'topic_id': topicId,
      'visibility': isPublic ? 'public' : 'private',
      'max': maxParticipants,
      'name': name,
      if (title.isNotEmpty) 'title': title,
      if (level.isNotEmpty) 'level': level,
    });
    return GroupRoom.fromJson(Map<String, dynamic>.from(data['room'] as Map));
  }

  Future<GroupRoom> preview(String code) async {
    final data = await _client.get('/group/rooms/$code');
    return GroupRoom.fromJson(Map<String, dynamic>.from(data['room'] as Map));
  }
}
