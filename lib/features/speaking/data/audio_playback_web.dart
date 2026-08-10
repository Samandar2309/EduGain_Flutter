import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_playback.dart';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external String _createObjectUrl(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

AudioPlayback createPlatformAudioPlayback() => WebAudioPlayback();

/// Web counterpart of `JustAudioPlayback`. There is no filesystem to stage a
/// temp file on, and `StreamAudioSource` is unusable on web (it needs
/// just_audio's dart:io proxy server, which cannot exist in a browser — the
/// exact cause of the original "voices broken" bug in the Mini App). The clip
/// is played from a blob URL instead: `setUrl` maps straight to `audio.src`,
/// which every browser engine plays natively for WAV.
class WebAudioPlayback extends AudioPlayback {
  WebAudioPlayback({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final ValueNotifier<double> _level = ValueNotifier<double>(0);
  bool _primed = false;
  String? _objectUrl;

  // 100ms of 16 kHz mono silence — enough of a real clip that `play()`
  // inside a user gesture "unlocks" the underlying HTMLAudioElement on
  // engines with strict autoplay policies (Telegram Web / iOS WebViews).
  static final Uint8List _silence = _silentWav();

  static Uint8List _silentWav() {
    const sampleRate = 16000;
    const samples = sampleRate ~/ 10;
    final pcm = Uint8List(samples * 2);
    final header = Uint8List.fromList([
      ...'RIFF'.codeUnits,
      ..._u32(36 + pcm.length),
      ...'WAVE'.codeUnits,
      ...'fmt '.codeUnits,
      ..._u32(16), ..._u16(1), ..._u16(1),
      ..._u32(sampleRate), ..._u32(sampleRate * 2), ..._u16(2), ..._u16(16),
      ...'data'.codeUnits,
      ..._u32(pcm.length),
    ]);
    return Uint8List.fromList([...header, ...pcm]);
  }

  static List<int> _u32(int v) =>
      [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
  static List<int> _u16(int v) => [v & 0xFF, (v >> 8) & 0xFF];

  /// The clip's URL, handed to the browser as bytes rather than as text.
  ///
  /// This used to be a base64 `data:` URI, and that was a real cause of the
  /// freezing learners reported during a tutor's reply: `Uri.dataFromBytes`
  /// encodes the whole clip into a string on the main thread, so a 15-second
  /// answer meant building a ~1 MB String before a single note played. A blob
  /// URL hands the same bytes over without encoding them at all.
  ///
  /// Falls back to the data URI if anything here throws. Playback breaking is
  /// far worse than playback being slow, and this file's own history — the
  /// "voices broken in the Mini App" bug — is the reason for the belt and
  /// braces.
  Future<void> _load(Uint8List bytes) async {
    final url = _blobUrl(bytes);
    if (url != null) {
      try {
        await _player.setUrl(url);
        return;
      } catch (_) {
        // The blob was created but this engine will not play it. Falling back
        // here rather than only around creation is the point: a URL that is
        // made successfully and then refused at playback is the failure that
        // would actually reach a learner, as silence.
        _releaseUrl();
      }
    }
    await _player.setUrl(_dataUri(bytes));
  }

  String? _blobUrl(Uint8List bytes) {
    try {
      final blob = _Blob(
        [bytes.toJS].toJS,
        {'type': 'audio/wav'}.jsify() as JSObject,
      );
      final url = _createObjectUrl(blob);
      _releaseUrl();
      _objectUrl = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  static String _dataUri(Uint8List bytes) =>
      Uri.dataFromBytes(bytes, mimeType: 'audio/wav').toString();

  /// Blob URLs pin their bytes until revoked. One clip per reply over a long
  /// lesson would otherwise hold every clip of that lesson in memory.
  void _releaseUrl() {
    final previous = _objectUrl;
    _objectUrl = null;
    if (previous == null) return;
    try {
      _revokeObjectUrl(previous);
    } catch (_) {
      // Already gone, or the engine disagrees — nothing to do either way.
    }
  }

  @override
  ValueListenable<double> get level => _level;

  /// Unlock autoplay by playing a moment of silence inside a user gesture.
  ///
  /// Latches only on success. It used to set the flag before trying, so a
  /// single failed unlock was permanent: the engine stayed locked, every
  /// following attempt returned early, and the tutor was silent for the rest of
  /// the lesson with nothing logged anywhere. In the Telegram webview — the
  /// strictest autoplay policy we ship against — that is the difference between
  /// a talking tutor and a mute one.
  @override
  Future<void> prime() async {
    if (_primed) return;
    try {
      await _player.setUrl(_dataUri(_silence));
      await _player.play();
      await _player.stop();
      _primed = true; // only now: the engine actually let us make a sound
    } catch (_) {
      // Left unlatched on purpose, so the next gesture tries again.
    }
  }

  @override
  Future<void> play(Uint8List bytes) => playFollowingEnvelope(
    player: _player,
    bytes: bytes,
    level: _level,
    loadSource: () => _load(bytes),
  );

  @override
  Future<void> stop() async {
    _level.value = 0;
    await _player.stop();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    _releaseUrl();
    await _player.dispose();
    _level.dispose();
  }
}
