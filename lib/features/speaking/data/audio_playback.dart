import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_playback_web.dart'
    if (dart.library.io) 'audio_playback_native.dart' as impl;
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

  /// Playback rate for subsequent clips (1.0 = as rendered). Used to replay a
  /// line slowly for a learner who missed it; the lip-sync stays honest because
  /// the envelope is sampled by SOURCE position, which slows with the audio.
  Future<void> setSpeed(double speed);

  /// Call from inside a user-gesture handler (e.g. the mic button tap) to
  /// satisfy browser autoplay policies before any real clip plays. No-op on
  /// native, where no such policy exists.
  Future<void> prime() async {}

  /// Live mouth level (0 closed .. 1 wide) tracking the playing clip's loudness;
  /// 0 when nothing is playing. The avatar lip-syncs to this.
  ValueListenable<double> get level;

  Future<void> dispose();
}

/// The right [AudioPlayback] for this platform: file-backed on native
/// ([impl.createPlatformAudioPlayback] resolves to `JustAudioPlayback`, which
/// needs `dart:io`), memory-backed on web (`WebAudioPlayback`, no filesystem
/// at all). Callers never need to know which — this is the only thing they
/// should import from this feature's playback layer.
AudioPlayback createAudioPlayback() => impl.createPlatformAudioPlayback();

const int envelopeFps = 30;

/// Shared by every [AudioPlayback] implementation: pre-compute the loudness
/// envelope, load the clip via [loadSource] (the only platform-specific
/// step), then drive [level] off a position-tracking ticker until the clip
/// naturally completes or is externally stopped.
Future<void> playFollowingEnvelope({
  required AudioPlayer player,
  required Uint8List bytes,
  required ValueNotifier<double> level,
  required Future<void> Function() loadSource,
}) async {
  final env = amplitudeEnvelope(bytes, fps: envelopeFps);
  await loadSource();

  // Wait until the player is actually holding this clip before listening for
  // the end of it.
  //
  // `processingStateStream` replays its current value the moment you subscribe,
  // and the previous clip left the player at `idle` (this function ends with
  // `stop()`). `setUrl`'s future can resolve a beat before the state stream
  // catches up — so subscribing straight away could match that stale `idle`,
  // resolve `done` instantly, and stop the clip before a single note played.
  // That is the tutor reading half its answer: some sentences played, others
  // were cut at the very start, and nothing failed anywhere.
  //
  // Bounded, because a load that never reaches `ready` must not hang the queue
  // — the clip is skipped and the next sentence still gets spoken.
  await player.processingStateStream
      .firstWhere(
        (s) =>
            s == ProcessingState.ready ||
            s == ProcessingState.buffering ||
            s == ProcessingState.completed,
      )
      .timeout(const Duration(seconds: 5), onTimeout: () => ProcessingState.idle);

  // Now a terminal state genuinely means this clip: `completed` on a natural
  // end, `idle` when something stopped it.
  final done = player.processingStateStream.firstWhere(
    (s) => s == ProcessingState.completed || s == ProcessingState.idle,
  );
  // Poll the play position and emit the matching envelope level. ~30 Hz is
  // ample — the avatar smooths it to 60 FPS.
  final ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
    level.value = levelAtEnvelope(env, player.position);
  });

  await player.play();
  await done;
  ticker.cancel();
  level.value = 0;
  // Reset to idle so the next load starts cleanly; harmless if already stopped.
  await player.stop();
}

double levelAtEnvelope(List<double> env, Duration pos) {
  final secs = pos.inMicroseconds / 1e6;
  if (env.isEmpty) return syntheticLipLevel(secs); // un-parseable audio → keep alive
  final idx = (secs * envelopeFps).floor();
  if (idx < 0 || idx >= env.length) return 0;
  return env[idx];
}

// Believable lip-flap when the envelope is unavailable (non-PCM audio).
double syntheticLipLevel(double t) {
  final a = 0.5 + 0.5 * math.sin(t * 16.0);
  final b = 0.5 + 0.5 * math.sin(t * 6.3 + 1.7);
  return (0.1 + (a * 0.7 + b * 0.3) * 0.9).clamp(0.0, 1.0);
}
