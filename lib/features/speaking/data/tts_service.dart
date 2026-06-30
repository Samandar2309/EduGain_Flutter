import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_playback.dart';

/// Renders one chunk of text to speech bytes in the given voice. Backed by the
/// server TTS endpoint (`POST /speaking/tts`); injected so [TtsService] stays
/// independent of the HTTP layer and is trivially fakeable in tests.
typedef SynthesizeFn = Future<Uint8List> Function(String text, String voice);

/// Speaks the AI's replies out loud using server-rendered TTS audio. Sentences
/// are queued and played one-by-one (each [AudioPlayback.play] resolves only
/// when its clip finishes), so sentences that arrive while the reply is still
/// streaming play back in order without overlapping — the AI starts talking
/// after the first sentence instead of waiting for the whole reply.
class TtsService {
  TtsService({
    required SynthesizeFn synthesize,
    required AudioPlayback playback,
    this.voice = fallbackVoice,
  }) : _synth = synthesize,
       _playback = playback;

  /// A safe default (an Orpheus voice, the backend's default model) used until
  /// the catalogue loads or the learner picks a voice.
  static const String fallbackVoice = 'troy';

  /// The voice future utterances are synthesised in. Cheap to change between
  /// turns; the next sentence picks it up.
  String voice;

  final SynthesizeFn _synth;
  final AudioPlayback _playback;
  final List<String> _queue = [];

  // True while the AI is talking (draining the queue) — drives the avatar's
  // mouth. Exposed as a listenable so the UI reacts without polling.
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);
  ValueListenable<bool> get speaking => _speaking;

  /// Live mouth level (0..1) of the currently playing clip — drives the avatar's
  /// lip-sync. Proxies the audio player; 0 between/while not playing.
  ValueListenable<double> get level => _playback.level;

  // Whether voice synthesis is currently working. Flips to false the first time
  // a synth call fails (e.g. the TTS provider is unavailable) so the UI can show
  // a calm "voice off" hint instead of dying silently; back to true on success.
  final ValueNotifier<bool> _available = ValueNotifier<bool>(true);
  ValueListenable<bool> get available => _available;

  bool _draining = false;
  bool _disposed = false;
  // Bumped by stop()/dispose() to invalidate an in-flight drain so a new turn
  // can never race the previous one on the shared player.
  int _gen = 0;
  Future<void>? _drainFuture;

  /// Queue a phrase to be spoken after anything already playing/queued.
  void enqueue(String text) {
    final t = text.trim();
    if (t.isEmpty || _disposed) return;
    _queue.add(t);
    if (!_draining) {
      _draining = true;
      _speaking.value = true;
      _drainFuture = _drain();
    }
  }

  Future<void> _drain() async {
    final gen = _gen;
    try {
      while (true) {
        if (_disposed || gen != _gen || _queue.isEmpty) return;
        final next = _queue.removeAt(0);
        final v = voice;
        final Uint8List bytes;
        try {
          bytes = await _synth(next, v);
          _available.value = true;
        } catch (_) {
          // A synth failure (network / provider) must never break the chat —
          // mark voice unavailable (the UI shows a calm hint), skip, carry on.
          _available.value = false;
          continue;
        }
        if (_disposed || gen != _gen) return; // stopped while synthesising
        try {
          await _playback.play(bytes);
        } catch (_) {
          // Likewise a playback hiccup is non-fatal.
        }
      }
    } finally {
      // Only the current generation owns the flag; a superseded drain must not
      // clobber a newer one's state.
      if (gen == _gen) {
        _draining = false;
        _speaking.value = false;
      }
    }
  }

  /// Stop immediately and drop anything queued (e.g. the user starts a new turn
  /// and we must not talk over them). Awaits the in-flight drain so a following
  /// [enqueue] starts cleanly.
  Future<void> stop() async {
    _queue.clear();
    _gen++;
    _draining = false;
    _speaking.value = false;
    try {
      await _playback.stop();
    } catch (_) {}
    try {
      await _drainFuture;
    } catch (_) {}
    _drainFuture = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    _queue.clear();
    _gen++;
    _draining = false;
    _speaking.value = false;
    try {
      await _playback.stop();
    } catch (_) {}
    try {
      await _drainFuture;
    } catch (_) {}
    try {
      await _playback.dispose();
    } catch (_) {}
    _speaking.dispose();
    _available.dispose();
  }
}

/// Splits a growing text stream into complete sentences so the first sentence
/// can be spoken while the rest of the reply is still arriving.
class SentenceChunker {
  final StringBuffer _pending = StringBuffer();

  // A run of text ending in a sentence terminator (or newline).
  static final RegExp _sentence = RegExp(r'[^.!?\n]*[.!?\n]+');

  /// Feed a streamed delta; returns any sentences completed by it.
  List<String> add(String delta) {
    _pending.write(delta);
    return _flush(all: false);
  }

  /// Flush the trailing partial sentence when the stream ends.
  List<String> finish() => _flush(all: true);

  List<String> _flush({required bool all}) {
    final text = _pending.toString();
    final out = <String>[];
    var consumed = 0;
    for (final m in _sentence.allMatches(text)) {
      final s = m.group(0)!.trim();
      if (s.isNotEmpty) out.add(s);
      consumed = m.end;
    }
    var remainder = text.substring(consumed);
    if (all) {
      final tail = remainder.trim();
      if (tail.isNotEmpty) out.add(tail);
      remainder = '';
    }
    _pending
      ..clear()
      ..write(remainder);
    return out;
  }
}
