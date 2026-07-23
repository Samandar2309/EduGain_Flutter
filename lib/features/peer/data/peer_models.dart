/// Peer speaking domain models — the room and its symmetric role-play card.
class PeerTopic {
  const PeerTopic({
    required this.id,
    required this.title,
    required this.yourRole,
    required this.partnerRole,
    required this.starters,
  });

  final String id;
  final String title;
  final String yourRole;
  final String partnerRole;
  final List<String> starters;

  factory PeerTopic.fromJson(Map<String, dynamic> json) => PeerTopic(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    yourRole: json['your_role'] as String? ?? '',
    partnerRole: json['partner_role'] as String? ?? '',
    starters: List<String>.from(json['starters'] as List? ?? const []),
  );
}

class PeerRoom {
  const PeerRoom({required this.code, required this.topic});

  final String code;
  final PeerTopic topic;

  factory PeerRoom.fromJson(Map<String, dynamic> json) => PeerRoom(
    code: json['code'] as String,
    topic: PeerTopic.fromJson(
      Map<String, dynamic>.from(json['topic'] as Map? ?? const {}),
    ),
  );
}

/// One finished conversation from the learner's history.
class PeerCallLog {
  const PeerCallLog({
    required this.partnerName,
    required this.topic,
    required this.startedAt,
    required this.durationSeconds,
  });

  final String partnerName;
  final String topic;
  final DateTime startedAt;
  final int durationSeconds;

  factory PeerCallLog.fromJson(Map<String, dynamic> json) => PeerCallLog(
    partnerName: json['partner_name'] as String? ?? 'Partner',
    topic: json['topic'] as String? ?? '',
    startedAt:
        DateTime.tryParse(json['started_at'] as String? ?? '') ?? DateTime.now(),
    durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
  );
}

/// The hub payload: history + how many learners are online right now.
class PeerHub {
  const PeerHub({required this.calls, required this.online});

  final List<PeerCallLog> calls;
  final int online;
}
