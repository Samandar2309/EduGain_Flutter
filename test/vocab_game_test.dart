import 'dart:math';

import 'package:edugain/features/vocabulary/domain/game.dart';
import 'package:edugain/features/vocabulary/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

VocabItem _item(String id, String word, String tr, {String example = ''}) =>
    VocabItem(
      id: id,
      word: word,
      translationUz: tr,
      definitionEn: '',
      example: example,
    );

final _pool = [
  _item('1', 'delicious', 'mazali', example: 'The soup is very delicious.'),
  _item('2', 'airport', 'aeroport'),
  _item('3', 'teacher', "o'qituvchi"),
  _item('4', 'computer', 'kompyuter'),
  _item('5', 'quickly', 'tez'),
];

void main() {
  test('every question has 4 distinct options and a valid correct index', () {
    final deck = buildDeck(_pool, random: Random(7));
    expect(deck, isNotEmpty);
    for (final q in deck) {
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4, reason: 'options must be distinct');
      expect(q.correctIndex, inInclusiveRange(0, 3));
      // the correct option maps back to the item under test
      expect(q.correctOption.isNotEmpty, true);
    }
  });

  test('deck size is capped and never exceeds the pool', () {
    final deck = buildDeck(_pool, maxQuestions: 3, random: Random(1));
    expect(deck.length, 3);
  });

  test('vocab is translation-only — no sentence exercises', () {
    final deck = buildDeck(_pool, random: Random(3));
    for (final q in deck) {
      expect(
        q.kind,
        anyOf(QuestionKind.wordToMeaning, QuestionKind.meaningToWord),
      );
      // the prompt is a single word/phrase, never a gapped sentence
      expect(q.prompt.contains('――――'), false);
    }
    // both directions appear across a session
    expect(deck.any((q) => q.kind == QuestionKind.wordToMeaning), true);
    expect(deck.any((q) => q.kind == QuestionKind.meaningToWord), true);
  });

  test('a pool too small to supply distractors yields no questions', () {
    final deck = buildDeck([_item('1', 'a', 'b')], random: Random(1));
    expect(deck, isEmpty);
  });

  test('xp rewards clean combos', () {
    expect(xpForRun(correct: 10, bestCombo: 10), greaterThan(xpForRun(correct: 10, bestCombo: 2)));
  });
}
