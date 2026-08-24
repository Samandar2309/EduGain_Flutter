import 'dart:convert';
import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../domain/models.dart';
import 'sse.dart';

/// Speaking use-cases over the §4.4 endpoints, including the SSE message stream.
class SpeakingRepository {
  SpeakingRepository(this._api);

  final ApiClient _api;

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
    String? freeTopic,
    String? lessonKey,
  }) async {
    final body = <String, dynamic>{};
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
  ///
  /// Passing [voice] asks the server to speak the reply as it writes it, so the
  /// audio arrives as [AudioEvent]s on this stream instead of costing a POST
  /// per sentence once the text is already here. Omit it and the reply comes
  /// back as text alone, exactly as before.
  ///
  /// [prerender] is the other half of that, for clients that cannot take audio
  /// on the stream: it asks the server to render each sentence into its cache
  /// while the model is still writing, so the /tts call this client makes a
  /// moment later is a cache hit rather than a two-second wait. The audio is
  /// identical — only the waiting moves.
  Stream<SpeakingEvent> streamReply(
    String sessionId,
    String text, {
    String? voice,
    String? prerender,
    String? requestId,
  }) async* {
    final raw = await _api.postStream(
      '/speaking/sessions/$sessionId/messages',
      body: {
        'text': text,
        if (voice != null) 'voice': voice,
        if (prerender != null) 'prerender': prerender,
      },
      requestId: requestId,
    );
    yield* _parseSse(raw);
  }

  /// Stream the AI reply for a spoken turn: upload the recorded clip, which the
  /// backend transcribes (Groq Whisper) and replies to. A leading
  /// [TranscriptEvent] carries what was heard; the rest mirrors [streamReply],
  /// [voice] included.
  Stream<SpeakingEvent> streamAudioReply(
    String sessionId,
    Uint8List audioBytes,
    String filename, {
    String? voice,
    String? prerender,
    void Function(int sent, int total)? onProgress,
    String? requestId,
  }) async* {
    final raw = await _api.postMultipartStream(
      '/speaking/sessions/$sessionId/messages/audio',
      bytes: audioBytes,
      filename: filename,
      fields: {
        if (voice != null) 'voice': voice,
        if (prerender != null) 'prerender': prerender,
      },
      onProgress: onProgress,
      requestId: requestId,
    );
    yield* _parseSse(raw);
  }

  /// Transcribe a clip ahead of the turn, during the detector's grace period.
  ///
  /// Starts no session, spends no turn and persists nothing — it only warms the
  /// transcript cache the real turn already consults, so the turn can skip
  /// transcription. Throws on any failure, which the caller reads as "send the
  /// recording the ordinary way".
  Future<void> transcribeAhead(Uint8List audioBytes, String filename) async {
    await _api.postMultipart(
      '/speaking/transcribe',
      bytes: audioBytes,
      filename: filename,
      field: 'audio',
    );
  }

  /// Report one turn's client-side timeline. Fire and forget, by contract.
  ///
  /// The metric this feature is being optimised against — silence to first
  /// audible reply — has both ends in the app, so the server cannot derive it.
  /// This is how its half reaches the same log stream, joined on the turn id
  /// that also travelled as `X-Request-ID`.
  ///
  /// Failures are swallowed at the call site. A turn that spoke correctly and
  /// then failed to report on itself was still a good turn, and a learner must
  /// never see anything because a measurement did not land.
  Future<void> reportTurnTiming({
    required String turnId,
    required String sessionId,
    required Map<String, Object?> record,
  }) async {
    await _api.post(
      '/speaking/telemetry/turn',
      body: {'turn_id': turnId, 'session_id': sessionId, 'record': record},
    );
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

  /// Mid-conversation help: translate the partner's last line ([kind] =
  /// `translate`) or suggest what to say back (`hint`), answered in [lang] —
  /// the language the learner runs the app in. Costs no turn and no speaking
  /// minutes.
  Future<String> assist({
    required String sessionId,
    required String kind,
    required String lang,
  }) async {
    final data = await _api.post(
      '/speaking/sessions/$sessionId/assist',
      body: {'kind': kind, 'lang': lang},
    );
    return (data['text'] as String?)?.trim() ?? '';
  }

  /// Past conversations, newest first. The data has always been there; until
  /// now nothing in the app asked for it, so a learner could never look back at
  /// what they had practised.
  Future<List<SpeakingSession>> history({int limit = 20}) async {
    // A list payload arrives wrapped as {items, meta} by the client envelope.
    final data = await _api.get('/speaking/history', query: {'limit': limit});
    final items = (data['items'] as List?) ?? const [];
    return items
        .map((e) => SpeakingSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// One conversation in full — the session plus every message. Used to reopen
  /// an interrupted session exactly where it stopped.
  Future<({SpeakingSession session, List<ChatMessage> messages})> getSession(
    String sessionId,
  ) async {
    final data = await _api.get('/speaking/sessions/$sessionId');
    final msgs = (data['messages'] as List? ?? const [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      session: SpeakingSession.fromJson(data['session'] as Map<String, dynamic>),
      messages: msgs,
    );
  }

  /// The report for a finished session, so a learner can re-read it later.
  Future<FeedbackReport> sessionFeedback(String sessionId) async {
    final data = await _api.get('/speaking/sessions/$sessionId/feedback');
    return FeedbackReport.fromJson(data['feedback'] as Map<String, dynamic>);
  }

  /// Close the session and get its report.
  ///
  /// Null means the session IS closed but the grading model was unavailable —
  /// never that the conversation was lost. Calling this again rebuilds the
  /// report, so the caller should offer that rather than discard the session.
  /// The correction for one turn, or null while it is still being written.
  ///
  /// Collected rather than pushed. The analysis is a second model call that
  /// writes several times more text than the reply it accompanies, so waiting
  /// for it used to delay the end of every turn — including for the learners
  /// who never looked at it. It finishes on its own now and waits here.
  ///
  /// Null covers both "not ready yet" and "there was nothing to say", and the
  /// caller treats them the same: show nothing. A correction that never
  /// arrives must never be visible as a failure — the learner already had
  /// their conversation.
  Future<Coaching?> coachingForTurn(String sessionId, int turnIndex) async {
    try {
      final data = await _api.get(
        '/speaking/sessions/$sessionId/coaching/$turnIndex',
      );
      if (data['ready'] != true) return null;
      final raw = data['coaching'];
      if (raw is! Map<String, dynamic>) return null;
      return Coaching.fromJson(raw);
    } catch (_) {
      // Never surfaced. See above.
      return null;
    }
  }

  Future<FeedbackReport?> endSession(String sessionId) async {
    // The server grades the whole conversation with a 70B model before it can
    // answer, so this one is allowed to take its time. Without that the call
    // was cut off at fifteen seconds and the learner was shown an internet
    // error while their report was being written -- see `ApiClient.slowCall`.
    final data = await _api.post(
      '/speaking/sessions/$sessionId/end',
      slow: true,
    );
    final feedback = data['feedback'];
    if (feedback == null) return null;
    return FeedbackReport.fromJson(feedback as Map<String, dynamic>);
  }

  /// Today's speaking budget — one cheap call that renders the minutes ring.
  Future<SpeakingQuota> quota() async {
    final data = await _api.get('/speaking/quota');
    return SpeakingQuota.fromJson(data);
  }

  /// The learner's Communication Profile (observed weak points + measured
  /// fluency + ability trends).
  Future<LearnerProfile> profile() async {
    final data = await _api.get('/speaking/profile');
    return LearnerProfile.fromJson(
      (data['profile'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
