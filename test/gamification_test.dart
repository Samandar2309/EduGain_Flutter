import 'package:edugain/features/gamification/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GamificationProfile parses stats + daily goal', () {
    final p = GamificationProfile.fromJson(const {
      'xp': 120,
      'level': 2,
      'streak': 5,
      'daily_goal': {'target': 50, 'progress': 20},
    });
    expect(p.xp, 120);
    expect(p.level, 2);
    expect(p.dailyGoalTarget, 50);
    expect(p.goalRatio, closeTo(0.4, 0.001));
  });

  test('goalRatio is 0 when target is 0 and clamps at 1', () {
    expect(
      GamificationProfile.fromJson(const {'daily_goal': {'target': 0}}).goalRatio,
      0,
    );
    expect(
      GamificationProfile.fromJson(const {
        'daily_goal': {'target': 10, 'progress': 30},
      }).goalRatio,
      1,
    );
  });

  test('XpEvent parses source/amount', () {
    final e = XpEvent.fromJson(const {
      'source': 'speaking',
      'amount': 20,
      'created_at': '2026-06-20T10:00:00+00:00',
    });
    expect(e.source, 'speaking');
    expect(e.amount, 20);
  });
}
