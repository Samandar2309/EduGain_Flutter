import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../domain/models.dart';
import 'sse.dart';

/// Speaking use-cases over the §4.4 endpoints, including the SSE message stream.
class SpeakingRepository {
  SpeakingRepository(this._api);

  final ApiClient _api;

  Future<List<Scenario>> listScenarios() async {
    final data = await _api.get('/speaking/scenarios');
    final items = (data['items'] as List?) ?? const [];
    return items
        .map((e) => Scenario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StartedSession> startSession({
    String? scenarioId,
    String? freeTopic,
  }) async {
    final body = <String, dynamic>{};
    if (scenarioId != null) body['scenario_id'] = scenarioId;
    if (freeTopic != null) body['free_topic'] = freeTopic;
    final data = await _api.post('/speaking/sessions', body: body);
    return StartedSession(
      session: SpeakingSession.fromJson(data['session'] as Map<String, dynamic>),
      firstMessage: ChatMessage.fromJson(
        data['first_message'] as Map<String, dynamic>,
      ),
    );
  }

  /// Stream the AI reply turn-by-turn. Pre-stream errors (paywall, turn limit)
  /// surface as an [ApiException] from the first await (REQ-23-006).
  Stream<SpeakingEvent> streamReply(String sessionId, String text) async* {
    final raw = await _api.postStream(
      '/speaking/sessions/$sessionId/messages',
      body: {'text': text},
    );
    var buffer = '';
    await for (final chunk in raw.transform(utf8.decoder)) {
      buffer += chunk;
      var idx = buffer.indexOf('\n\n');
      while (idx != -1) {
        final block = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);
        final event = parseSseEvent(block);
        if (event != null) yield event;
        idx = buffer.indexOf('\n\n');
      }
    }
  }

  Future<FeedbackReport> endSession(String sessionId) async {
    final data = await _api.post('/speaking/sessions/$sessionId/end');
    return FeedbackReport.fromJson(data['feedback'] as Map<String, dynamic>);
  }
}
