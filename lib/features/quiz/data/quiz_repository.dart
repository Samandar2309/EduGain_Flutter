import '../../../core/api/api_client.dart';
import '../domain/models.dart';

/// Two calls, because the quiz needs exactly two things: what is live, and the
/// result of one tap.
///
/// There is no socket here on purpose. The client is told how many seconds are
/// left in the round, so it knows precisely when the next one begins and can
/// ask again on the boundary — about four requests a minute. A persistent
/// connection would buy nothing and would reintroduce the web-socket problems
/// this app already met inside the Telegram Mini App.
class QuizRepository {
  QuizRepository(this._api);

  final ApiClient _api;

  Future<QuizState> state() async =>
      QuizState.fromJson(await _api.get('/quiz/state'));

  /// Open a lobby. The server tells us whether this call is what opened it,
  /// which is what decides if everybody gets a nudge.
  Future<void> start() => _api.post('/quiz/start', body: const {});

  /// "I am here." Renewed by every poll afterwards.
  Future<void> ready({bool leave = false}) =>
      _api.post('/quiz/ready', body: {'leave': leave});

  /// The lobby summary alone, for the games hub.
  ///
  /// Deliberately not `state()`: asking for the full state marks the caller as
  /// playing, and a hub card that counted everyone reading the menu would be
  /// inflating the number rather than reporting it.
  Future<QuizLive> live() async =>
      QuizLive.fromJson(await _api.get('/quiz/live'));

  /// The match and index are sent back so the server can refuse an answer to a
  /// round that has already passed. It never takes our word for the timing —
  /// the score is computed from when the request actually arrived.
  Future<QuizVerdict> answer({
    required int match,
    required int index,
    required int choice,
  }) async {
    final data = await _api.post(
      '/quiz/answer',
      body: {'match': match, 'index': index, 'choice': choice},
    );
    return QuizVerdict.fromJson(data);
  }
}
