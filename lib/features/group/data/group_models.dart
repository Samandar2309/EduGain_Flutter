// Group speaking domain models — a discussion room and its topic.

class GroupTopic {
  const GroupTopic({required this.id, required this.title, required this.prompt});

  final String id;
  final String title;
  final String prompt;

  factory GroupTopic.fromJson(Map<String, dynamic> json) => GroupTopic(
    id: json['id'] as String? ?? 'free',
    title: json['title'] as String? ?? '',
    prompt: json['prompt'] as String? ?? '',
  );
}

/// A room as seen in the lobby / preview.
class GroupRoom {
  const GroupRoom({
    required this.code,
    required this.title,
    required this.topic,
    required this.level,
    required this.hostName,
    required this.visibility,
    required this.count,
    required this.max,
    required this.status,
  });

  final String code;
  final String title;
  final GroupTopic topic;
  final String level;
  final String hostName;
  final String visibility; // public | private
  final int count;
  final int max;
  final String status; // waiting | live

  bool get isPublic => visibility == 'public';
  bool get isFull => count >= max;

  factory GroupRoom.fromJson(Map<String, dynamic> json) => GroupRoom(
    code: json['code'] as String,
    title: (json['title'] as String?)?.trim().isNotEmpty == true
        ? json['title'] as String
        : GroupTopic.fromJson(
            Map<String, dynamic>.from(json['topic'] as Map? ?? const {}),
          ).title,
    topic: GroupTopic.fromJson(
      Map<String, dynamic>.from(json['topic'] as Map? ?? const {}),
    ),
    level: json['level'] as String? ?? '',
    hostName: json['host_name'] as String? ?? '',
    visibility: json['visibility'] as String? ?? 'public',
    count: (json['count'] as num?)?.toInt() ?? 0,
    max: (json['max'] as num?)?.toInt() ?? 5,
    status: json['status'] as String? ?? 'waiting',
  );
}

/// What the server says a group room may be, fetched before one is created.
///
/// Carries the cap alongside the topics because both answer the same question —
/// "what can I make here?" — and a second request for one integer would be a
/// round trip on the path to starting a call.
class GroupConfig {
  const GroupConfig({required this.topics, required this.maxParticipants});
  final List<GroupTopic> topics;
  final int maxParticipants;
}
