import 'dart:convert';
import 'dart:typed_data';

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

  /// The whole Speaking home in one call: continue, daily mission, recommended
  /// lesson, the goal tracks (with progress) and an overall summary.
  Future<SpeakingHome> home() async {
    final data = await _api.get('/speaking/home');
    return SpeakingHome.fromJson(data);
  }

  /// The five goal tracks for the Speaking home, with progress + a
  /// placement-based recommendation.
  Future<TrackCatalog> listTracks() async {
    final data = await _api.get('/speaking/tracks');
    return TrackCatalog.fromJson(data);
  }

  /// The lessons inside one track, each with lock + done state.
  Future<TrackDetail> trackLessons(String track) async {
    final data = await _api.get('/speaking/tracks/$track');
    return TrackDetail.fromJson(data);
  }

  Future<StartedSession> startSession({
    String? scenarioId,
    String? freeTopic,
    String? lessonKey,
  }) async {
    final body = <String, dynamic>{};
    if (scenarioId != null) body['scenario_id'] = scenarioId;
    if (freeTopic != null) body['free_topic'] = freeTopic;
    if (lessonKey != null) body['lesson_key'] = lessonKey;
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
    yield* _parseSse(raw);
  }

  /// Stream the AI reply for a spoken turn: upload the recorded clip, which the
  /// backend transcribes (Groq Whisper) and replies to. A leading
  /// [TranscriptEvent] carries what was heard; the rest mirrors [streamReply].
  Stream<SpeakingEvent> streamAudioReply(
    String sessionId,
    String filePath,
    String filename,
  ) async* {
    final raw = await _api.postMultipartStream(
      '/speaking/sessions/$sessionId/messages/audio',
      filePath: filePath,
      filename: filename,
    );
    yield* _parseSse(raw);
  }

  /// Decode a raw SSE byte stream into [SpeakingEvent]s (`\n\n`-delimited blocks).
  Stream<SpeakingEvent> _parseSse(Stream<List<int>> raw) async* {
    var buffer = '';
    // `.cast<List<int>>()` is required: dio's stream is concretely
    // `Stream<Uint8List>`, and `Stream.transform` reifies that element type at
    // runtime — passing `utf8.decoder` (typed for `List<int>`) directly throws
    // a TypeError. The cast realigns the runtime element type.
    await for (final chunk in raw.cast<List<int>>().transform(utf8.decoder)) {
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

  /// The server-curated TTS voice catalogue (same on every device).
  Future<List<Voice>> listVoices() async {
    final data = await _api.get('/speaking/voices');
    final items = (data['items'] as List?) ?? const [];
    return items.map((e) => Voice.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Render one chunk of text to speech audio (wav bytes) in [voice].
  Future<Uint8List> synthesizeSpeech(String text, String voice) {
    return _api.postBytes(
      '/speaking/tts',
      body: {'text': text, 'voice': voice},
    );
  }

  Future<FeedbackReport> endSession(String sessionId) async {
    final data = await _api.post('/speaking/sessions/$sessionId/end');
    return FeedbackReport.fromJson(data['feedback'] as Map<String, dynamic>);
  }
}
