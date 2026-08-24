import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

export 'upload_codec.dart';

import 'turn_timing.dart';

/// Recording the microphone as Opus, using the browser's own encoder.
///
/// The upload is the largest single part of a spoken turn. Web records
/// PCM16 at 16 kHz and wraps it in WAV — 32 KB per second, so a seventeen
/// second answer is 550 KB and takes about five seconds to send on a weak
/// mobile uplink. That is more than the transcription, the model and the
/// speech synthesis put together.
///
/// Opus at 24 kbps is 3 KB per second. The same answer becomes 45 KB.
///
/// **Why not the `record` package.** Its file mode would give Opus, but
/// `getUserMedia` lives inside the call that starts it — so recording per turn
/// would ask for the microphone per turn. That is the trap the streaming path
/// in `audio_recorder.dart` exists to avoid.
///
/// **Why asking for the microphone here is free.** Permission has already been
/// granted by the time a turn is recorded — the mic gate does that from the
/// learner's own tap, before the call begins. A second `getUserMedia` with the
/// permission already held resolves silently, with no dialog.
///
/// Every entry point is guarded: an unsupported browser, a refused stream or a
/// recorder that produces nothing all return null, and the caller keeps its
/// existing WAV path. The worst case is today's behaviour.
@JS('navigator.mediaDevices.getUserMedia')
external JSPromise<JSObject> _getUserMedia(JSObject constraints);

@JS('MediaRecorder')
external JSFunction? get _mediaRecorderCtor;

/// Bound to the real `MediaRecorder`, and the annotation is load-bearing.
///
/// Without it the STATIC members resolve against a global named
/// `_JSMediaRecorder`, which does not exist — so `isTypeSupported` threw for
/// every container it was asked about, the picker concluded the browser could
/// record none of them, and every turn fell back to WAV. Silently, because
/// falling back is the designed behaviour.
///
/// It was invisible from the outside and unmistakable from the telemetry:
/// desktop Chrome reported `no_mime_of_8`, and desktop Chrome has recorded
/// `audio/webm;codecs=opus` for a decade. That is not a browser saying no,
/// that is the question never reaching it — and it meant a phone uploaded 400
/// KB where 12 KB would have done, for the whole life of this file.
///
/// Instance members do not need this (they are property accesses on an object
/// that already exists), which is why everything else here worked and made the
/// failure look like a device limitation.
@JS('MediaRecorder')
extension type _JSMediaRecorder._(JSObject _) implements JSObject {
  external factory _JSMediaRecorder(JSObject stream, JSObject options);
  external static bool isTypeSupported(String type);
  external void start();
  external void stop();

  /// Flush what has been encoded so far WITHOUT ending the recording.
  ///
  /// The one API that makes speculative transcription possible. `stop()` would
  /// also hand over the audio, but it ends the capture — and a learner who was
  /// only pausing would find the microphone rebuilt underneath them, which is
  /// the cost that turned a ten second turn into forty-seven once already.
  ///
  /// The blob it produces arrives through the same `ondataavailable` as every
  /// other chunk, so the recording continues to accumulate normally and the
  /// final clip is still the concatenation of everything.
  external void requestData();
  external String get state;
  external set ondataavailable(JSFunction f);
  external set onstop(JSFunction f);
}

extension type _JSBlobEvent._(JSObject _) implements JSObject {
  external JSObject? get data;
}

extension type _JSBlob._(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
  external int get size;
}

extension type _JSMediaStream._(JSObject _) implements JSObject {
  external JSArray<JSObject> getTracks();
}

extension type _JSTrack._(JSObject _) implements JSObject {
  external void stop();

  /// "live" or "ended". A track the browser reclaimed stays in `getTracks()`
  /// forever — it just stops carrying sound — so its presence says nothing
  /// about whether the microphone still works.
  external String get readyState;
}

/// The container the browser will actually produce, or null if none of them.
///
/// WebM first because it is what Chrome and the Android WebView emit, which is
/// every learner we have. MP4 is Safari's, and is checked so an iPhone is not
/// silently left on the WAV path.
/// Every container this app can usefully record into, best first.
///
/// The list was three entries and a real Android WebView supported none of
/// them — so every turn went up as a 97 KB WAV instead of an 11 KB Opus, and
/// on a phone uplink that is most of a second, every time.
///
/// Ordered by what the transcriber gets back for the bytes: Opus in WebM is
/// the smallest, Opus in Ogg the same codec in the container some engines
/// prefer, AAC/MP4 next, and MPEG last because it is the biggest of the four.
const _mimeCandidates = <String>[
  'audio/webm;codecs=opus',
  'audio/ogg;codecs=opus',
  'audio/webm',
  'audio/ogg',
  'audio/mp4;codecs=mp4a.40.2',
  'audio/mp4',
  'audio/aac',
  'audio/mpeg',
];

/// Why no container could be used, or "" when one was. Read by telemetry: a
/// silent fallback to WAV is right for the learner and useless for whoever
/// has to explain the upload size afterwards.
String lastCodecFailure = '';

String? _pickMimeType() {
  if (_mediaRecorderCtor == null) {
    // No MediaRecorder at all. Nothing in this file can help.
    lastCodecFailure = 'no_mediarecorder';
    return null;
  }
  final tried = <String>[];
  for (final type in _mimeCandidates) {
    try {
      if (_JSMediaRecorder.isTypeSupported(type)) {
        lastCodecFailure = '';
        return type;
      }
      tried.add(type);
    } catch (_) {
      // Keep going. Some engines THROW on a container they do not know rather
      // than answering false, and the old code took that as a verdict on the
      // whole list — so one unrecognised string ruled out the formats after
      // it, none of which had been asked about.
      tried.add(type);
    }
  }
  lastCodecFailure = 'no_mime_of_${tried.length}';
  return null;
}
/// The one microphone stream for the whole conversation.
///
/// This is the fix for the version that made things worse. Opening the device
/// per turn showed no permission dialog — that part was right — but acquiring
/// it is not free when a stream is already running: on an Android WebView it
/// took seconds, and a ten second round trip became as much as forty-seven.
///
/// Opened once on the first turn and kept until the session ends, so the cost
/// is paid once instead of every time somebody speaks.
_JSMediaStream? _shared;

Future<_JSMediaStream?> _stream() async {
  final existing = _shared;
  if (existing != null) {
    try {
      // A track the browser reclaimed is no use; drop it and open another.
      //
      // It has to be asked whether it is LIVE, not whether it exists. An ended
      // track stays in `getTracks()` — so the old check ("are there any
      // tracks?") was true for a microphone that had already been taken away,
      // and this function kept handing back a dead stream. A `MediaRecorder`
      // built on one starts, stops and reports no error; it simply produces no
      // audio. The caller then finds nothing to upload and quietly falls back
      // to WAV, which is the 550 KB upload this whole file exists to avoid —
      // for the rest of the app's life, with nothing anywhere saying so.
      //
      // A WebView that was backgrounded, or a phone where another app took the
      // microphone, is enough to end a track. That is an ordinary afternoon.
      final live = existing
          .getTracks()
          .toDart
          .any((t) => (t as _JSTrack).readyState == 'live');
      if (live) return existing;
      releaseOpusMicrophone();
    } catch (_) {
      // Fall through and reopen.
    }
  }
  try {
    final constraints = {
      'audio': {
        'channelCount': 1,
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
    }.jsify() as JSObject;
    return _shared = (await _getUserMedia(constraints).toDart) as _JSMediaStream;
  } catch (_) {
    return null;
  }
}

/// Give the device back. Called when the conversation ends, not when a turn does.
void releaseOpusMicrophone() {
  final stream = _shared;
  _shared = null;
  if (stream == null) return;
  try {
    for (final track in stream.getTracks().toDart) {
      (track as _JSTrack).stop();
    }
  } catch (_) {
    // Already gone.
  }
}

class OpusCapture {
  OpusCapture._(this._recorder, this.mimeType);

  final _JSMediaRecorder _recorder;

  /// What the browser chose. The caller turns this into a filename extension,
  /// which is the only codec hint the transcriber gets.
  final String mimeType;

  final _chunks = <JSObject>[];
  final _done = Completer<void>();
  var _closed = false;

  /// Set only while [snapshot] is waiting for its flush to arrive.
  void Function()? _onChunk;

  static bool get isSupported => _pickMimeType() != null;

  /// Open the microphone and start recording, or null if anything is missing.
  static Future<OpusCapture?> start() async {
    final type = _pickMimeType();
    if (type == null) return null;
    try {
      final stream = await _stream();
      if (stream == null) return null;

      final options = {'mimeType': type, 'audioBitsPerSecond': 24000}.jsify()
          as JSObject;
      final recorder = _JSMediaRecorder(stream, options);
      final capture = OpusCapture._(recorder, type);

      recorder.ondataavailable = ((JSObject event) {
        final blob = (event as _JSBlobEvent).data;
        if (blob != null) capture._chunks.add(blob);
        // Wakes a pending `snapshot()`. Null at every other moment, so the
        // ordinary recording path is untouched.
        capture._onChunk?.call();
      }).toJS;
      recorder.onstop = ((JSObject _) {
        if (!capture._done.isCompleted) capture._done.complete();
      }).toJS;

      recorder.start();
      return capture;
    } catch (_) {
      // No permission, no device, a browser that lied about support. The
      // caller falls back rather than failing the turn.
      return null;
    }
  }

  /// Everything encoded so far, without ending the recording.
  ///
  /// Called when the learner goes quiet but before the turn is committed, so
  /// the utterance can be transcribed during the grace period instead of after
  /// it. Recording continues; if they resume, this snapshot is simply thrown
  /// away and the eventual clip still contains every word.
  ///
  /// Null when there is nothing yet, or when the browser did not deliver the
  /// flush promptly — the caller then does exactly what it did before.
  Future<Uint8List?> snapshot() async {
    if (_closed) return null;
    try {
      if (_recorder.state != 'recording') return null;
      final before = _chunks.length;
      final arrived = Completer<void>();
      _onChunk = () {
        if (!arrived.isCompleted) arrived.complete();
      };
      _recorder.requestData();
      // Bounded, unlike the wait in `stop()`. There the last chunk is owed to
      // us and the turn cannot proceed without it; here nothing is owed and the
      // learner is still inside their grace period, so a browser that does not
      // answer promptly costs the speculation rather than the turn.
      await arrived.future.timeout(
        const Duration(milliseconds: 400),
        onTimeout: () {},
      );
      _onChunk = null;
      if (_chunks.length == before) return null;
      return await _joined();
    } catch (_) {
      _onChunk = null;
      return null;
    }
  }

  /// Concatenate every chunk held so far into one buffer.
  Future<Uint8List?> _joined() async {
    var total = 0;
    final parts = <Uint8List>[];
    for (final chunk in _chunks) {
      final buffer = await (chunk as _JSBlob).arrayBuffer().toDart;
      final bytes = buffer.toDart.asUint8List();
      total += bytes.length;
      parts.add(bytes);
    }
    if (total == 0) return null;
    final out = Uint8List(total);
    var at = 0;
    for (final part in parts) {
      out.setAll(at, part);
      at += part.length;
    }
    return out;
  }

  /// Stop, and return the recording. Null when nothing was captured.
  ///
  /// [onStage] is a measurement hook and nothing more: it is called with
  /// `recorder_stopped` once the browser has delivered the last chunk, and with
  /// `bytes_ready` once they are one buffer. Both are awaits that were invisible
  /// from outside, and between them they are the whole gap between "the turn
  /// ended" and "there is something to upload". Never provided in tests or by
  /// callers that do not measure; the recording path does not change either way.
  Future<Uint8List?> stop({void Function(String stage)? onStage}) async {
    if (_closed) return null;
    _closed = true;
    try {
      if (_recorder.state != 'inactive') _recorder.stop();
      // The last chunk arrives with `onstop`, not before it. No timeout here:
      // the two-second one this used to have was added to EVERY turn, and was
      // most of why the first attempt read as slow even when it worked.
      await _done.future;
      onStage?.call(TurnTimeline.mRecorderStopped);
      // The same concatenation `snapshot()` uses, so a speculative prefix and
      // the final clip can never be assembled two different ways.
      final out = await _joined();
      if (out == null) return null;
      onStage?.call(TurnTimeline.mBytesReady);
      return out;
    } catch (_) {
      return null;
    }
  }

  /// Abandon the recording and give the microphone back.
  void cancel() {
    if (_closed) return;
    _closed = true;
    try {
      if (_recorder.state != 'inactive') _recorder.stop();
    } catch (_) {
      // Already gone.
    }
  }

}
