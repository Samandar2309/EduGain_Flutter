import 'dart:async';
import 'dart:convert';

import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Records what it plays; optionally blocks each [play] on a gate so a test can
/// observe a "currently playing" state and then interrupt it.
class _FakePlayback extends AudioPlayback {
  final List<String> played = [];
  final List<double> speeds = [];
  int stops = 0;
  int disposes = 0;
  bool block = false;
  Completer<void>? _gate;

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  final ValueNotifier<double> level = ValueNotifier<double>(0);

  @override
  Future<void> play(Uint8List bytes) async {
    played.add(utf8.decode(bytes));
    if (block) {
      final gate = _gate = Completer<void>();
      await gate.future;
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<void> dispose() async {
    disposes++;
    _gate?.complete();
    _gate = null;
  }
}

void main() {
  group('TtsService', () {
    late _FakePlayback playback;
    late List<List<String>> synthCalls;

    Future<Uint8List> synth(String text, String voice) async {
      synthCalls.add([text, voice]);
      if (text == 'boom') throw Exception('synth failed');
      return _bytes(text);
    }

    TtsService make() =>
        TtsService(synthesize: synth, playback: playback, voice: 'troy');

    setUp(() {
      playback = _FakePlayback();
      synthCalls = [];
    });

    test('plays queued sentences in order', () async {
      make()
        ..enqueue('one')
        ..enqueue('two')
        ..enqueue('three');
      await pumpEventQueue();
      expect(playback.played, ['one', 'two', 'three']);
    });

    test('synthesises in the current voice', () async {
      final tts = make()..voice = 'hannah';
      tts.enqueue('hello');
      await pumpEventQueue();
      expect(synthCalls, [
        ['hello', 'hannah'],
      ]);
    });

    test('a voice change applies to later sentences', () async {
      final tts = make();
      tts
        ..voice = 'troy'
        ..enqueue('first');
      await pumpEventQueue();
      tts
        ..voice = 'diana'
        ..enqueue('second');
      await pumpEventQueue();
      expect(synthCalls, [
        ['first', 'troy'],
        ['second', 'diana'],
      ]);
    });

    test('a synth failure is skipped, the rest still play', () async {
      make()
        ..enqueue('x')
        ..enqueue('boom')
        ..enqueue('y');
      await pumpEventQueue();
      expect(playback.played, ['x', 'y']);
    });

    test('ignores empty / whitespace-only text', () async {
      make()
        ..enqueue('   ')
        ..enqueue('');
      await pumpEventQueue();
      expect(playback.played, isEmpty);
      expect(synthCalls, isEmpty);
    });

    test('stop interrupts playback, clears the queue, and a new turn is clean',
        () async {
      playback.block = true;
      final tts = make()
        ..enqueue('a')
        ..enqueue('b')
        ..enqueue('c');
      await pumpEventQueue();
      // 'a' is playing (blocked); 'b','c' still queued.
      expect(playback.played, ['a']);

      await tts.stop();
      expect(playback.stops, greaterThanOrEqualTo(1));

      // A fresh turn after stop plays cleanly with no leftover b/c.
      playback.block = false;
      tts.enqueue('d');
      await pumpEventQueue();
      expect(playback.played, ['a', 'd']);
    });

    test('speaking signal is true while playing and false once drained',
        () async {
      playback.block = true;
      final tts = make()..enqueue('hi');
      await pumpEventQueue();
      expect(tts.speaking.value, isTrue); // a clip is playing

      playback.block = false;
      await tts.stop();
      expect(tts.speaking.value, isFalse);
    });

    test('speaking returns to false after the queue empties on its own',
        () async {
      final tts = make()
        ..enqueue('one')
        ..enqueue('two');
      await pumpEventQueue();
      expect(playback.played, ['one', 'two']);
      expect(tts.speaking.value, isFalse);
    });

    test('dispose stops, disposes the player, and ignores further enqueues',
        () async {
      final tts = make();
      await tts.dispose();
      expect(playback.disposes, 1);
      tts.enqueue('late');
      await pumpEventQueue();
      expect(playback.played, isEmpty);
    });

    test('replay speaks the line again without a turn, at normal speed',
        () async {
      final tts = make()..enqueue('first');
      await pumpEventQueue();
      playback.played.clear();

      await tts.replay('Hello there. How are you?');
      await pumpEventQueue();

      // split into sentences so it starts speaking promptly
      expect(playback.played, ['Hello there.', 'How are you?']);
      // The rate is set explicitly every time, so a replay is never left slow
      // by an earlier one whose restore did not land.
      expect(playback.speeds, [1.0]);
    });

    test('slow replay sets the rate and restores it afterwards', () async {
      final tts = make();
      await tts.replay('Say it slowly.', speed: 0.7);
      await pumpEventQueue();

      expect(playback.played, ['Say it slowly.']);
      expect(playback.speeds.first, 0.7);
      expect(playback.speeds.last, 1.0, reason: 'the next turn must not be slow');
    });

    test('replay drops whatever was already queued', () async {
      final tts = make()
        ..enqueue('stale one')
        ..enqueue('stale two');
      playback.block = true;
      await pumpEventQueue();

      playback.block = false;
      await tts.replay('the only thing that should be heard');
      await pumpEventQueue();

      expect(playback.played.last, 'the only thing that should be heard');
      expect(playback.played, isNot(contains('stale two')));
    });

    test('replay after dispose is ignored', () async {
      final tts = make();
      await tts.dispose();
      await tts.replay('too late');
      await pumpEventQueue();
      expect(playback.played, isEmpty);
    });

    // ── rendered-audio cache ────────────────────────────────────────────
    // Synthesis is billed against the learner's daily tts_chars budget, so
    // audio we already hold must never be paid for twice.
    test('replaying a line does not re-synthesise it', () async {
      final tts = make()..enqueue('Hello there.');
      await pumpEventQueue();
      expect(synthCalls.length, 1);

      await tts.replay('Hello there.');
      await pumpEventQueue();
      await tts.replay('Hello there.', speed: 0.7);
      await pumpEventQueue();

      // played three times, paid for once
      expect(playback.played.length, 3);
      expect(synthCalls.length, 1, reason: 'replay must be free');
    });

    test('the same voice+text is synthesised once even when requested at once',
        () async {
      final tts = make();
      // two callers race for the identical clip
      await Future.wait([
        tts.replay('Same line.'),
        tts.replay('Same line.'),
      ]);
      await pumpEventQueue();
      expect(synthCalls.length, 1, reason: 'in-flight requests must coalesce');
    });

    test('a different voice is different audio, not a cache hit', () async {
      final tts = make()..enqueue('Ping.');
      await pumpEventQueue();
      tts
        ..voice = 'diana'
        ..enqueue('Ping.');
      await pumpEventQueue();
      expect(synthCalls, [
        ['Ping.', 'troy'],
        ['Ping.', 'diana'],
      ]);
    });

    test('a failed synth is not cached, so a retry really retries', () async {
      final tts = make()..enqueue('boom');
      await pumpEventQueue();
      expect(synthCalls.length, 1);
      expect(playback.played, isEmpty);

      await tts.replay('boom');
      await pumpEventQueue();
      expect(synthCalls.length, 2, reason: 'a failure must not poison the line');
    });

    test('the cache is bounded, so a long session cannot grow without limit',
        () async {
      final tts = make();
      for (var i = 0; i < 60; i++) {
        tts.enqueue('line number $i.');
      }
      await pumpEventQueue();
      expect(playback.played.length, 60);
      expect(tts.cachedClips, lessThanOrEqualTo(24));
    });

    test('an oversized clip is played but never cached', () async {
      final big = Uint8List(2 * 1024 * 1024); // over the per-clip ceiling
      var calls = 0;
      final tts = TtsService(
        synthesize: (t, v) async {
          calls++;
          return big;
        },
        playback: playback,
      )..enqueue('huge');
      await pumpEventQueue();
      expect(tts.cachedClips, 0);

      await tts.replay('huge');
      await pumpEventQueue();
      expect(calls, 2, reason: 'not cached, so it is fetched again');
    });

    test('dispose releases the cached audio', () async {
      final tts = make()..enqueue('hold me.');
      await pumpEventQueue();
      expect(tts.cachedClips, 1);
      await tts.dispose();
      expect(tts.cachedClips, 0);
    });

    // ── gapless playback ────────────────────────────────────────────────
    // Rendering only after the previous clip finished made every sentence
    // boundary cost a full network round-trip, which is heard as the tutor
    // hesitating mid-thought.
    test('renders the next sentence while the current one is still playing',
        () async {
      playback.block = true; // hold the first clip open
      make()
        ..enqueue('first sentence.')
        ..enqueue('second sentence.');
      await pumpEventQueue();

      expect(playback.played, ['first sentence.'], reason: 'still on the first');
      expect(
        synthCalls.map((c) => c[0]),
        containsAll(['first sentence.', 'second sentence.']),
        reason: 'the next clip must already be rendered, not started later',
      );
    });

    test('the prefetched clip is reused, not rendered twice', () async {
      make()
        ..enqueue('alpha.')
        ..enqueue('beta.');
      await pumpEventQueue();

      expect(playback.played, ['alpha.', 'beta.']);
      // One render per sentence — the prefetch primed the cache the drain then hit.
      expect(synthCalls.length, 2);
    });

    test('a failed prefetch is retried when its turn comes, not skipped',
        () async {
      var attempts = 0;
      final tts = TtsService(
        synthesize: (t, v) async {
          if (t == 'flaky.') {
            attempts++;
            if (attempts == 1) throw Exception('transient');
          }
          return _bytes(t);
        },
        playback: playback,
      )
        ..enqueue('steady.')
        ..enqueue('flaky.');
      await pumpEventQueue();

      expect(attempts, 2, reason: 'prefetch failed, the real turn retried');
      expect(playback.played, ['steady.', 'flaky.']);
      await tts.dispose();
    });
  });
}
