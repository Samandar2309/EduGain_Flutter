import 'models.dart';

/// The two grammar practice mechanics.
enum GrammarKind {
  /// "Bo'shliqni to'ldirish" — a sentence with a blank + tap the right form.
  fillBlank,

  /// "Gap tuzish" — arrange scrambled words into the correct sentence.
  reorder,
}

/// One practice item, parsed from the game payload (which — unlike the formal
/// exercise DTO — includes the answer + explanation for instant client grading).
class GrammarGameExercise {
  const GrammarGameExercise({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.explanation,
    this.options = const [],
    this.correctIndex = 0,
    this.correctWords = const [],
  });

  final String id;
  final GrammarKind kind;

  /// fillBlank: the sentence with a blank. reorder: the Uzbek translation.
  final String prompt;
  final String explanation;

  // fillBlank
  final List<String> options;
  final int correctIndex;

  // reorder
  final List<String> correctWords;

  String get correctOption =>
      (correctIndex >= 0 && correctIndex < options.length)
          ? options[correctIndex]
          : '';

  /// The English answer (for pronunciation): the chosen form's sentence isn't
  /// stored, so we speak the correct option (fill-blank) or the built sentence.
  String get spoken => kind == GrammarKind.reorder
      ? correctWords.join(' ')
      : prompt.replaceAll(RegExp(r'_{2,}|―+'), correctOption);

  /// Renderable = we can present it tap-only. fill-blank needs ≥2 options;
  /// reorder needs ≥2 words. (Free-text `fill_blank` exercises are skipped.)
  bool get renderable => kind == GrammarKind.fillBlank
      ? options.length >= 2 && correctIndex >= 0
      : correctWords.length >= 2;

  factory GrammarGameExercise.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'mcq';
    final answer = json['correct_answer'];
    final explanation = json['explanation'] as String? ?? '';
    if (type == 'reorder') {
      final words = (answer is List)
          ? answer.map((e) => e.toString()).toList()
          : <String>[];
      return GrammarGameExercise(
        id: json['id'] as String,
        kind: GrammarKind.reorder,
        prompt: json['prompt'] as String? ?? '',
        explanation: explanation,
        correctWords: words,
      );
    }
    // mcq / fill_blank with options
    final options =
        ((json['options'] as List?) ?? const []).map((e) => e.toString()).toList();
    final correct = answer?.toString() ?? '';
    return GrammarGameExercise(
      id: json['id'] as String,
      kind: GrammarKind.fillBlank,
      prompt: json['prompt'] as String? ?? '',
      explanation: explanation,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }
}

class GrammarLesson {
  const GrammarLesson({required this.topic, required this.exercises});

  final GrammarTopic topic;
  final List<GrammarGameExercise> exercises;

  List<GrammarGameExercise> get playable =>
      exercises.where((e) => e.renderable).toList();
}
