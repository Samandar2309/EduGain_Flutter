import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

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

extension type _JSMediaRecorder._(JSObject _) implements JSObject {
  external factory _JSMediaRecorder(JSObject stream, JSObject options);
  external static bool isTypeSupported(String type);
  external void start();
  external void stop();
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
}

/// The container the browser will actually produce, or null if none of them.
///
/// WebM first because it is what Chrome and the Android WebView emit, which is
/// every learner we have. MP4 is Safari's, and is checked so an iPhone is not
/// silently left on the WAV path.
String? _pickMimeType() {
  if (_mediaRecorderCtor == null) return null;
  for (final type in const [
    'audio/webm;codecs=opus',
    'audio/webm',
    'audio/mp4',
  ]) {
    try {
      if (_JSMediaRecorder.isTypeSupported(type)) return type;
    } catch (_) {
      return null;
    }
  }
  return null;
}

class OpusCapture {
  OpusCapture._(this._recorder, this._stream, this.mimeType);

  final _JSMediaRecorder _recorder;
  final _JSMediaStream _stream;

  /// What the browser chose. The caller turns this into a filename extension,
  /// which is the only codec hint the transcriber gets.
  final String mimeType;

  final _chunks = <JSObject>[];
  final _done = Completer<void>();
  var _closed = false;

  static bool get isSupported => _pickMimeType() != null;

  /// Open the microphone and start recording, or null if anything is missing.
  static Future<OpusCapture?> start() async {
    final type = _pickMimeType();
    if (type == null) return null;
    try {
      final constraints = {
        'audio': {
          'channelCount': 1,
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
      }.jsify() as JSObject;
      final stream = (await _getUserMedia(constraints).toDart) as _JSMediaStream;

      final options = {'mimeType': type, 'audioBitsPerSecond': 24000}.jsify()
          as JSObject;
      final recorder = _JSMediaRecorder(stream, options);
      final capture = OpusCapture._(recorder, stream, type);

      recorder.ondataavailable = ((JSObject event) {
        final blob = (event as _JSBlobEvent).data;
        if (blob != null) capture._chunks.add(blob);
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

  /// Stop, and return the recording. Null when nothing was captured.
  Future<Uint8List?> stop() async {
    if (_closed) return null;
    _closed = true;
    try {
      if (_recorder.state != 'inactive') _recorder.stop();
      // The last chunk arrives with `onstop`, not before it.
      await _done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      _release();

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
    } catch (_) {
      _release();
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
    _release();
  }

  /// Hand the device back.
  ///
  /// Held only for the length of one turn, unlike the session-long stream the
  /// WAV path keeps. A track left running is a microphone indicator that never
  /// goes out, which learners read as being listened to.
  void _release() {
    try {
      for (final track in _stream.getTracks().toDart) {
        (track as _JSTrack).stop();
      }
    } catch (_) {
      // Nothing to release.
    }
  }
}
