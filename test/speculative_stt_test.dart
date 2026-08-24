import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:edugain/features/speaking/data/speculative_stt.dart';

/// Transcribing during the pause is only worth having if it can never be
/// mistaken for the turn it does not belong to. What is asserted here is mostly
/// the refusals: a resumed sentence must not carry its half-transcript into the
/// real turn, a failure must be invisible, and an answer that arrives after its
/// silence has ended must be thrown away rather than used.
void main() {
  Uint8List bytes(int n) => Uint8List.fromList(List<int>.filled(n, 7));

  group('SpeculativeStt', () {
    test('silence starting sends the clip to be transcribed', () async {
      final sent = <(int, String)>[];
      final s = SpeculativeStt(
        transcribe: (b, f) async => sent.add((b.length, f)),
      );

      s.begin(bytes(4000), 'turn.webm');
      await Future<void>.delayed(Duration.zero);

      expect(sent, [(4000, 'turn.webm')]);
      expect(s.isActive, isTrue);
    });

    test('a completed transcript is reused by the turn', () async {
      final s = SpeculativeStt(transcribe: (b, f) async {});
      s.begin(bytes(4000), 'turn.webm');
      await Future<void>.delayed(Duration.zero);

      expect(await s.settle(), isNotNull);
      expect((await s.settle())!.length, 4000);
      expect(s.filename, 'turn.webm');
    });

    test('a turn that commits early waits for the same request', () async {
      final gate = Completer<void>();
      var calls = 0;
      final s = SpeculativeStt(
        transcribe: (b, f) async {
          calls++;
          await gate.future;
        },
      );
      s.begin(bytes(4000), 'turn.webm');

      final settled = s.settle();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.complete(); // the in-flight request finishes
      expect(await settled, isNotNull);
      // Waited for the one already running rather than starting a second.
      expect(calls, 1);
    });

    test('a resumed sentence discards the result', () async {
      final s = SpeculativeStt(transcribe: (b, f) async {});
      s.begin(bytes(4000), 'turn.webm');
      await Future<void>.delayed(Duration.zero);

      s.discard(); // the learner carried on talking
      expect(s.isActive, isFalse);
      expect(await s.settle(), isNull);
    });

    test('a reply that lands after the learner resumed is not used', () async {
      final gate = Completer<void>();
      final s = SpeculativeStt(
        transcribe: (b, f) async => gate.future,
      );
      s.begin(bytes(4000), 'turn.webm');
      // Resumes while the request is still out.
      s.discard();
      gate.complete();
      await Future<void>.delayed(Duration.zero);

      // The answer arrived, but for a silence that is over. It must not be
      // attached to whatever turn happens to be current.
      expect(await s.settle(), isNull);
    });

    test('a failure falls back to the ordinary upload', () async {
      final s = SpeculativeStt(
        transcribe: (b, f) async => throw StateError('provider down'),
      );
      s.begin(bytes(4000), 'turn.webm');
      await Future<void>.delayed(Duration.zero);

      // No throw reaches the caller, and the turn simply gets nothing back.
      expect(await s.settle(), isNull);
    });

    test('a request that never answers times out rather than holding the turn',
        () async {
      final s = SpeculativeStt(transcribe: (b, f) => Completer<void>().future);
      s.begin(bytes(4000), 'turn.webm');

      expect(
        await s.settle(timeout: const Duration(milliseconds: 30)),
        isNull,
      );
    });

    test('nothing leaks into the next turn', () async {
      final s = SpeculativeStt(transcribe: (b, f) async {});
      s.begin(bytes(4000), 'first.webm');
      await Future<void>.delayed(Duration.zero);
      expect(await s.settle(), isNotNull);

      // The turn is sent and the next one begins.
      s.reset();
      expect(s.isActive, isFalse);
      expect(await s.settle(), isNull);
      expect(s.filename, isNull);
      // The next turn's own speculation is unaffected by the last one.
      s.begin(bytes(9000), 'second.webm');
      await Future<void>.delayed(Duration.zero);
      expect((await s.settle())!.length, 9000);
      expect(s.filename, 'second.webm');
    });

    test('one silence buys at most one transcription', () async {
      var calls = 0;
      final s = SpeculativeStt(transcribe: (b, f) async => calls++);
      s.begin(bytes(4000), 'turn.webm');
      s.begin(bytes(4000), 'turn.webm'); // a second reading in the same silence
      s.begin(bytes(4000), 'turn.webm');
      await Future<void>.delayed(Duration.zero);

      expect(calls, 1);
    });

    test('a hesitant learner cannot buy unlimited transcriptions', () async {
      var calls = 0;
      final s = SpeculativeStt(
        transcribe: (b, f) async => calls++,
        maxPerTurn: 2,
      );
      // Pause, resume, pause, resume, pause — three silences in one turn.
      for (var i = 0; i < 3; i++) {
        s.begin(bytes(4000), 'turn.webm');
        await Future<void>.delayed(Duration.zero);
        s.discard();
      }
      expect(calls, 2, reason: 'the third pause falls back to waiting');
      expect(s.attemptsThisTurn, 2);

      // A new turn restores the budget.
      s.reset();
      s.begin(bytes(4000), 'turn.webm');
      await Future<void>.delayed(Duration.zero);
      expect(calls, 3);
    });

    test('the budget is per turn, not per session', () async {
      var calls = 0;
      final s = SpeculativeStt(
        transcribe: (b, f) async => calls++,
        maxPerTurn: 1,
      );
      for (var turn = 0; turn < 3; turn++) {
        s.reset();
        s.begin(bytes(4000), 'turn.webm');
        await Future<void>.delayed(Duration.zero);
      }
      expect(calls, 3);
    });
  });

  group('the snapshot the speculation runs on', () {
    // `SpeechRecorder.snapshot()` itself is guarded on `kIsWeb` and needs a
    // live capture, so it cannot run here. What can be pinned is the thing
    // that would fail silently: a snapshot must READ the recording so far, not
    // consume it. `takeBytes` empties a BytesBuilder; the turn that follows
    // would then upload a clip missing everything said before the pause, and
    // nothing would report an error — the learner would simply be answered as
    // if they had said less than they did.
    test('reading a builder twice gives the same bytes', () {
      final b = BytesBuilder(copy: false)
        ..add(Uint8List.fromList([1, 2, 3, 4]));
      final first = b.toBytes();
      b.add(Uint8List.fromList([5, 6]));
      final second = b.toBytes();
      expect(first, [1, 2, 3, 4], reason: 'the first read was consumed');
      expect(second, [1, 2, 3, 4, 5, 6], reason: 'later audio was lost');
    });

    test('taking it would lose the recording — which is why it is not used', () {
      final b = BytesBuilder(copy: false)
        ..add(Uint8List.fromList([1, 2, 3, 4]));
      b.takeBytes();
      expect(b.toBytes(), isEmpty);
    });
  });
}
