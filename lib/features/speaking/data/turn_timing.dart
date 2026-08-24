import 'dart:math';

import 'package:flutter/foundation.dart';

/// Where one spoken turn's seconds actually go, measured on the client.
///
/// The server already records its own half of a turn, but the number the
/// learner experiences is not on the server at all: it starts when they stop
/// talking and ends when they hear an answer, and both ends are in the app.
/// Two optimisations have already been deployed on reasoning alone and
/// measured *slower*, so the point of this file is that the next one does not
/// have to be argued about.
///
/// **Monotonic, not wall clock.** Every mark is a millisecond offset from one
/// [Stopwatch] started at a single origin. Nothing here reads the wall clock,
/// so a phone that re-syncs its time mid-turn — or a WebView that suspends and
/// resumes — cannot produce a negative duration or a wild outlier.
///
/// **The origin is silence-onset, not the turn decision.** [begin] is called
/// when the voice detector first sees the learner go quiet, which is the moment
/// they actually stopped speaking. The two seconds the detector then waits
/// before committing the turn are part of what the learner feels, so they are
/// inside the measurement rather than in front of it.
///
/// **Best effort, always.** Every method swallows its own failures. A turn must
/// never break because a measurement did.
class TurnTimeline {
  TurnTimeline._(this.turnId, this.platform);

  /// A fresh timeline, not yet started. [begin] sets the origin.
  factory TurnTimeline.create() =>
      TurnTimeline._(_newTurnId(), _platformName());

  /// Correlation id for this turn, sent as `X-Request-ID` on the turn's HTTP
  /// requests. The server's request-context middleware already honours that
  /// header and binds it into every log line it writes, so client and server
  /// records join on this value with no second mechanism.
  final String turnId;

  /// `web`, `android`, `iOS`, … — the two paths through this feature differ
  /// enough that a mixed average would describe neither.
  final String platform;

  final Stopwatch _clock = Stopwatch();
  final Map<String, int> _marks = <String, int>{};

  /// Non-timing facts worth having beside the timings: how big the upload was,
  /// which codec it used, which callback reported the first audio.
  final Map<String, Object?> _facts = <String, Object?>{};

  bool get started => _clock.isRunning || _marks.isNotEmpty;

  /// Start (or restart) the clock at silence-onset.
  ///
  /// Restartable on purpose. A learner who pauses and then carries on has not
  /// finished their turn, and the detector's own silence counter resets — so
  /// this resets with it, and the origin ends up at the *last* time they
  /// stopped, which is the one the turn was actually built from.
  void begin() {
    try {
      _marks.clear();
      _facts.clear();
      _clock
        ..reset()
        ..start();
    } catch (_) {
      // A timeline that cannot start simply records nothing.
    }
  }

  /// Record [name] at the current offset, if the clock is running.
  ///
  /// First write wins: these mark the FIRST time something happened (the first
  /// chunk, the first sentence, the first audio), and a later repeat of the
  /// same event must not overwrite the moment that matters.
  void mark(String name) {
    try {
      if (!_clock.isRunning) return;
      _marks.putIfAbsent(name, () => _clock.elapsedMilliseconds);
    } catch (_) {
      // Never at the cost of the turn.
    }
  }

  /// Attach a non-timing fact (size, format, which callback fired).
  void note(String key, Object? value) {
    try {
      _facts[key] = value;
    } catch (_) {
      // As above.
    }
  }

  int? operator [](String name) => _marks[name];

  /// Whether this turn reached audible audio. A turn that failed, was retried
  /// or was abandoned must not be reported as if it had — see [toJson].
  bool get reachedAudio => _marks.containsKey(mFirstAudio);

  /// Stop the clock. Marks recorded after this are ignored, which is what keeps
  /// a cancelled turn from collecting a stray "first audio" from the next one.
  void end() {
    try {
      _clock.stop();
    } catch (_) {
      // Nothing to do.
    }
  }

  /// The record to ship. Timing keys are offsets in milliseconds from
  /// silence-onset; [outcome] says whether the turn got as far as speaking, so
  /// a failed turn's partial timings are never averaged in with complete ones.
  ///
  /// Deliberately carries no transcript, no reply text, no audio and no token
  /// counts — only durations, sizes, formats and the correlation id.
  Map<String, Object?> toJson() => <String, Object?>{
    'turn_id': turnId,
    'platform': platform,
    'outcome': reachedAudio ? 'spoke' : 'incomplete',
    ..._facts,
    ..._marks,
  };

  // ── mark names ────────────────────────────────────────────────────────────
  //
  // Named constants rather than bare strings: these are the column headers of
  // every latency report this project will produce, and a typo in one of them
  // is a silently missing stage rather than an error.

  /// The origin itself (always 0) — recorded so a reader can see it was set.
  static const String mSilenceStart = 'vad_silence_start_ms';

  /// The detector committed the turn. The gap to [mSilenceStart] is the
  /// deliberate grace period, currently a hardcoded two seconds.
  static const String mVadConfirmed = 'vad_confirmed_ms';

  /// `_stopAndSend` entered — the app has begun ending the turn.
  static const String mStopBegin = 'recorder_stop_start_ms';

  /// The browser's recorder reported `onstop` / the native recorder returned.
  ///
  /// Passed to `SpeechRecorder.stop`'s stage hook by name rather than spelled
  /// there as a literal. They were literals once, and they did not match these
  /// constants: the server's allowlist dropped both stages on arrival, so
  /// recorder-finalisation could not be measured at all and nothing said so.
  static const String mRecorderStopped = 'recorder_stopped_ms';

  /// The encoded bytes are one contiguous buffer — the end of finalisation.
  static const String mBytesReady = 'bytes_ready_ms';

  /// Encoded bytes are in hand and ready to upload.
  static const String mAudioReady = 'audio_ready_ms';

  /// The HTTP request for the turn was handed to the client.
  static const String mUploadStart = 'upload_start_ms';

  /// The first byte of the reply reached the app. On a transport that does not
  /// stream this is the WHOLE body, which is exactly what makes it worth
  /// measuring separately from [mFirstSentence].
  static const String mFirstChunk = 'first_client_chunk_ms';

  /// The transcript event arrived (audio turns only).
  static const String mTranscript = 'transcript_ms';

  /// A complete sentence was available to speak.
  static const String mFirstSentence = 'first_sentence_ms';

  /// The reply stream closed.
  static const String mStreamDone = 'stream_done_ms';

  /// Text was handed to the speech engine / player.
  static const String mTtsStart = 'tts_start_ms';

  /// Sound actually started. See `first_audio_source` for which callback said
  /// so — the browser reports true `onstart`; the native player reports the
  /// moment playback was invoked on a loaded clip, which is close but not the
  /// same claim.
  static const String mFirstAudio = 'first_audio_started_ms';
}

/// Randomised, not sequential: it is only required to be unique per turn, and a
/// counter would collide across app restarts on the same account.
String _newTurnId() {
  const digits = '0123456789abcdef';
  final rnd = Random();
  final buf = StringBuffer('t-');
  for (var i = 0; i < 24; i++) {
    buf.write(digits[rnd.nextInt(16)]);
  }
  return buf.toString();
}

String _platformName() {
  if (kIsWeb) return 'web';
  try {
    return defaultTargetPlatform.name;
  } catch (_) {
    return 'unknown';
  }
}
