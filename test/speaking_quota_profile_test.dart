import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpeakingQuota', () {
    test('parses the /speaking/quota payload and derives the ring values', () {
      final q = SpeakingQuota.fromJson(const {
        'sessions_remaining': 3,
        'speaking': {
          'seconds_limit': 900, // 15 min tier
          'seconds_used': 130,
          'seconds_remaining': 770,
        },
      });
      expect(q.sessionsRemaining, 3);
      expect(q.secondsLimit, 900);
      expect(q.secondsRemaining, 770);
      expect(q.minutesLimit, 15);
      // Partial minutes round UP so the ring never lies "0 min" early.
      expect(q.minutesRemaining, 13);
      expect(q.isExhausted, isFalse);
      expect(q.remainingRatio, closeTo(770 / 900, 1e-9));
    });

    test('an exhausted budget is exhausted and never negative', () {
      final q = SpeakingQuota.fromJson(const {
        'sessions_remaining': 0,
        'speaking': {'seconds_limit': 300, 'seconds_used': 300},
      });
      expect(q.isExhausted, isTrue);
      expect(q.secondsRemaining, 0);
      expect(q.minutesRemaining, 0);
      expect(q.remainingRatio, 0);
    });

    test('missing fields fall back to zeros (fail-safe hide)', () {
      final q = SpeakingQuota.fromJson(const {});
      expect(q.secondsLimit, 0);
      expect(q.isExhausted, isFalse); // limit 0 → card hidden, not "exhausted"
    });
  });

  group('LearnerProfile', () {
    test('parses the full Communication Profile payload', () {
      final p = LearnerProfile.fromJson(const {
        'focus_tags': ['past_simple', 'articles'],
        'fluency': {
          'voiced_minutes': 12.4,
          'spoken_words': 1830,
          'words_per_minute': 112.5,
          'wpm_target': 140,
        },
        'abilities': {
          'grammar': {'current': 68.2, 'delta': 3.1, 'samples': 5},
          'overall': {'current': 71.0, 'delta': null, 'samples': 5},
        },
        'has_memory': true,
      });
      expect(p.focusTags, ['past_simple', 'articles']);
      expect(p.voicedMinutes, 12.4);
      expect(p.spokenWords, 1830);
      expect(p.wordsPerMinute, 112.5);
      expect(p.wpmTarget, 140);
      expect(p.abilities['grammar']!.current, 68.2);
      expect(p.abilities['grammar']!.delta, 3.1);
      expect(p.abilities['overall']!.delta, isNull);
      expect(p.hasMemory, isTrue);
      expect(p.isEmpty, isFalse);
    });

    test('honesty rule: unmeasured axes stay null, empty profile is empty', () {
      final p = LearnerProfile.fromJson(const {
        'focus_tags': [],
        'fluency': {
          'voiced_minutes': null,
          'spoken_words': 0,
          'words_per_minute': null, // under the 60s measurement floor
          'wpm_target': 140,
        },
        'abilities': null,
        'has_memory': false,
      });
      expect(p.wordsPerMinute, isNull);
      expect(p.voicedMinutes, isNull);
      expect(p.abilities, isEmpty);
      expect(p.isEmpty, isTrue);
    });
  });

  group('FeedbackReport score deltas', () {
    test('parses score_deltas when the previous session exists', () {
      final r = FeedbackReport.fromJson(const {
        'cefr_estimate': 'B1',
        'summary': 'ok',
        'scores': {
          'grammar': 70,
          'vocabulary': 65,
          'fluency': 60,
          'pronunciation': 55,
          'overall': 66,
        },
        'score_deltas': {'grammar': 7, 'overall': -2},
        'is_locked': false,
      });
      expect(r.scoreDeltas, {'grammar': 7, 'overall': -2});
    });

    test('missing score_deltas stays null (no arrows shown)', () {
      final r = FeedbackReport.fromJson(const {
        'cefr_estimate': null,
        'summary': '',
      });
      expect(r.scoreDeltas, isNull);
    });
  });
}
