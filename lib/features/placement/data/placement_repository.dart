import '../../../core/api/api_client.dart';
import '../domain/models.dart';

class PlacementRepository {
  PlacementRepository(this._api);

  final ApiClient _api;

  Future<List<PlacementQuestion>> getTest() async {
    final data = await _api.get('/placement/test');
    final questions = (data['questions'] as List?) ?? const [];
    return questions
        .map((e) => PlacementQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlacementResult> submit(
    List<({String questionId, Object answer})> answers,
  ) async {
    final data = await _api.post(
      '/users/me/placement',
      body: {
        'answers': [
          for (final a in answers)
            {'question_id': a.questionId, 'answer': a.answer},
        ],
      },
    );
    return PlacementResult.fromJson(data);
  }

  Future<PlacementResult> latestResult() async {
    final data = await _api.get('/placement/result');
    return PlacementResult.fromJson(data);
  }
}
