import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the learner is told about the sentence they just said.
///
/// The panel answers three questions, and each one is optional because the
/// model answers honestly: a sentence that was already correct has no
/// correction, and one that was correct but stiff has a better version and
/// nothing to fix. Rendering an empty row would tell somebody a mistake was
/// found when none was — the opposite of the point.
void main() {
  Coaching make({
    String correction = '',
    String why = '',
    String natural = '',
  }) => Coaching(
    understood: '',
    hasErrors: correction.isNotEmpty,
    correction: correction,
    naturalVersion: natural,
    grammarPoint: '',
    why: why,
    vocabulary: const [],
    pronunciation: const [],
    errorTags: const [],
    emotion: 'neutral',
  );

  group('the model', () {
    test('reads why off the wire', () {
      final c = Coaching.fromJson(const {
        'correction': 'I went to the market.',
        'why': 'Kechagi ish uchun Past Simple kerak.',
      });
      expect(c.correction, 'I went to the market.');
      expect(c.why, 'Kechagi ish uchun Past Simple kerak.');
    });

    test('an older server without the field still parses', () {
      // The backend and the app do not deploy in the same instant.
      final c = Coaching.fromJson(const {'correction': 'I went.'});
      expect(c.why, '');
      expect(c.correction, 'I went.');
    });

    test('a correct sentence carries nothing to show', () {
      final c = Coaching.fromJson(const {'correction': '', 'why': ''});
      expect(c.correction, isEmpty);
      expect(c.hasErrors, isFalse);
    });
  });

  group('what gets shown', () {
    // The strip is private, so these assert the decision it makes rather than
    // reaching into the widget: nothing to say means nothing on screen.
    bool showsSomething(Coaching c) =>
        c.correction.trim().isNotEmpty || c.naturalVersion.trim().isNotEmpty;

    test('a correct, natural sentence shows nothing', () {
      expect(showsSomething(make()), isFalse);
    });

    test('a mistake shows', () {
      expect(showsSomething(make(correction: 'I went to the market.')), isTrue);
    });

    test('correct but stiff still shows', () {
      // "Correct" and "natural" are not the same thing, and the gap between
      // them is most of what fluency is.
      expect(showsSomething(make(natural: 'I popped to the shops.')), isTrue);
    });

    test('whitespace is not content', () {
      expect(showsSomething(make(correction: '   ')), isFalse);
    });
  });
}
