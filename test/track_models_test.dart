import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackCatalog.fromJson', () {
    test('parses tracks, recommendation and per-track progress', () {
      final catalog = TrackCatalog.fromJson({
        'cefr_level': 'B1',
        'recommended_track': 'real_life',
        'recommended_lesson_key': 'real_life.coffee_shop',
        'tracks': [
          {
            'track': 'cefr',
            'title': 'CEFR Course',
            'subtitle': 'Level up',
            'icon': 'graduation',
            'backdrop': 'university',
            'lessons_total': 6,
            'lessons_done': 3,
            'is_recommended': false,
          },
          {
            'track': 'real_life',
            'title': 'Real Life Scenarios',
            'subtitle': 'Everyday',
            'icon': 'globe',
            'backdrop': 'airport',
            'lessons_total': 10,
            'lessons_done': 0,
            'is_recommended': true,
          },
        ],
      });

      expect(catalog.cefrLevel, 'B1');
      expect(catalog.recommendedTrack, 'real_life');
      expect(catalog.tracks, hasLength(2));
      expect(catalog.tracks.first.progress, closeTo(0.5, 1e-9));
      expect(catalog.tracks[1].isRecommended, isTrue);
    });

    test('tolerates a missing tracks list', () {
      final catalog = TrackCatalog.fromJson({});
      expect(catalog.tracks, isEmpty);
      expect(catalog.tracks, isA<List<TrackSummary>>());
    });
  });

  group('SpeakingHome.fromJson', () {
    test('parses continue, mission, recommended, tracks and summary', () {
      final home = SpeakingHome.fromJson({
        'cefr_level': 'B1',
        'continue_lesson': {
          'lesson_key': 'real_life.airport',
          'track': 'real_life',
          'track_title': 'Real Life Scenarios',
          'title': 'Airport',
          'subtitle': 'Check-in',
          'backdrop': 'airport',
          'cefr_min': 'A1',
          'cefr_max': 'C2',
          'difficulty': 'easy',
          'est_minutes': 5,
          'xp_reward': 20,
          'progress': 0.6,
          'is_completed': false,
          'last_opened': '2026-06-29T12:00:00+00:00',
        },
        'daily_mission': {
          'lesson_key': 'daily.topic',
          'title': 'Your dream trip',
          'subtitle': "Today's mission",
          'backdrop': 'daily',
          'difficulty': 'easy',
          'est_minutes': 6,
          'xp_reward': 20,
        },
        'recommended_track': 'real_life',
        'recommended_lesson': {
          'key': 'real_life.coffee_shop',
          'title': 'Coffee Shop',
          'subtitle': 'Order drinks',
          'backdrop': 'coffee',
          'cefr_min': 'A1',
          'cefr_max': 'C2',
          'difficulty': 'easy',
          'est_minutes': 5,
          'xp_reward': 20,
          'is_premium': false,
          'is_locked': false,
          'is_done': false,
        },
        'tracks': [
          {
            'track': 'real_life',
            'title': 'Real Life',
            'subtitle': 'x',
            'icon': 'globe',
            'backdrop': 'airport',
            'lessons_total': 10,
            'lessons_done': 2,
            'is_recommended': true,
          },
        ],
        'progress_summary': {'lessons_done': 2, 'lessons_total': 29},
      });

      expect(home.cefrLevel, 'B1');
      expect(home.continueLesson, isNotNull);
      expect(home.continueLesson!.lessonKey, 'real_life.airport');
      expect(home.continueLesson!.progress, closeTo(0.6, 1e-9));
      expect(home.continueLesson!.lastOpened, isNotNull);
      expect(home.dailyMission!.lessonKey, 'daily.topic');
      expect(home.recommendedLesson!.key, 'real_life.coffee_shop');
      expect(home.tracks, hasLength(1));
      expect(home.lessonsDone, 2);
      expect(home.lessonsTotal, 29);
    });

    test('handles an empty / first-time home', () {
      final home = SpeakingHome.fromJson({
        'cefr_level': 'A2',
        'continue_lesson': null,
        'daily_mission': null,
        'recommended_lesson': null,
        'tracks': [],
        'progress_summary': {'lessons_done': 0, 'lessons_total': 29},
      });
      expect(home.continueLesson, isNull);
      expect(home.dailyMission, isNull);
      expect(home.recommendedLesson, isNull);
      expect(home.tracks, isEmpty);
      expect(home.lessonsDone, 0);
    });
  });

  group('TrackDetail.fromJson', () {
    test('parses lessons with lock/done/premium flags', () {
      final detail = TrackDetail.fromJson({
        'track': 'ielts',
        'title': 'IELTS Speaking',
        'subtitle': 'All parts',
        'lessons': [
          {
            'key': 'ielts.part1',
            'title': 'Part 1',
            'subtitle': 'Intro',
            'backdrop': 'ielts',
            'cefr_min': 'B1',
            'cefr_max': 'C2',
            'is_premium': false,
            'is_locked': false,
            'is_done': true,
          },
          {
            'key': 'ielts.mock',
            'title': 'Mock Test',
            'subtitle': 'Full sim',
            'backdrop': 'ielts',
            'cefr_min': 'B2',
            'cefr_max': 'C2',
            'is_premium': true,
            'is_locked': true,
            'is_done': false,
          },
        ],
      });

      expect(detail.track, 'ielts');
      expect(detail.lessons, hasLength(2));
      expect(detail.lessons.first.isDone, isTrue);
      expect(detail.lessons[1].isLocked, isTrue);
      expect(detail.lessons[1].isPremium, isTrue);
    });
  });
}
