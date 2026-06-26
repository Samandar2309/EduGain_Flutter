import 'package:edugain/features/grammar/domain/models.dart';
import 'package:edugain/features/vocabulary/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VocabItem parses backend shape', () {
    final item = VocabItem.fromJson(const {
      'id': 'i-1',
      'word': 'apple',
      'translation_uz': 'olma',
      'definition_en': 'a fruit',
      'example': 'I ate an apple.',
    });
    expect(item.word, 'apple');
    expect(item.translationUz, 'olma');
  });

  test('GrammarExercise hides correct answer and parses options', () {
    final json = const {
      'id': 'e-1',
      'type': 'mcq',
      'prompt': 'I ___ a teacher.',
      'options': ['am', 'is', 'are'],
    };
    final ex = GrammarExercise.fromJson(json);
    expect(ex.isMcq, isTrue);
    expect(ex.options, ['am', 'is', 'are']);
    expect(json.containsKey('correct_answer'), isFalse);
  });

  test('CheckResult parses score and per-exercise results', () {
    final result = CheckResult.fromJson(const {
      'score': 1,
      'total': 2,
      'results': [
        {'exercise_id': 'e-1', 'correct': true, 'explanation': 'ok'},
        {'exercise_id': 'e-2', 'correct': false, 'explanation': 'no'},
      ],
    });
    expect(result.score, 1);
    expect(result.results.first.correct, isTrue);
    expect(result.results.last.explanation, 'no');
  });
}
