import 'dart:math';

import 'models.dart';

/// "Harflardan yig'" (Spell it) — the productive-recall game. Unlike the MCQ
/// games (recognition: pick the answer among options), here the learner is
/// shown only the *meaning* and must reconstruct the English word from
/// scrambled letter tiles — recalling the word's form, tap-only, no keyboard.
/// This is the missing rung between passive recognition and active use.

class SpellChallenge {
  const SpellChallenge({
    required this.itemId,
    required this.word,
    required this.meaning,
    required this.letters,
  });

  final String itemId;

  /// The answer, lower-cased (comparison + tile source).
  final String word;

  /// The Uzbek meaning — the only prompt the learner sees.
  final String meaning;

  /// The word's letters, shuffled — the tile bank.
  final List<String> letters;
}

final _alpha = RegExp(r'^[a-zA-Z]+$');

/// Builds a spell deck from [items]: single alphabetic words of a spellable
/// length (3–11), each with its letters shuffled into a bank. Multi-word
/// entries and very long/short words are skipped (they don't tile well).
List<SpellChallenge> buildSpellDeck(
  List<VocabItem> items, {
  int maxWords = 10,
  Random? random,
}) {
  final rng = random ?? Random();
  final pool = items.where((i) {
    final w = i.word.trim();
    return _alpha.hasMatch(w) &&
        w.length >= 3 &&
        w.length <= 11 &&
        i.translationUz.trim().isNotEmpty;
  }).toList()
    ..shuffle(rng);

  return pool.take(maxWords).map((i) {
    final w = i.word.trim().toLowerCase();
    return SpellChallenge(
      itemId: i.id,
      word: w,
      meaning: i.translationUz.trim(),
      letters: _shuffledLetters(w, rng),
    );
  }).toList();
}

/// Shuffles a word's letters, retrying so the result isn't the word itself
/// (a scramble that spells the answer is no challenge and reads as a bug).
List<String> _shuffledLetters(String word, Random rng) {
  final letters = word.split('');
  if (letters.length <= 1) return letters;
  for (var attempt = 0; attempt < 6; attempt++) {
    letters.shuffle(rng);
    if (letters.join() != word) break;
  }
  return letters;
}
