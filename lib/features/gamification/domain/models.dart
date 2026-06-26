// Gamification models (contract §4.8).

class GamificationProfile {
  const GamificationProfile({
    required this.xp,
    required this.level,
    required this.streak,
    required this.dailyGoalTarget,
    required this.dailyGoalProgress,
  });

  final int xp;
  final int level;
  final int streak;
  final int dailyGoalTarget;
  final int dailyGoalProgress;

  double get goalRatio =>
      dailyGoalTarget == 0 ? 0 : (dailyGoalProgress / dailyGoalTarget).clamp(0, 1);

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    final goal = (json['daily_goal'] as Map?) ?? const {};
    return GamificationProfile(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      dailyGoalTarget: (goal['target'] as num?)?.toInt() ?? 0,
      dailyGoalProgress: (goal['progress'] as num?)?.toInt() ?? 0,
    );
  }
}

class XpEvent {
  const XpEvent({
    required this.source,
    required this.amount,
    required this.createdAt,
  });

  final String source;
  final int amount;
  final String createdAt;

  factory XpEvent.fromJson(Map<String, dynamic> json) => XpEvent(
    source: json['source'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] as String? ?? '',
  );
}
