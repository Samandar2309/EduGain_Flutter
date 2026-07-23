import 'dart:math';

import 'package:edugain/features/vocabulary/domain/models.dart';
import 'package:edugain/features/vocabulary/domain/spell_game.dart';
import 'package:flutter_test/flutter_test.dart';

VocabItem _item(String id, String word, String tr) =>
    VocabItem(id: id, word: word, translationUz: tr, definitionEn: '', example: '');

void main() {
  final pool = [
    _item('1', 'delicious', 'mazali'),
    _item('2', 'airport', 'aeroport'),
    _item('3', 'teacher', "o'qituvchi"),
    _item('4', 'to', 'ga'), // too short → skipped
    _item('5', 'record player', 'plastinka'), // multi-word → skipped
    _item('6', 'extraordinarily', 'favqulodda'), // too long → skipped
  ];

  test('only spellable single words become challenges', () {
    final deck = buildSpellDeck(pool, random: Random(1));
    final words = deck.map((c) => c.word).toSet();
    expect(words, containsAll(['delicious', 'airport', 'teacher']));
    expect(words, isNot(contains('to')));
    expect(words.any((w) => w.contains(' ')), false);
    expect(words, isNot(contains('extraordinarily')));
  });

  test('letters are a shuffled permutation of the word, not the word itself', () {
    final deck = buildSpellDeck(pool, random: Random(3));
    for (final c in deck) {
      final sorted = [...c.letters]..sort();
      final wordSorted = c.word.split('')..sort();
      expect(sorted, wordSorted, reason: 'letters must be the word letters');
      if (c.word.length > 1) {
        expect(c.letters.join(), isNot(c.word),
            reason: 'a scramble should not spell the answer');
      }
      expect(c.meaning.isNotEmpty, true);
    }
  });

  test('deck size is capped', () {
    final deck = buildSpellDeck(pool, maxWords: 2, random: Random(1));
    expect(deck.length, 2);
  });
}
