import '../../../core/api/api_client.dart';
import '../domain/grammar_game.dart';
import '../domain/models.dart';

class GrammarRepository {
  GrammarRepository(this._api);

  final ApiClient _api;

  Future<List<GrammarTopic>> listTopics() async {
    final data = await _api.get('/grammar/topics');
    final topics = (data['topics'] as List?) ?? const [];
    return topics
        .map((e) => GrammarTopic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Practice-game payload: exercises WITH answers + explanations for instant
  /// client-side grading (the "why").
  Future<GrammarLesson> getGame(String topicId) async {
    final data = await _api.get('/grammar/topics/$topicId/game');
    return GrammarLesson(
      topic: GrammarTopic.fromJson(data['topic'] as Map<String, dynamic>),
      exercises: ((data['exercises'] as List?) ?? const [])
          .map((e) => GrammarGameExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Record a finished practice run (client already graded) → XP + progress.
  Future<void> recordPractice(
    String topicId,
    List<({String exerciseId, bool correct})> results,
  ) async {
    await _api.post(
      '/grammar/topics/$topicId/record',
      body: {
        'results': [
          for (final r in results)
            {'exercise_id': r.exerciseId, 'correct': r.correct},
        ],
      },
    );
  }

  Future<GrammarTopicDetail> getTopic(String topicId) async {
    final data = await _api.get('/grammar/topics/$topicId');
    return GrammarTopicDetail(
      topic: GrammarTopic.fromJson(data['topic'] as Map<String, dynamic>),
      exercises: ((data['exercises'] as List?) ?? const [])
          .map((e) => GrammarExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<CheckResult> check(
    String topicId,
    List<({String exerciseId, Object answer})> answers,
  ) async {
    final data = await _api.post(
      '/grammar/topics/$topicId/check',
      body: {
        'answers': [
          for (final a in answers)
            {'exercise_id': a.exerciseId, 'answer': a.answer},
        ],
      },
    );
    return CheckResult.fromJson(data);
  }
}
