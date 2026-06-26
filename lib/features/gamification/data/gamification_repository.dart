import '../../../core/api/api_client.dart';
import '../domain/models.dart';

class GamificationRepository {
  GamificationRepository(this._api);

  final ApiClient _api;

  Future<GamificationProfile> profile() async {
    final data = await _api.get('/gamification/profile');
    return GamificationProfile.fromJson(data);
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
