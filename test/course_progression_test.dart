import 'package:edugain/features/course/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Moving on when a unit is finished.
///
/// Reported from production: a topic with two exercises, both finished, and
/// the app kept handing back the second one. The path never advanced.
///
/// A finished unit has no `current` lesson — every lesson comes back `done` —
/// and the screen has to offer something. It used to fall back to the unit's
/// LAST lesson, which is work already behind the learner, and it did that
/// every time they returned. What the screen needs is to be able to tell
/// "carry on here" from "this unit is done", and then to be told what follows.

UnitDetail _unit({
  required List<LessonState> lessons,
  UnitLink? nextUnit,
  int mastery = 0,
}) => UnitDetail(
  id: 'u1',
  number: '1',
  title: 'There is / There are',
  grammar: 'there is',
  explanation: '',
  vocab: 'words',
  mastery: mastery,
  lessons: [
    for (var i = 0; i < lessons.length; i++)
      LessonRef(id: 'l$i', index: i, itemCount: 4, state: lessons[i]),
  ],
  nextUnit: nextUnit,
);

/// What the screen asks: the lesson to carry on with, or null when there is
/// none. Mirrors the one line in `unit_screen.dart` that produced the bug.
LessonRef? _carryOn(UnitDetail unit) =>
    unit.lessons.where((x) => x.state == LessonState.current).firstOrNull;

void main() {
  group('a finished unit', () {
    final finished = _unit(
      lessons: [LessonState.done, LessonState.done],
      mastery: 1,
      nextUnit: const UnitLink(id: 'u2', number: '2', title: 'Past Simple'),
    );

    test('offers no lesson to carry on with', () {
      // The bug in one assertion. `firstWhere(..., orElse: lessons.last)`
      // answered "the second exercise" here, forever.
      expect(_carryOn(finished), isNull);
      expect(finished.isFinished, isTrue);
    });

    test('never re-offers its own last lesson', () {
      expect(_carryOn(finished)?.id, isNot('l1'));
    });

    test('knows what comes after it', () {
      expect(finished.nextUnit!.id, 'u2');
      expect(finished.nextUnit!.title, 'Past Simple');
    });
  });

  group('a unit still being worked', () {
    final midway = _unit(lessons: [LessonState.done, LessonState.current]);

    test('carries on with the current lesson', () {
      expect(_carryOn(midway)!.id, 'l1');
      expect(midway.isFinished, isFalse);
    });

    test('is not offered a way to skip ahead', () {
      // Pointing at the next unit mid-way would walk a learner past work the
      // course has not given them yet. The server sends null here.
      expect(midway.nextUnit, isNull);
    });
  });

  group('the end of the course', () {
    test('a finished last unit points nowhere', () {
      final last = _unit(
        lessons: [LessonState.done, LessonState.done],
        mastery: 1,
      );
      expect(_carryOn(last), isNull);
      expect(last.nextUnit, isNull);
      // Nothing to carry on with AND nowhere to go: the screen shows no
      // button at all rather than one that leads back into finished work.
    });
  });

  group('the wire format', () {
    test('next_unit is read when the server sends it', () {
      final unit = UnitDetail.fromJson(const {
        'id': 'u1',
        'number': '1',
        'title': 'There is / There are',
        'next_unit': {'id': 'u2', 'number': '2', 'title': 'Past Simple'},
        'lessons': [
          {'id': 'l0', 'index': 0, 'item_count': 4, 'state': 'done'},
          {'id': 'l1', 'index': 1, 'item_count': 4, 'state': 'done'},
        ],
      });
      expect(unit.nextUnit!.id, 'u2');
      expect(unit.isFinished, isTrue);
    });

    test('an absent next_unit is null, not an invented unit', () {
      // An older server, or the end of the course. A button offering somewhere
      // to go has to lead somewhere real.
      final unit = UnitDetail.fromJson(const {
        'id': 'u1',
        'lessons': [
          {'id': 'l0', 'index': 0, 'item_count': 4, 'state': 'current'},
        ],
      });
      expect(unit.nextUnit, isNull);
    });

    test('a unit with no lessons is not "finished"', () {
      // Empty content must not read as an accomplishment, and must not offer
      // a lesson that does not exist.
      final unit = UnitDetail.fromJson(const {'id': 'u1', 'lessons': []});
      expect(unit.isFinished, isFalse);
      expect(_carryOn(unit), isNull);
    });
  });
}
