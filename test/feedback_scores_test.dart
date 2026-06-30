import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackReport scores', () {
    test('parses the scores block when present', () {
      final r = FeedbackReport.fromJson(const {
        'cefr_estimate': 'B1',
        'summary': 'Good.',
        'scores': {
          'grammar': 78,
          'vocabulary': 70,
          'fluency': 65,
          'pronunciation': 60,
          'overall': 72,
        },
        'errors': [],
        'strengths': [],
        'is_locked': false,
      });
      expect(r.scores, isNotNull);
      expect(r.scores!.overall, 72);
      expect(r.scores!.grammar, 78);
    });

    test('scores is null when omitted', () {
      final r = FeedbackReport.fromJson(const {
        'cefr_estimate': 'B1',
        'summary': 's',
      });
      expect(r.scores, isNull);
    });

    test('clamps out-of-range values', () {
      final s = FeedbackScores.fromJson(const {
        'grammar': 140,
        'vocabulary': -10,
        'overall': 50,
      });
      expect(s.grammar, 100);
      expect(s.vocabulary, 0);
      expect(s.overall, 50);
      expect(s.fluency, 0); // missing → 0
    });
  });
}
