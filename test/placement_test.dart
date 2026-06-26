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
}
