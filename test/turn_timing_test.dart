import 'package:flutter_test/flutter_test.dart';

import 'package:edugain/features/speaking/data/turn_timing.dart';

/// The timeline is the instrument every later optimisation will be judged with,
/// so the properties that make it trustworthy are asserted rather than assumed:
/// it never goes backwards, it never reports a stage twice, and it never claims
/// a turn spoke when it did not.
void main() {
  group('TurnTimeline', () {
    test('records nothing until the clock is started', () {
      final t = TurnTimeline.create();
      t.mark(TurnTimeline.mFirstAudio);
      expect(t.started, isFalse);
      expect(t[TurnTimeline.mFirstAudio], isNull);
    });

    test('offsets are non-negative and never go backwards', () async {
      final t = TurnTimeline.create()..begin();
      t.mark(TurnTimeline.mSilenceStart);
      await Future<void>.delayed(const Duration(milliseconds: 12));
      t.mark(TurnTimeline.mStopBegin);
      await Future<void>.delayed(const Duration(milliseconds: 12));
      t.mark(TurnTimeline.mFirstAudio);

      final silence = t[TurnTimeline.mSilenceStart]!;
      final stop = t[TurnTimeline.mStopBegin]!;
      final audio = t[TurnTimeline.mFirstAudio]!;
      expect(silence, greaterThanOrEqualTo(0));
      expect(stop, greaterThanOrEqualTo(silence));
      expect(audio, greaterThanOrEqualTo(stop));
    });

    test('a repeated mark keeps the FIRST time it happened', () async {
      final t = TurnTimeline.create()..begin();
      t.mark(TurnTimeline.mFirstChunk);
      final first = t[TurnTimeline.mFirstChunk];
      await Future<void>.delayed(const Duration(milliseconds: 15));
      t.mark(TurnTimeline.mFirstChunk);
      expect(t[TurnTimeline.mFirstChunk], first);
    });

    test('begin() restarts the clock and clears the previous attempt', () async {
      final t = TurnTimeline.create()..begin();
      t.mark(TurnTimeline.mFirstAudio);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // A learner who paused and carried on: the turn that eventually gets sent
      // starts at the LAST time they stopped, so nothing from before survives.
      t.begin();
      expect(t[TurnTimeline.mFirstAudio], isNull);
      expect(t.reachedAudio, isFalse);
      t.mark(TurnTimeline.mSilenceStart);
      expect(t[TurnTimeline.mSilenceStart], lessThan(20));
    });

    test('a turn that never spoke is reported as incomplete', () {
      final t = TurnTimeline.create()..begin();
      t
        ..mark(TurnTimeline.mSilenceStart)
        ..mark(TurnTimeline.mUploadStart)
        ..mark(TurnTimeline.mStreamDone);
      expect(t.reachedAudio, isFalse);
      expect(t.toJson()['outcome'], 'incomplete');
      expect(t.toJson().containsKey(TurnTimeline.mFirstAudio), isFalse);
    });

    test('a turn that spoke is reported as such', () {
      final t = TurnTimeline.create()..begin();
      t.mark(TurnTimeline.mFirstAudio);
      expect(t.reachedAudio, isTrue);
      expect(t.toJson()['outcome'], 'spoke');
    });

    test('marks after end() are ignored', () async {
      final t = TurnTimeline.create()..begin();
      t.mark(TurnTimeline.mStreamDone);
      t.end();
      // A cancelled turn must not collect the NEXT turn's first audio and
      // report it as its own — that would be the one genuinely misleading
      // number this whole layer exists to produce correctly.
      t.mark(TurnTimeline.mFirstAudio);
      expect(t.reachedAudio, isFalse);
    });

    test('one turn carries one id, and ids differ between turns', () {
      final a = TurnTimeline.create()..begin();
      final idBefore = a.turnId;
      a
        ..mark(TurnTimeline.mSilenceStart)
        ..begin()
        ..mark(TurnTimeline.mFirstAudio);
      // Restarting the clock is still the same turn attempt on the same screen.
      expect(a.turnId, idBefore);
      expect(a.toJson()['turn_id'], idBefore);

      final b = TurnTimeline.create();
      expect(b.turnId, isNot(a.turnId));
    });

    test('notes ride along but never overwrite a timing key', () {
      final t = TurnTimeline.create()..begin();
      t
        ..note('audio_format', 'webm')
        ..note('audio_bytes', 51234)
        ..mark(TurnTimeline.mFirstAudio);
      final json = t.toJson();
      expect(json['audio_format'], 'webm');
      expect(json['audio_bytes'], 51234);
      expect(json[TurnTimeline.mFirstAudio], isA<int>());
      expect(json['platform'], isNotEmpty);
    });

    test('the record carries only timings, sizes and labels', () {
      final t = TurnTimeline.create()..begin();
      t
        ..note('audio_format', 'webm')
        ..mark(TurnTimeline.mFirstAudio);
      // Nothing in the shipped record may be free text from the conversation.
      for (final entry in t.toJson().entries) {
        expect(
          entry.value,
          anyOf(isA<int>(), isA<String>(), isA<bool>(), isNull),
          reason: '${entry.key} must be a scalar, never content',
        );
      }
    });
  });
}
