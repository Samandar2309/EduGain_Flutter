// Speaking domain models mirroring the backend DTOs (§3, §4.4).

class Scenario {
  const Scenario({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.cefrMin,
    required this.cefrMax,
    required this.isPremium,
    required this.isLocked,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String cefrMin;
  final String cefrMax;
  final bool isPremium;
  final bool isLocked;

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    cefrMin: json['cefr_min'] as String? ?? '',
    cefrMax: json['cefr_max'] as String? ?? '',
    isPremium: json['is_premium'] as bool? ?? false,
    isLocked: json['is_locked'] as bool? ?? false,
  );
}

class SpeakingSession {
  const SpeakingSession({
    required this.id,
    required this.status,
    required this.turnCount,
    required this.maxTurns,
    required this.quotaRemaining,
  });

  final String id;
  final String status; // active | completed | abandoned | limited
  final int turnCount;
  final int maxTurns;
  final int quotaRemaining;

  bool get isActive => status == 'active';
  int get turnsLeft => (maxTurns - turnCount).clamp(0, maxTurns);

  factory SpeakingSession.fromJson(Map<String, dynamic> json) =>
      SpeakingSession(
        id: json['id'] as String,
        status: json['status'] as String? ?? 'active',
        turnCount: (json['turn_count'] as num?)?.toInt() ?? 0,
        maxTurns: (json['max_turns'] as num?)?.toInt() ?? 0,
        quotaRemaining: (json['quota_remaining'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role; // user | assistant
  final String content;

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] as String,
    content: json['content'] as String? ?? '',
  );
}

class FeedbackError {
  const FeedbackError({
    required this.original,
    required this.correction,
    required this.type,
    required this.explanation,
  });

  final String original;
  final String correction;
  final String type;
  final String explanation;

  factory FeedbackError.fromJson(Map<String, dynamic> json) => FeedbackError(
    original: json['original'] as String? ?? '',
    correction: json['correction'] as String? ?? '',
    type: json['type'] as String? ?? 'grammar',
    explanation: json['explanation'] as String? ?? '',
  );
}

class FeedbackReport {
  const FeedbackReport({
    required this.cefrEstimate,
    required this.summary,
    required this.errors,
    required this.strengths,
    required this.isLocked,
  });

  final String? cefrEstimate;
  final String summary;
  final List<FeedbackError> errors;
  final List<String> strengths;
  final bool isLocked;

  factory FeedbackReport.fromJson(Map<String, dynamic> json) => FeedbackReport(
    cefrEstimate: json['cefr_estimate'] as String?,
    summary: json['summary'] as String? ?? '',
    errors: ((json['errors'] as List?) ?? [])
        .map((e) => FeedbackError.fromJson(e as Map<String, dynamic>))
        .toList(),
    strengths: ((json['strengths'] as List?) ?? [])
        .map((e) => e.toString())
        .toList(),
    isLocked: json['is_locked'] as bool? ?? false,
  );
}

/// Result of starting a session: the session + the AI's opening message.
class StartedSession {
  const StartedSession({required this.session, required this.firstMessage});
  final SpeakingSession session;
  final ChatMessage firstMessage;
}

// ── SSE events (§5: chunk / done / error) ──────────────────────────────────
sealed class SpeakingEvent {
  const SpeakingEvent();
}

class ChunkEvent extends SpeakingEvent {
  const ChunkEvent(this.text);
  final String text;
}

class DoneEvent extends SpeakingEvent {
  const DoneEvent(this.session);
  final SpeakingSession session;
}

class StreamErrorEvent extends SpeakingEvent {
  const StreamErrorEvent(this.code, this.message);
  final String code;
  final String message;
}
