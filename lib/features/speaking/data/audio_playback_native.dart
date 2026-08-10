import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_playback.dart';

AudioPlayback createPlatformAudioPlayback() => JustAudioPlayback();

/// `just_audio`-backed native playback. The bytes are written to a temp
/// `.wav` and played from disk — the most reliable native path for arbitrary
/// audio (avoids per-platform `setAudioSource`-from-bytes quirks).
class JustAudioPlayback extends AudioPlayback {
  JustAudioPlayback({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final ValueNotifier<double> _level = ValueNotifier<double>(0);
  int _seq = 0;
  Directory? _tmp;

  @override
  ValueListenable<double> get level => _level;

  @override
  Future<void> play(Uint8List bytes) async {
    final file = await _writeTemp(bytes);
    // setFilePath resets the player to a non-terminal state, so the envelope
    // follower can't match a *stale* `completed` left over from the previous clip.
    await playFollowingEnvelope(
      player: _player,
      bytes: bytes,
      level: _level,
      loadSource: () => _player.setFilePath(file.path),
    );
    unawaited(file.delete().catchError((_) => file));
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
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _level.dispose();
  }
}
