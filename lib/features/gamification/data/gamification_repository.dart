import '../../../core/api/api_client.dart';
import '../domain/leaderboard.dart';
import '../domain/models.dart';

class GamificationRepository {
  GamificationRepository(this._api);

  final ApiClient _api;

  Future<GamificationProfile> profile() async {
    final data = await _api.get('/gamification/profile');
    return GamificationProfile.fromJson(data);
  }

  /// This week's standings, or last week's with [previous].
  ///
  /// `ApiClient` already unwraps the `data` envelope — unwrapping it a second
  /// time here is how the question bank silently broke on a 200 response.
  Future<Leaderboard> leaderboard({bool previous = false}) async {
    final data = await _api.get(
      '/gamification/leaderboard${previous ? '?week=previous' : ''}',
    );
    return Leaderboard.fromJson(data);
  }

  Future<List<XpEvent>> xpHistory() async {
    final data = await _api.get('/gamification/xp-history');
    final items = (data['items'] as List?) ?? const [];
    return items.map((e) => XpEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> setDailyGoal(int targetXp) async {
    final data = await _api.put(
      '/gamification/daily-goal',
      body: {'target_xp': targetXp},
    );
    return (data['target_xp'] as num?)?.toInt() ?? targetXp;
  }
}
