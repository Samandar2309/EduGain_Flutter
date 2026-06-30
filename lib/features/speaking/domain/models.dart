// Speaking domain models mirroring the backend DTOs (§3, §4.4).

class Scenario {
  const Scenario({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.category,
    required this.cefrMin,
    required this.cefrMax,
    required this.isPremium,
    required this.isLocked,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String category;
  final String cefrMin;
  final String cefrMax;
  final bool isPremium;
  final bool isLocked;

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    cefrMin: json['cefr_min'] as String? ?? '',
    cefrMax: json['cefr_max'] as String? ?? '',
    isPremium: json['is_premium'] as bool? ?? false,
    isLocked: json['is_locked'] as bool? ?? false,
  );
}

/// One of the five goal paths shown on the Speaking home (`GET /speaking/tracks`).
class TrackSummary {
  const TrackSummary({
    required this.track,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backdrop,
    required this.lessonsTotal,
    required this.lessonsDone,
    required this.isRecommended,
  });

  final String track; // cefr | daily | real_life | ielts | career
  final String title;
  final String subtitle;
  final String icon; // semantic key (graduation/microphone/globe/book/briefcase)
  final String backdrop; // scenario_theme key for the card accent
  final int lessonsTotal;
  final int lessonsDone;
  final bool isRecommended;

  double get progress =>
      lessonsTotal == 0 ? 0 : (lessonsDone / lessonsTotal).clamp(0, 1).toDouble();

  factory TrackSummary.fromJson(Map<String, dynamic> json) => TrackSummary(
    track: json['track'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    icon: json['icon'] as String? ?? 'spark',
    backdrop: json['backdrop'] as String? ?? 'default',
    lessonsTotal: (json['lessons_total'] as num?)?.toInt() ?? 0,
    lessonsDone: (json['lessons_done'] as num?)?.toInt() ?? 0,
    isRecommended: json['is_recommended'] as bool? ?? false,
  );
}

/// The Speaking home payload: the goal tracks plus a placement-driven hint.
class TrackCatalog {
  const TrackCatalog({
    required this.cefrLevel,
    required this.recommendedTrack,
    required this.recommendedLessonKey,
    required this.tracks,
  });

  final String cefrLevel;
  final String recommendedTrack;
  final String recommendedLessonKey;
  final List<TrackSummary> tracks;

  factory TrackCatalog.fromJson(Map<String, dynamic> json) => TrackCatalog(
    cefrLevel: json['cefr_level'] as String? ?? '',
    recommendedTrack: json['recommended_track'] as String? ?? '',
    recommendedLessonKey: json['recommended_lesson_key'] as String? ?? '',
    tracks: ((json['tracks'] as List?) ?? [])
        .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// One selectable lesson inside a track (`GET /speaking/tracks/{track}`).
class TrackLesson {
  const TrackLesson({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.backdrop,
    required this.cefrMin,
    required this.cefrMax,
    required this.difficulty,
    required this.estMinutes,
    required this.xpReward,
    required this.objective,
    required this.mission,
    required this.grammarFocus,
    required this.vocabulary,
    required this.feedbackCriteria,
    required this.isPremium,
    required this.isLocked,
    required this.isDone,
  });

  final String key; // e.g. "ielts.part2" — sent back to start the session
  final String title;
  final String subtitle;
  final String backdrop; // scenario_theme key (avatar + background)
  final String cefrMin;
  final String cefrMax;
  final String difficulty; // easy | medium | hard
  final int estMinutes; // rough duration
  final int xpReward; // XP awarded on completion
  // Teaching content shown on the card / pre-lesson briefing.
  final String objective;
  final String mission;
  final String grammarFocus;
  final List<String> vocabulary;
  final List<String> feedbackCriteria;
  final bool isPremium;
  final bool isLocked;
  final bool isDone;

  static List<String> _strs(Object? v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  factory TrackLesson.fromJson(Map<String, dynamic> json) => TrackLesson(
    key: json['key'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    backdrop: json['backdrop'] as String? ?? 'default',
    cefrMin: json['cefr_min'] as String? ?? '',
    cefrMax: json['cefr_max'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'medium',
    estMinutes: (json['est_minutes'] as num?)?.toInt() ?? 5,
    xpReward: (json['xp_reward'] as num?)?.toInt() ?? 20,
    objective: json['objective'] as String? ?? '',
    mission: json['mission'] as String? ?? '',
    grammarFocus: json['grammar_focus'] as String? ?? '',
    vocabulary: _strs(json['vocabulary']),
    feedbackCriteria: _strs(json['feedback_criteria']),
    isPremium: json['is_premium'] as bool? ?? false,
    isLocked: json['is_locked'] as bool? ?? false,
    isDone: json['is_done'] as bool? ?? false,
  );
}

/// The "Continue Learning" hero on the Speaking home: where the learner left off.
class ContinueLesson {
  const ContinueLesson({
    required this.lessonKey,
    required this.track,
    required this.trackTitle,
    required this.title,
    required this.subtitle,
    required this.backdrop,
    required this.cefrMin,
    required this.cefrMax,
    required this.difficulty,
    required this.estMinutes,
    required this.xpReward,
    required this.objective,
    required this.grammarFocus,
    required this.progress,
    required this.isCompleted,
    required this.lastOpened,
  });

  final String lessonKey;
  final String track;
  final String trackTitle;
  final String title;
  final String subtitle;
  final String backdrop;
  final String cefrMin;
  final String cefrMax;
  final String difficulty;
  final int estMinutes;
  final int xpReward;
  final String objective;
  final String grammarFocus;
  final double progress; // 0..1
  final bool isCompleted;
  final DateTime? lastOpened;

  factory ContinueLesson.fromJson(Map<String, dynamic> json) => ContinueLesson(
    lessonKey: json['lesson_key'] as String,
    track: json['track'] as String? ?? '',
    trackTitle: json['track_title'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    backdrop: json['backdrop'] as String? ?? 'default',
    cefrMin: json['cefr_min'] as String? ?? '',
    cefrMax: json['cefr_max'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'medium',
    estMinutes: (json['est_minutes'] as num?)?.toInt() ?? 5,
    xpReward: (json['xp_reward'] as num?)?.toInt() ?? 20,
    objective: json['objective'] as String? ?? '',
    grammarFocus: json['grammar_focus'] as String? ?? '',
    progress: ((json['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble(),
    isCompleted: json['is_completed'] as bool? ?? false,
    lastOpened: DateTime.tryParse(json['last_opened'] as String? ?? ''),
  );
}

/// Today's auto-rotating speaking mission.
class DailyMission {
  const DailyMission({
    required this.lessonKey,
    required this.title,
    required this.subtitle,
    required this.backdrop,
    required this.difficulty,
    required this.estMinutes,
    required this.xpReward,
  });

  final String lessonKey;
  final String title;
  final String subtitle;
  final String backdrop;
  final String difficulty;
  final int estMinutes;
  final int xpReward;

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
    lessonKey: json['lesson_key'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    backdrop: json['backdrop'] as String? ?? 'daily',
    difficulty: json['difficulty'] as String? ?? 'easy',
    estMinutes: (json['est_minutes'] as num?)?.toInt() ?? 5,
    xpReward: (json['xp_reward'] as num?)?.toInt() ?? 20,
  );
}

/// The whole Speaking home payload (`GET /speaking/home`) — one call so the
/// page opens instantly with everything it needs.
class SpeakingHome {
  const SpeakingHome({
    required this.cefrLevel,
    required this.continueLesson,
    required this.dailyMission,
    required this.recommendedTrack,
    required this.recommendedLesson,
    required this.tracks,
    required this.lessonsDone,
    required this.lessonsTotal,
  });

  final String cefrLevel;
  final ContinueLesson? continueLesson;
  final DailyMission? dailyMission;
  final String recommendedTrack;
  final TrackLesson? recommendedLesson;
  final List<TrackSummary> tracks;
  final int lessonsDone;
  final int lessonsTotal;

  factory SpeakingHome.fromJson(Map<String, dynamic> json) {
    final summary = (json['progress_summary'] as Map?) ?? const {};
    return SpeakingHome(
      cefrLevel: json['cefr_level'] as String? ?? '',
      continueLesson: json['continue_lesson'] == null
          ? null
          : ContinueLesson.fromJson(
              json['continue_lesson'] as Map<String, dynamic>,
            ),
      dailyMission: json['daily_mission'] == null
          ? null
          : DailyMission.fromJson(json['daily_mission'] as Map<String, dynamic>),
      recommendedTrack: json['recommended_track'] as String? ?? '',
      recommendedLesson: json['recommended_lesson'] == null
          ? null
          : TrackLesson.fromJson(
              json['recommended_lesson'] as Map<String, dynamic>,
            ),
      tracks: ((json['tracks'] as List?) ?? [])
          .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      lessonsDone: (summary['lessons_done'] as num?)?.toInt() ?? 0,
      lessonsTotal: (summary['lessons_total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A track's detail page: its title plus the lessons within it.
class TrackDetail {
  const TrackDetail({
    required this.track,
    required this.title,
    required this.subtitle,
    required this.lessons,
  });

  final String track;
  final String title;
  final String subtitle;
  final List<TrackLesson> lessons;

  factory TrackDetail.fromJson(Map<String, dynamic> json) => TrackDetail(
    track: json['track'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    lessons: ((json['lessons'] as List?) ?? [])
        .map((e) => TrackLesson.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// A selectable TTS voice from the server catalogue (`GET /speaking/voices`).
/// The catalogue is server-curated, so every device offers the same voices.
class Voice {
  const Voice({
    required this.id,
    required this.name,
    required this.gender,
    required this.accent,
  });

  final String id; // provider token, sent back on synthesis (e.g. "troy")
  final String name; // display label (e.g. "Troy")
  final String gender; // "male" | "female"
  final String accent; // free-text label (e.g. "American")

  factory Voice.fromJson(Map<String, dynamic> json) => Voice(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    gender: json['gender'] as String? ?? '',
    accent: json['accent'] as String? ?? '',
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

/// Per-skill report-card scores (0–100). `fluency` and `pronunciation` are
/// model estimates from the transcript (no audio assessment yet).
class FeedbackScores {
  const FeedbackScores({
    required this.grammar,
    required this.vocabulary,
    required this.fluency,
    required this.pronunciation,
    required this.overall,
  });

  final int grammar;
  final int vocabulary;
  final int fluency;
  final int pronunciation;
  final int overall;

  static int _pct(Object? v) => ((v as num?)?.toInt() ?? 0).clamp(0, 100);

  factory FeedbackScores.fromJson(Map<String, dynamic> json) => FeedbackScores(
    grammar: _pct(json['grammar']),
    vocabulary: _pct(json['vocabulary']),
    fluency: _pct(json['fluency']),
    pronunciation: _pct(json['pronunciation']),
    overall: _pct(json['overall']),
  );
}

class FeedbackReport {
  const FeedbackReport({
    required this.cefrEstimate,
    required this.summary,
    required this.scores,
    required this.errors,
    required this.strengths,
    required this.isLocked,
  });

  final String? cefrEstimate;
  final String summary;
  final FeedbackScores? scores;
  final List<FeedbackError> errors;
  final List<String> strengths;
  final bool isLocked;

  factory FeedbackReport.fromJson(Map<String, dynamic> json) => FeedbackReport(
    cefrEstimate: json['cefr_estimate'] as String?,
    summary: json['summary'] as String? ?? '',
    scores: json['scores'] == null
        ? null
        : FeedbackScores.fromJson(json['scores'] as Map<String, dynamic>),
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

/// Everything the immersive chat screen needs to launch: the started session
/// plus what was picked, so it can theme the scenario backdrop. A track lesson
/// passes its [backdropKey] + [title] directly (no Django scenario involved).
class SpeakingLaunch {
  const SpeakingLaunch({
    required this.started,
    this.scenario,
    this.freeTopic,
    this.backdropKey,
    this.title,
  });
  final StartedSession started;
  final Scenario? scenario;
  final String? freeTopic;
  final String? backdropKey; // track lesson theme key (scenario_theme)
  final String? title; // header title for a track lesson
}

/// Per-turn coaching on the learner's utterance (the "one reply, many benefits"
/// micro-lesson). `emotion` drives the avatar's reaction.
class Coaching {
  const Coaching({
    required this.understood,
    required this.hasErrors,
    required this.correction,
    required this.naturalVersion,
    required this.grammarPoint,
    required this.vocabulary,
    required this.pronunciation,
    required this.errorTags,
    required this.emotion,
  });

  final String understood;
  final bool hasErrors;
  final String correction;
  final String naturalVersion;
  final String grammarPoint;
  final List<String> vocabulary;
  final List<String> pronunciation;
  final List<String> errorTags;
  final String emotion; // neutral|happy|encouraging|surprised|thinking|proud|curious

  static List<String> _strs(Object? v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  factory Coaching.fromJson(Map<String, dynamic> json) => Coaching(
    understood: json['understood'] as String? ?? '',
    hasErrors: json['has_errors'] as bool? ?? false,
    correction: json['correction'] as String? ?? '',
    naturalVersion: json['natural_version'] as String? ?? '',
    grammarPoint: json['grammar_point'] as String? ?? '',
    vocabulary: _strs(json['vocabulary']),
    pronunciation: _strs(json['pronunciation']),
    errorTags: _strs(json['error_tags']),
    emotion: json['emotion'] as String? ?? 'neutral',
  );
}

// ── SSE events (§5: transcript / chunk / coaching / done / error) ──────────
sealed class SpeakingEvent {
  const SpeakingEvent();
}

/// Audio turns only: the speech-to-text result, sent before the reply streams
/// so the UI can show what the learner said.
class TranscriptEvent extends SpeakingEvent {
  const TranscriptEvent(this.text);
  final String text;
}

class ChunkEvent extends SpeakingEvent {
  const ChunkEvent(this.text);
  final String text;
}

/// The per-turn coaching, sent after the reply chunks and before [DoneEvent].
class CoachingEvent extends SpeakingEvent {
  const CoachingEvent(this.coaching);
  final Coaching coaching;
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
