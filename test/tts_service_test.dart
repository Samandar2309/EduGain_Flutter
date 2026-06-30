import 'dart:async';
import 'dart:convert';

import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Records what it plays; optionally blocks each [play] on a gate so a test can
/// observe a "currently playing" state and then interrupt it.
class _FakePlayback implements AudioPlayback {
  final List<String> played = [];
  int stops = 0;
  int disposes = 0;
  bool block = false;
  Completer<void>? _gate;

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
  });
}
