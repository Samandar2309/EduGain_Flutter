/// The question bank: a part, its topics, and their questions.
///
/// The shape mirrors the exam because that grouping is already in learners'
/// heads — but nothing here is exam-specific, so the same structure carries
/// everyday and real-life topics when those are added.
library;

/// A Part 2 task: one prompt, the points to cover, and the closing turn.
///
/// Not a list of questions, and rendered as its own screen for that reason.
/// A learner who reads the bullets as four questions gives four short answers
/// instead of one long turn — the exact mistake the exam marks down.
class CueCard {
  const CueCard({
    required this.prompt,
    required this.bullets,
    required this.closing,
    required this.prepSeconds,
    required this.talkSeconds,
  });

  final String prompt;
  final List<String> bullets;

  /// The "and explain why…" line. Carries most of the marks and is the part
  /// learners skip, so it is shown apart from the bullets rather than as one.
  final String closing;
  final int prepSeconds;
  final int talkSeconds;

  factory CueCard.fromJson(Map<String, dynamic> json) => CueCard(
    prompt: json['prompt'] as String? ?? '',
    bullets: ((json['bullets'] as List?) ?? const [])
        .map((b) => b as String)
        .toList(),
    closing: json['closing'] as String? ?? '',
    prepSeconds: (json['prep_seconds'] as num?)?.toInt() ?? 60,
    talkSeconds: (json['talk_seconds'] as num?)?.toInt() ?? 120,
  );
}

/// One question answered badly and then well, with the difference named.
///
/// Never a single model answer. Learners memorise those, examiners are trained
/// to spot memorised answers and mark them down, and a coach that teaches a
/// habit which loses marks is worse than one that teaches nothing. Two answers
/// side by side cannot be memorised — which one? — while showing exactly what
/// separates them.
class WorkedAnswer {
  const WorkedAnswer({
    required this.question,
    required this.weak,
    required this.strong,
    required this.moves,
  });

  final String question;
  final String weak;
  final String strong;

  /// What actually changed. Without this the pair is two paragraphs and the
  /// reader is left guessing.
  final List<String> moves;

  factory WorkedAnswer.fromJson(Map<String, dynamic> json) => WorkedAnswer(
    question: json['question'] as String? ?? '',
    weak: json['weak'] as String? ?? '',
    strong: json['strong'] as String? ?? '',
    moves: ((json['moves'] as List?) ?? const [])
        .map((m) => m as String)
        .toList(),
  );
}

class QuestionTopic {
  const QuestionTopic({
    required this.id,
    required this.title,
    required this.questions,
    this.cueCard,
    this.followsTitle,
    this.worked,
    this.hasWorked = false,
    this.isNew = false,
  });

  /// Stable, and the whole basis of the live feature: two learners can only
  /// discuss the same question if both clients can be pointed at one address.
  final String id;
  final String title;
  final List<String> questions;

  /// Present for Part 2 only. Both shapes travel the same browse path; only
  /// the last screen differs.
  final CueCard? cueCard;

  /// Part 3 only: the Part 2 card this discussion grows out of.
  ///
  /// Worth showing. In the exam the examiner takes what you just described and
  /// widens it, and a learner who meets these questions as a standalone list
  /// never sees that move — which is the part that catches people out.
  final String? followsTitle;

  /// Null when the learner's tier may not read it — see [hasWorked].
  final WorkedAnswer? worked;

  /// True when one exists, whether or not this learner may open it.
  ///
  /// Advertised while locked on purpose: a paid feature nobody knows about
  /// sells nothing, and one that is simply missing reads as a bug the moment a
  /// friend mentions having it.
  final bool hasWorked;
  final bool isNew;

  int get questionCount => questions.length;
  bool get isCueCard => cueCard != null;

  factory QuestionTopic.fromJson(Map<String, dynamic> json) => QuestionTopic(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    questions: ((json['questions'] as List?) ?? const [])
        .map((q) => q as String)
        .toList(),
    cueCard: json['cue_card'] == null
        ? null
        : CueCard.fromJson(json['cue_card'] as Map<String, dynamic>),
    followsTitle: json['follows_title'] as String?,
    worked: json['worked'] == null
        ? null
        : WorkedAnswer.fromJson(json['worked'] as Map<String, dynamic>),
    hasWorked: json['has_worked'] as bool? ?? false,
    isNew: json['is_new'] as bool? ?? false,
  );
}

class QuestionPart {
  const QuestionPart({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.topics,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<QuestionTopic> topics;

  int get topicCount => topics.length;

  factory QuestionPart.fromJson(Map<String, dynamic> json) => QuestionPart(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    topics: ((json['topics'] as List?) ?? const [])
        .map((t) => QuestionTopic.fromJson(t as Map<String, dynamic>))
        .toList(),
  );
}
