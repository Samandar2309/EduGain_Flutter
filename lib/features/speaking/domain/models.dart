// Speaking domain models mirroring the backend DTOs (§3, §4.4).

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
/// An unfinished conversation waiting to be walked back into.
///
/// A session lives on the server, so it survives the app being killed — which
/// in a Telegram Mini App happens constantly (a call, another chat, a swipe
/// away). Without this the next session silently abandoned it, taking the
/// transcript and the speaking minutes already spent with it.
class ResumableSession {
  const ResumableSession({
    required this.session,
    required this.lastMessage,
    required this.title,
    required this.backdropKey,
  });

  final SpeakingSession session;
  /// The tutor's last line — shown and spoken on resume so the learner lands
  /// back in context instead of on a blank screen.
  final ChatMessage lastMessage;
  final String title;
  final String backdropKey;

  factory ResumableSession.fromJson(Map<String, dynamic> json) =>
      ResumableSession(
        session: SpeakingSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
        lastMessage: ChatMessage.fromJson(
          json['last_message'] as Map<String, dynamic>,
        ),
        title: json['title'] as String? ?? '',
        backdropKey: json['backdrop'] as String? ?? '',
      );

  /// Re-enter the same conversation: the launch the chat screen expects.
  SpeakingLaunch toLaunch() => SpeakingLaunch(
    started: StartedSession(session: session, firstMessage: lastMessage),
    backdropKey: backdropKey.isEmpty ? null : backdropKey,
    title: title.isEmpty ? null : title,
  );
}

class SpeakingHome {
  const SpeakingHome({
    required this.cefrLevel,
    required this.activeSession,
    required this.continueLesson,
    required this.dailyMission,
    required this.recommendedTrack,
    required this.recommendedLesson,
    required this.tracks,
    required this.lessonsDone,
    required this.lessonsTotal,
  });

  final String cefrLevel;
  final ResumableSession? activeSession;
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
      activeSession: json['active_session'] == null
          ? null
          : ResumableSession.fromJson(
              json['active_session'] as Map<String, dynamic>,
            ),
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
    this.lessonKey,
    this.freeTopic,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String status; // active | completed | abandoned | limited
  final int turnCount;
  final int maxTurns;
  final int quotaRemaining;

  // What the conversation was about + when — only needed by the history list,
  // so they stay nullable for every other caller.
  final String? lessonKey;
  final String? freeTopic;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get isActive => status == 'active';
  int get turnsLeft => (maxTurns - turnCount).clamp(0, maxTurns);

  factory SpeakingSession.fromJson(Map<String, dynamic> json) =>
      SpeakingSession(
        id: json['id'] as String,
        status: json['status'] as String? ?? 'active',
        turnCount: (json['turn_count'] as num?)?.toInt() ?? 0,
        maxTurns: (json['max_turns'] as num?)?.toInt() ?? 0,
        quotaRemaining: (json['quota_remaining'] as num?)?.toInt() ?? 0,
        lessonKey: json['lesson_key'] as String?,
        freeTopic: json['free_topic'] as String?,
        startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
        endedAt: DateTime.tryParse(json['ended_at'] as String? ?? ''),
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
    this.scoreDeltas,
  });

  final String? cefrEstimate;
  final String summary;
  final FeedbackScores? scores;
  final List<FeedbackError> errors;
  final List<String> strengths;
  final bool isLocked;

  /// Per-skill change vs the learner's previous session (e.g. {"grammar": 7}).
  /// Null when either side is missing — the UI shows the score without arrows.
  final Map<String, int>? scoreDeltas;

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
    scoreDeltas: json['score_deltas'] == null
        ? null
        : (json['score_deltas'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ),
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
    this.freeTopic,
    this.backdropKey,
    this.title,
  });
  final StartedSession started;
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
  const TranscriptEvent(this.text, {this.clarity});
  final String text;

  /// How confidently the recogniser read the audio, 0..1, or null when the
  /// provider gave no signal. NOT a pronunciation score — a noisy room lowers
  /// it too — so it is only ever used to suggest repeating an answer.
  final double? clarity;

  /// Low enough that the learner is likely to have been misheard. Deliberately
  /// conservative: a false "we could not hear you" is more discouraging than
  /// staying quiet.
  bool get wasHardToHear => clarity != null && clarity! < 0.35;
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

/// Today's speaking budget (`GET /speaking/quota`) — drives the minutes ring.
/// `used` is clamped server-side, so the remainder is never negative.
class SpeakingQuota {
  const SpeakingQuota({
    required this.sessionsRemaining,
    required this.secondsLimit,
    required this.secondsUsed,
    this.aiUnlocked = false,
    this.resetsInSeconds = 0,
  });

  final int sessionsRemaining;
  final int secondsLimit;
  final int secondsUsed;

  /// How long until today's budget refills.
  ///
  /// A duration the server measured, never a time this device computed. Phone
  /// clocks are wrong often enough that subtracting one from a timestamp has
  /// already produced a nine-second room timer elsewhere in this app.
  ///
  /// Zero means the server did not say — an older build, a field that went
  /// missing — and the caller must then simply not schedule anything rather
  /// than treat "now" as the answer and spin.
  final int resetsInSeconds;

  /// Whether the AI tutor is open to this learner yet.
  ///
  /// Defaults to false, which is the important half: a response we could not
  /// parse, an old build talking to a new server, a field that goes missing —
  /// every one of those shows the "coming soon" card rather than a door that
  /// opens onto a 423.
  final bool aiUnlocked;

  int get secondsRemaining => (secondsLimit - secondsUsed).clamp(0, 1 << 31);
  bool get isExhausted => secondsLimit > 0 && secondsRemaining <= 0;

  /// 0..1 of today's budget still available.
  double get remainingRatio =>
      secondsLimit == 0 ? 0 : (secondsRemaining / secondsLimit).clamp(0.0, 1.0);

  /// Whole minutes shown to the learner (partial minutes round up, so the ring
  /// never says "0 min" while seconds remain).
  int get minutesRemaining => (secondsRemaining / 60).ceil();
  int get minutesLimit => (secondsLimit / 60).round();
  int get minutesUsed => minutesLimit - minutesRemaining;

  factory SpeakingQuota.fromJson(Map<String, dynamic> json) {
    final speaking = (json['speaking'] as Map?) ?? const {};
    return SpeakingQuota(
      sessionsRemaining: (json['sessions_remaining'] as num?)?.toInt() ?? 0,
      secondsLimit: (speaking['seconds_limit'] as num?)?.toInt() ?? 0,
      secondsUsed: (speaking['seconds_used'] as num?)?.toInt() ?? 0,
      aiUnlocked: json['ai_unlocked'] as bool? ?? false,
      resetsInSeconds: (speaking['resets_in_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One ability's smoothed trend inside the Communication Profile.
class AbilityTrend {
  const AbilityTrend({
    required this.current,
    required this.delta,
    required this.samples,
  });

  final double current; // EWMA-smoothed 0..100
  final double? delta; // change vs the previous smoothed value
  final int samples; // scored sessions behind the number

  factory AbilityTrend.fromJson(Map<String, dynamic> json) => AbilityTrend(
    current: (json['current'] as num?)?.toDouble() ?? 0,
    delta: (json['delta'] as num?)?.toDouble(),
    samples: (json['samples'] as num?)?.toInt() ?? 0,
  );
}

/// The learner's Communication Profile (`GET /speaking/profile`): observed
/// weak points + measured fluency + smoothed ability trends. Axes follow the
/// honesty rule — null until actually measured, and the UI must not invent
/// numbers for them.
class LearnerProfile {
  const LearnerProfile({
    required this.focusTags,
    required this.voicedMinutes,
    required this.spokenWords,
    required this.wordsPerMinute,
    required this.wpmTarget,
    required this.abilities,
    required this.hasMemory,
  });

  final List<String> focusTags; // recurring error tags, worst first
  final double? voicedMinutes; // total voiced speaking time
  final int spokenWords;
  final double? wordsPerMinute; // null under the measurement floor
  final int wpmTarget;
  final Map<String, AbilityTrend> abilities; // grammar/vocabulary/overall
  final bool hasMemory;

  /// True when nothing measurable exists yet — the UI shows a friendly
  /// "start speaking" state instead of a wall of zeros.
  bool get isEmpty =>
      focusTags.isEmpty && abilities.isEmpty && spokenWords == 0;

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    final fluency = (json['fluency'] as Map?) ?? const {};
    final abilities = (json['abilities'] as Map?) ?? const {};
    return LearnerProfile(
      focusTags: ((json['focus_tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      voicedMinutes: (fluency['voiced_minutes'] as num?)?.toDouble(),
      spokenWords: (fluency['spoken_words'] as num?)?.toInt() ?? 0,
      wordsPerMinute: (fluency['words_per_minute'] as num?)?.toDouble(),
      wpmTarget: (fluency['wpm_target'] as num?)?.toInt() ?? 140,
      abilities: abilities.map(
        (k, v) => MapEntry(
          k.toString(),
          AbilityTrend.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      hasMemory: json['has_memory'] as bool? ?? false,
    );
  }
}
