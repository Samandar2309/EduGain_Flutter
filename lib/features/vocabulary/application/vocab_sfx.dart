import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Tiny sound-effect player for the vocab games — three preloaded, synthesized
/// chimes (correct / wrong / streak). Kept app-scoped (a plain [Provider]) so
/// the assets load once and every game plays them with no startup latency.
class VocabSfx {
  final AudioPlayer _correct = AudioPlayer();
  final AudioPlayer _wrong = AudioPlayer();
  final AudioPlayer _streak = AudioPlayer();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await _correct.setAsset('assets/sfx/correct.wav');
      await _wrong.setAsset('assets/sfx/wrong.wav');
      await _streak.setAsset('assets/sfx/streak.wav');
      _ready = true;
    } on Object {
      // Audio unavailable (rare) — the games stay fully playable, just silent.
    }
  }

  void _fire(AudioPlayer p) {
    if (!_ready) return;
    // Restart from the top so rapid consecutive answers each get a fresh hit.
    p.seek(Duration.zero);
    p.play();
  }

  void correct() => _fire(_correct);
  void wrong() => _fire(_wrong);
  void streak() => _fire(_streak);

  Future<void> dispose() async {
    await _correct.dispose();
    await _wrong.dispose();
    await _streak.dispose();
  }
}

final vocabSfxProvider = Provider<VocabSfx>((ref) {
  final sfx = VocabSfx();
  sfx.init();
  ref.onDispose(sfx.dispose);
  return sfx;
});
