// Grammar domain models (contract §4.6). Exercises never include the correct
// answer — checking is server-side (REQ-07-008).

class GrammarTopic {
  const GrammarTopic({
    required this.id,
    required this.slug,
    required this.title,
    required this.cefrLevel,
    required this.isPremium,
    required this.isLocked,
    this.explanationMd = '',
  });

  final String id;
  final String slug;
  final String title;
  final String cefrLevel;
  final bool isPremium;
  final bool isLocked;
  final String explanationMd;

  factory GrammarTopic.fromJson(Map<String, dynamic> json) => GrammarTopic(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    cefrLevel: json['cefr_level'] as String? ?? '',
    isPremium: json['is_premium'] as bool? ?? false,
    isLocked: json['is_locked'] as bool? ?? false,
    explanationMd: json['explanation_md'] as String? ?? '',
  );
}

class GrammarExercise {
  const GrammarExercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String type; // fill_blank | mcq | reorder | transform
  final String prompt;
  final List<String> options;

  bool get isMcq => type == 'mcq';

  factory GrammarExercise.fromJson(Map<String, dynamic> json) => GrammarExercise(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'fill_blank',
    prompt: json['prompt'] as String? ?? '',
    options: ((json['options'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class GrammarTopicDetail {
  const GrammarTopicDetail({required this.topic, required this.exercises});
  final GrammarTopic topic;
  final List<GrammarExercise> exercises;
}

class ExerciseResult {
  const ExerciseResult({
    required this.exerciseId,
    required this.correct,
    required this.explanation,
  });

  final String exerciseId;
  final bool correct;
  final String explanation;

  factory ExerciseResult.fromJson(Map<String, dynamic> json) => ExerciseResult(
    exerciseId: json['exercise_id'] as String,
    correct: json['correct'] as bool? ?? false,
    explanation: json['explanation'] as String? ?? '',
  );
}

class CheckResult {
  const CheckResult({
    required this.score,
    required this.total,
    required this.results,
  });

  final int score;
  final int total;
  final List<ExerciseResult> results;

  factory CheckResult.fromJson(Map<String, dynamic> json) => CheckResult(
    score: (json['score'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    results: ((json['results'] as List?) ?? const [])
        .map((e) => ExerciseResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
