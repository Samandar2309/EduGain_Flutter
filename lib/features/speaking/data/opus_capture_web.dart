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
      if (existing.getTracks().toDart.isNotEmpty) return existing;
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
      // The last chunk arrives with `onstop`, not before it. No timeout here:
      // the two-second one this used to have was added to EVERY turn, and was
      // most of why the first attempt read as slow even when it worked.
      await _done.future;

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
