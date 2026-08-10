import '../../../core/api/api_client.dart';
import '../domain/models.dart';

/// Reads the question bank.
///
/// One request for the whole thing: it is a few kilobytes, and a round trip
/// per topic would put a spinner between a learner and the questions they are
/// about to read out loud.
class QuestionRepository {
  QuestionRepository(this._api);

  final ApiClient _api;

  Future<List<QuestionPart>> bank() async {
    // `ApiClient` already unwraps the `{"data": ...}` envelope, so this reads
    // `parts` at the top level. Reaching for `data['data']` here — as this
    // once did — throws on a perfectly good 200 and surfaces as "could not
    // load the questions", which points at the server and is entirely a
    // client-side mistake.
    final data = await _api.get('/speaking/questions');
    final parts = data['parts'] as List?;
    return (parts ?? const [])
        .map((p) => QuestionPart.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
