import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../speaking/data/audio_playback.dart';
import 'word_tts.dart';

/// Speaks an English word or sentence aloud using clean, server-rendered TTS
/// (the same Groq voice the Speaking tutor uses).
///
/// Why not the browser's speech engine: inside the Telegram in-app WebView
/// `speechSynthesis` typically exposes no English voice, so it reads English in
/// the phone's own (Uzbek/Russian) engine — unintelligible. Server audio sounds
/// identical and natural on every device. If the server is unreachable we fall
/// back to on-device speech, so a network blip never leaves the games silent.
class Pronouncer {
  Pronouncer(this._fetch);

  /// Fetches server-rendered audio bytes for [text]. Injected so the service
  /// stays independent of the HTTP layer (and trivially fakeable).
  final Future<Uint8List> Function(String text) _fetch;

  final AudioPlayback _playback = createAudioPlayback();
  // Session cache: a fixed vocabulary repeats constantly, so each clip is
  // fetched at most once per app run.
  final Map<String, Uint8List> _cache = {};
  int _gen = 0;
  bool _disposed = false;

  /// Speak [text]. Cheap on repeats (bytes cached); a newer call cuts off
  /// whatever is currently playing so taps never overlap.
  Future<void> speak(String text) async {
    final t = text.trim();
    if (t.isEmpty || _disposed) return;
    final key = t.toLowerCase();
    final gen = ++_gen;

    var bytes = _cache[key];
    if (bytes == null) {
      try {
        bytes = await _fetch(t);
        _cache[key] = bytes;
      } catch (_) {
        WordTts.speak(t); // degrade to on-device speech
        return;
      }
    }
    if (_disposed || gen != _gen) return; // superseded by a newer tap

    try {
      await _playback.stop();
      if (_disposed || gen != _gen) return;
      await _playback.play(bytes);
    } catch (_) {
      WordTts.speak(t);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _playback.dispose();
    } catch (_) {}
  }
}

/// App-scoped so the audio player and clip cache are shared across every game.
final pronouncerProvider = Provider<Pronouncer>((ref) {
  final api = ref.read(apiClientProvider);
  final p = Pronouncer(
    (text) => api.postBytes('/pronounce', body: {'text': text}),
  );
  ref.onDispose(p.dispose);
  return p;
});
