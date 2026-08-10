import 'package:edugain/features/placement/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlacementQuestion parses without leaking the answer', () {
    final json = const {
      'id': 'q-1',
      'section': 'grammar',
      'cefr_level': 'A2',
      'type': 'mcq',
      'prompt': 'She ___ home.',
      'options': ['go', 'went', 'goes'],
    };
    final q = PlacementQuestion.fromJson(json);
    expect(q.isMcq, isTrue);
    expect(q.options.length, 3);
    expect(json.containsKey('correct_answer'), isFalse);
  });

  test('PlacementResult parses cefr + breakdown', () {
    final result = PlacementResult.fromJson(const {
      'result_cefr': 'B1',
      'breakdown': {
        'A2': {'correct': 2, 'total': 2, 'ratio': 1.0},
      },
    });
    expect(result.resultCefr, 'B1');
    expect(result.breakdown.containsKey('A2'), isTrue);
  });

  test('PlacementResult tolerates a null result', () {
    final result = PlacementResult.fromJson(const {'result_cefr': null});
    expect(result.resultCefr, isNull);
    expect(result.breakdown, isEmpty);
  });

  // ── the retake gate reads these ────────────────────────────────────────
  //
  // Whether a returning learner is shown their level or dropped into question
  // one turns entirely on `hasLevel` and `completedAt`. Both come off the wire
  // as loosely-typed JSON, so both are pinned here.

  test('a measured level carries the date it was measured', () {
    final result = PlacementResult.fromJson(const {
      'result_cefr': 'C1',
      'score': 14,
      'completed_at': '2026-07-20T09:30:00Z',
    });
    expect(result.hasLevel, isTrue);
    expect(result.score, 14);
    expect(result.completedAt?.toUtc().day, 20);
  });

  test('never taken is not the same as placed at the bottom', () {
    // The distinction the whole gate rests on: no level means "we have never
    // asked", and asking again is the point. Treating it as a low level would
    // show someone a result they never sat.
    expect(PlacementResult.fromJson(const {}).hasLevel, isFalse);
    expect(
      PlacementResult.fromJson(const {'result_cefr': null}).hasLevel,
      isFalse,
    );
    expect(PlacementResult.fromJson(const {'result_cefr': ''}).hasLevel, isFalse);
    expect(
      PlacementResult.fromJson(const {'result_cefr': 'A1'}).hasLevel,
      isTrue,
      reason: 'A1 is a real measured level, not the absence of one',
    );
  });

  test('a level with no date is still shown', () {
    // A fresh submission answers without `completed_at`. Losing the date is a
    // reason to omit one line, not to hide the result.
    final result = PlacementResult.fromJson(const {'result_cefr': 'B2'});
    expect(result.hasLevel, isTrue);
    expect(result.completedAt, isNull);
  });

  test('an unparseable date does not take the level down with it', () {
    final result = PlacementResult.fromJson(const {
      'result_cefr': 'B1',
      'completed_at': 'not-a-date',
    });
    expect(result.hasLevel, isTrue);
    expect(result.completedAt, isNull);
  });
}
