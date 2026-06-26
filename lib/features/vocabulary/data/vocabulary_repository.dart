import '../../../core/api/api_client.dart';
import '../domain/models.dart';

class VocabularyRepository {
  VocabularyRepository(this._api);

  final ApiClient _api;

  Future<List<VocabSet>> listSets() async {
    final data = await _api.get('/vocabulary/sets');
    final sets = (data['sets'] as List?) ?? const [];
    return sets.map((e) => VocabSet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VocabSetDetail> getSet(String setId) async {
    final data = await _api.get('/vocabulary/sets/$setId');
    return VocabSetDetail(
      set: VocabSet.fromJson(data['set'] as Map<String, dynamic>),
      items: ((data['items'] as List?) ?? const [])
          .map((e) => VocabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Submit per-word recall results; returns how many were marked learned.
  Future<int> submitProgress(
    String setId,
    List<({String itemId, bool correct})> results,
  ) async {
    final data = await _api.post(
      '/vocabulary/sets/$setId/progress',
      body: {
        'item_results': [
          for (final r in results) {'item_id': r.itemId, 'correct': r.correct},
        ],
      },
    );
    return (data['learned'] as num?)?.toInt() ?? 0;
  }

  /// Words whose spaced-repetition review is due across all sets.
  Future<List<VocabItem>> fetchReview() async {
    final data = await _api.get('/vocabulary/review');
    return ((data['items'] as List?) ?? const [])
        .map((e) => VocabItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Submit recall results for a review session; returns (reviewed, correct).
  Future<({int reviewed, int correct})> submitReview(
    List<({String itemId, bool correct})> results,
  ) async {
    final data = await _api.post(
      '/vocabulary/review',
      body: {
        'item_results': [
          for (final r in results) {'item_id': r.itemId, 'correct': r.correct},
        ],
      },
    );
    return (
      reviewed: (data['reviewed'] as num?)?.toInt() ?? 0,
      correct: (data['correct'] as num?)?.toInt() ?? 0,
    );
  }
}
