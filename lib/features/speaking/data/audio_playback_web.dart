import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_playback.dart';

AudioPlayback createPlatformAudioPlayback() => WebAudioPlayback();

/// Web counterpart of `JustAudioPlayback`. There is no filesystem to stage a
/// temp file on, and `StreamAudioSource` is unusable on web (it needs
/// just_audio's dart:io proxy server, which cannot exist in a browser — the
/// exact cause of the original "voices broken" bug in the Mini App). The clip
/// is played from a base64 data URI instead: `setUrl` maps straight to
/// `audio.src`, which every browser engine plays natively for WAV.
class WebAudioPlayback extends AudioPlayback {
  WebAudioPlayback({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final ValueNotifier<double> _level = ValueNotifier<double>(0);
  bool _primed = false;

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

  static String _dataUri(Uint8List bytes) =>
      Uri.dataFromBytes(bytes, mimeType: 'audio/wav').toString();

  @override
  ValueListenable<double> get level => _level;

  @override
  Future<void> prime() async {
    if (_primed) return;
    _primed = true;
    try {
      await _player.setUrl(_dataUri(_silence));
      await _player.play();
      await _player.stop();
    } catch (_) {
      // Best-effort: a failed unlock only means audio stays subject to the
      // engine's autoplay policy — never break the caller's gesture handler.
    }
  }

  @override
  Future<void> play(Uint8List bytes) => playFollowingEnvelope(
    player: _player,
    bytes: bytes,
    level: _level,
    loadSource: () => _player.setUrl(_dataUri(bytes)),
  );

  @override
  Future<void> stop() async {
    _level.value = 0;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _level.dispose();
  }
}
