import 'dart:math';

import 'models.dart';

/// The vocabulary game engine — pure Dart, no I/O, so it's fully testable.
/// It turns a pool of [VocabItem]s into a shuffled deck of tap-only questions
/// (no keyboard, ever) and scores answers. The same deck drives both solo play
/// and the bot duel (the widget layer only differs in whether an opponent bar
/// is racing alongside).

enum GameMode {
  /// Play alone, at your own pace.
  solo,

  /// Race a calibrated bot ("Gainsy").
  duel,

  /// Race another real learner over the network.
  online,
}

enum QuestionKind {
  /// See the English word → tap its Uzbek meaning.
  wordToMeaning,

  /// See the Uzbek meaning → tap the English word.
  meaningToWord,
}

class GameQuestion {
  const GameQuestion({
    required this.itemId,
    required this.kind,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String itemId;
  final QuestionKind kind;

  /// The English word or the Uzbek meaning — depending on [kind].
  final String prompt;
  final List<String> options;
  final int correctIndex;

  String get correctOption => options[correctIndex];

  /// The English word this question is about — for pronunciation. It's the
  /// prompt when translating from the word, otherwise the correct option.
  String get englishWord =>
      kind == QuestionKind.wordToMeaning ? prompt : correctOption;

  /// Wire format for the online duel — the host builds the deck and ships it to
  /// the guest so both race the exact same questions.
  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'kind': kind.index,
    'prompt': prompt,
    'options': options,
    'correctIndex': correctIndex,
  };

  factory GameQuestion.fromJson(Map<String, dynamic> j) => GameQuestion(
    itemId: j['itemId'] as String,
    kind: QuestionKind.values[j['kind'] as int],
    prompt: j['prompt'] as String,
    options: List<String>.from(j['options'] as List),
    correctIndex: j['correctIndex'] as int,
  );
}

/// Builds a game deck from [items]. Vocabulary is *only* word↔translation
/// recall — no sentence exercises (gap-fill sentences belong to Grammar). Each
/// item becomes one question, alternating the two directions so a session
/// drills both recognition and production of the meaning. Distractors are drawn
/// from the other items in the pool (same set = plausible, same CEFR/topic).
List<GameQuestion> buildDeck(
  List<VocabItem> items, {
  int maxQuestions = 12,
  Random? random,
}) {
  final rng = random ?? Random();
  final pool = items.where((i) => i.word.trim().isNotEmpty).toList();
  if (pool.length < 2) return const [];

  final chosen = [...pool]..shuffle(rng);
  final deck = <GameQuestion>[];
  var rotation = 0;
  for (final item in chosen.take(maxQuestions)) {
    // Alternate direction; fall back to the other if one can't build options.
    final kinds = rotation.isEven
        ? [QuestionKind.wordToMeaning, QuestionKind.meaningToWord]
        : [QuestionKind.meaningToWord, QuestionKind.wordToMeaning];
    GameQuestion? q;
    for (final kind in kinds) {
      q = _buildQuestion(kind, item, pool, rng);
      if (q != null) break;
    }
    if (q != null) {
      deck.add(q);
      rotation++;
    }
  }
  return deck;
}

GameQuestion? _buildQuestion(
  QuestionKind kind,
  VocabItem item,
  List<VocabItem> pool,
  Random rng,
) {
  switch (kind) {
    case QuestionKind.wordToMeaning:
      final options = _optionsFrom(
        correct: item.translationUz,
        pool: pool,
        pick: (i) => i.translationUz,
        exclude: item.id,
        rng: rng,
      );
      if (options == null) return null;
      return GameQuestion(
        itemId: item.id,
        kind: kind,
        prompt: item.word,
        options: options.$1,
        correctIndex: options.$2,
      );
    case QuestionKind.meaningToWord:
      final options = _optionsFrom(
        correct: item.word,
        pool: pool,
        pick: (i) => i.word,
        exclude: item.id,
        rng: rng,
      );
      if (options == null) return null;
      return GameQuestion(
        itemId: item.id,
        kind: kind,
        prompt: item.translationUz,
        options: options.$1,
        correctIndex: options.$2,
      );
  }
}

/// Four distinct options (correct + 3 distractors) with the correct index.
/// Returns null when the pool can't supply 3 distinct distractors.
(List<String>, int)? _optionsFrom({
  required String correct,
  required List<VocabItem> pool,
  required String Function(VocabItem) pick,
  required String exclude,
  required Random rng,
}) {
  final seen = <String>{correct.toLowerCase()};
  final distractors = <String>[];
  final candidates = pool.where((i) => i.id != exclude).toList()..shuffle(rng);
  for (final c in candidates) {
    final v = pick(c).trim();
    if (v.isEmpty || seen.contains(v.toLowerCase())) continue;
    seen.add(v.toLowerCase());
    distractors.add(v);
    if (distractors.length == 3) break;
  }
  if (distractors.length < 3) return null;
  final options = [correct, ...distractors]..shuffle(rng);
  return (options, options.indexOf(correct));
}

/// The outcome of one completed game, ready for the results screen and the
/// backend submit (per-item correctness → SRS + XP).
class GameResult {
  const GameResult({
    required this.mode,
    required this.total,
    required this.correct,
    required this.bestCombo,
    required this.xpEarned,
    required this.itemResults,
    this.youWon,
    this.opponentCorrect,
  });

  final GameMode mode;
  final int total;
  final int correct;
  final int bestCombo;
  final int xpEarned;

  /// Per-item correctness for `record_vocab_progress` (drives the SRS box).
  final List<({String itemId, bool correct})> itemResults;

  /// Duel only.
  final bool? youWon;
  final int? opponentCorrect;

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// XP model: base per correct + a combo kicker, so a clean streak is rewarded
/// more than the same score with misses scattered through it.
int xpForRun({required int correct, required int bestCombo}) =>
    correct * 4 + (bestCombo >= 5 ? 10 : 0) + (bestCombo >= 10 ? 15 : 0);

/// What the router hands the game screen: the word pool, the mode, a title for
/// the app bar, and the set id used to submit progress (null → a cross-set
/// review, submitted to the review endpoint instead).
class VocabGameLaunch {
  const VocabGameLaunch({
    required this.items,
    required this.mode,
    required this.title,
    this.setId,
  });

  final List<VocabItem> items;
  final GameMode mode;
  final String title;
  final String? setId;
}
