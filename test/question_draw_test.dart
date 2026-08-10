import 'package:edugain/features/questions/application/providers.dart';
import 'package:edugain/features/questions/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drawing a random question.
///
/// The one promise this makes is that a question you have already answered does
/// not come back, and it is the kind of promise that is easy to break by
/// accident and hard to notice: a repeat looks like bad luck, not like a bug,
/// until it happens for the third time in one call.
QuestionPart _part(String id, String title, List<String> questions,
        {CueCard? card}) =>
    QuestionPart(
      id: id,
      title: title,
      subtitle: '',
      topics: [
        QuestionTopic(id: '$id-t', title: 'Topic', questions: questions,
            cueCard: card),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every question is drawn exactly once before any repeats', () {
    final parts = [
      _part('p1', 'Part 1', ['a', 'b', 'c']),
      _part('p3', 'Part 3', ['d', 'e']),
    ];
    final seen = SeenQuestions();

    final drawn = <String>[];
    for (var i = 0; i < 5; i++) {
      drawn.add(seen.draw(parts, onWrap: () => false)!.text);
    }

    expect(drawn.toSet().length, 5, reason: 'a question repeated early');
    expect(drawn.toSet(), {'a', 'b', 'c', 'd', 'e'});
  });

  test('the bank starts over rather than dead-ending', () {
    final parts = [_part('p1', 'Part 1', ['only'])];
    final seen = SeenQuestions();

    expect(seen.draw(parts, onWrap: () => false)!.text, 'only');

    var wrapped = false;
    // A button that stops working is worse than one that repeats after the
    // whole bank is done — but the caller has to be told, so it can say so.
    final again = seen.draw(parts, onWrap: () => wrapped = true);
    expect(again!.text, 'only');
    expect(wrapped, isTrue);
  });

  test('a Part 2 cue card is drawable, or Part 2 never comes up', () {
    final parts = [
      _part('p2', 'Part 2', const [],
          card: const CueCard(
            prompt: 'Describe a place you like',
            bullets: ['where it is'],
            closing: 'and explain why',
            prepSeconds: 60,
            talkSeconds: 120,
          )),
    ];

    final picked = SeenQuestions().draw(parts, onWrap: () => false);
    expect(picked!.text, 'Describe a place you like');
    expect(picked.partTitle, 'Part 2');
  });

  test('the drawn question says which part it came from', () {
    final parts = [_part('p3', 'Part 3', ['why?'])];
    expect(SeenQuestions().draw(parts, onWrap: () => false)!.partTitle, 'Part 3');
  });

  test('an empty bank draws nothing instead of throwing', () {
    expect(SeenQuestions().draw(const [], onWrap: () => false), isNull);
    expect(
      SeenQuestions().draw([_part('p1', 'Part 1', const [])], onWrap: () => false),
      isNull,
    );
  });

  test('what was drawn is remembered across a restart', () async {
    final parts = [_part('p1', 'Part 1', ['a', 'b'])];
    final first = SeenQuestions();
    final one = first.draw(parts, onWrap: () => false)!.text;
    // Let the write land before the "restart" reads it back.
    await Future<void>.delayed(Duration.zero);

    final afterRestart = SeenQuestions();
    await Future<void>.delayed(Duration.zero);
    final two = afterRestart.draw(parts, onWrap: () => false)!.text;

    expect(two, isNot(one), reason: 'a restart handed back an answered question');
  });
}
