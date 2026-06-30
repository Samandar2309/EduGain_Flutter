import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'wav_envelope.dart';

/// Plays one short audio clip at a time. [play] resolves only when the clip
/// finishes (or is cut short by [stop]) — that completion contract is what lets
/// [TtsService] serialise spoken sentences with no overlap.
abstract class AudioPlayback {
  /// Play [bytes] to completion. Must not throw on a decode/playback hiccup in
  /// a way that breaks the caller — failures should surface as a resolved (or
  /// caught) future so the chat keeps working.
  Future<void> play(Uint8List bytes);

  /// Stop immediately; any in-flight [play] resolves.
  Future<void> stop();

  /// Live mouth level (0 closed .. 1 wide) tracking the playing clip's loudness;
  /// 0 when nothing is playing. The avatar lip-syncs to this.
  ValueListenable<double> get level;

  Future<void> dispose();
}

/// `just_audio`-backed playback. The bytes are written to a temp `.wav` and
/// played from disk — the most reliable cross-platform path for arbitrary audio
/// (avoids per-platform `setAudioSource`-from-bytes quirks). `just_audio`'s
/// `play()` future completes when the clip reaches its end or is stopped, which
/// is exactly the completion contract above.
class JustAudioPlayback implements AudioPlayback {
  JustAudioPlayback({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final ValueNotifier<double> _level = ValueNotifier<double>(0);
  int _seq = 0;
  Directory? _tmp;

  static const int _fps = 30;

  @override
  ValueListenable<double> get level => _level;

  @override
  Future<void> play(Uint8List bytes) async {
    final file = await _writeTemp(bytes);
    // Pre-compute the loudness envelope so the mouth tracks the real voice.
    final env = amplitudeEnvelope(bytes, fps: _fps);

    // setFilePath resets the player to a non-terminal state, so the predicate
    // below can't match a *stale* `completed` left over from the previous clip.
    await _player.setFilePath(file.path);
    // Resolve on natural end (`completed`) or an external stop (`idle`). We wait
    // on the state stream rather than trusting `play()`'s own completion, which
    // is version-dependent — getting it wrong would hang the whole queue after
    // the first sentence.
    final done = _player.processingStateStream.firstWhere(
      (s) => s == ProcessingState.completed || s == ProcessingState.idle,
    );
    // Poll the play position and emit the matching envelope level. ~30 Hz is
    // ample — the avatar smooths it to 60 FPS.
    final ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _level.value = _levelAt(env, _player.position);
    });

    await _player.play();
    await done;
    ticker.cancel();
    _level.value = 0;
    // Reset to idle so the next setFilePath starts cleanly; harmless if already
    // stopped, and best-effort cleanup of the temp clip.
    await _player.stop();
    unawaited(file.delete().catchError((_) => file));
  }

  double _levelAt(List<double> env, Duration pos) {
    final secs = pos.inMicroseconds / 1e6;
    if (env.isEmpty) return _synthetic(secs); // un-parseable audio → keep alive
    final idx = (secs * _fps).floor();
    if (idx < 0 || idx >= env.length) return 0;
    return env[idx];
  }

  // Believable lip-flap when the envelope is unavailable (non-PCM audio).
  double _synthetic(double t) {
    final a = 0.5 + 0.5 * math.sin(t * 16.0);
    final b = 0.5 + 0.5 * math.sin(t * 6.3 + 1.7);
    return (0.1 + (a * 0.7 + b * 0.3) * 0.9).clamp(0.0, 1.0);
  }

  Future<File> _writeTemp(Uint8List bytes) async {
    final dir = _tmp ??= await getTemporaryDirectory();
    // Unique name per clip so the player never replays a cached previous file.
    final file = File('${dir.path}/tts_${_seq++}.wav');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

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
