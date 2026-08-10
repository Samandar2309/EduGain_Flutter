import 'dart:math' as math;
import 'dart:typed_data';

import 'package:edugain/features/speaking/data/voice_activity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deciding when someone has finished speaking, so they never press anything.
///
/// The two failure modes are not symmetric, and every threshold here follows
/// from that. Ending a turn early cuts a learner off while they are hunting for
/// a word — the exact moment this product exists to support. Ending a turn that
/// holds no speech costs an upload, a transcription and a model call, and hands
/// back nonsense they then have to read. So silence must be long and clearly
/// deliberate before it ends anything, and speech must genuinely have happened.
Uint8List _pcm(double amplitude, {int ms = 100, int sampleRate = 16000}) {
  final frames = sampleRate * ms ~/ 1000;
  final bytes = Uint8List(frames * 2);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < frames; i++) {
    // A tone, not a constant: a DC offset would have an RMS unlike any real
    // microphone signal and would make these numbers meaningless.
    final v = math.sin(2 * math.pi * 180 * i / sampleRate) * amplitude;
    view.setInt16(i * 2, (v * 32000).round(), Endian.little);
  }
  return bytes;
}

const _quiet = 0.01; // room tone
const _talking = 0.35; // an ordinary speaking voice

void main() {
  group('measuring loudness', () {
    test('silence reads near zero and speech reads clearly above it', () {
      expect(rms(_pcm(0)), lessThan(0.01));
      expect(rms(_pcm(_quiet)), lessThan(0.05));
      expect(rms(_pcm(_talking)), greaterThan(0.15));
    });

    test('a short buffer never divides by zero', () {
      expect(rms(Uint8List(0)), 0);
      expect(rms(Uint8List(1)), 0);
    });

    test('subsampling does not change the answer', () {
      // It runs on the UI thread many times a second — Dart on web has no
      // isolate to move it to — so it reads a fraction of the samples. That
      // shortcut is only acceptable if the number stays the same.
      final loud = _pcm(_talking, ms: 500);
      expect(
        (rms(loud, maxSamples: 256) - rms(loud, maxSamples: 100000)).abs(),
        lessThan(0.02),
      );
    });
  });

  group('ending a turn', () {
    test('keeps listening while someone is talking', () {
      final vad = VoiceActivity();
      for (var i = 0; i < 20; i++) {
        expect(
          vad.onChunk(_pcm(_talking), sampleRate: 16000),
          VoiceVerdict.keepListening,
        );
      }
    });

    test('sends after speech is followed by a real silence', () {
      final vad = VoiceActivity();
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(_talking), sampleRate: 16000);
      }
      // Fed from the threshold rather than a hard-coded count: this test broke
      // when the silence window was widened for learners who pause to find a
      // word, even though the behaviour it checks had not changed at all.
      final chunks = vad.silenceToEnd.inMilliseconds ~/ 100 + 5;
      var verdict = VoiceVerdict.keepListening;
      for (var i = 0; i < chunks && verdict == VoiceVerdict.keepListening; i++) {
        verdict = vad.onChunk(_pcm(_quiet), sampleRate: 16000);
      }
      expect(verdict, VoiceVerdict.endOfTurn);
    });

    test('a pause to reach for a word is not the end of a turn', () {
      // The complaint this window exists for: a learner searching for a word
      // goes quiet for a second or two routinely, and being answered
      // mid-thought costs them the sentence.
      //
      // The bound is a floor, not the value. It was 3000 while the detector
      // measured time wrongly and every setting had to be inflated to
      // compensate; with a real clock, two seconds is two seconds.
      final vad = VoiceActivity();
      expect(vad.silenceToEnd.inMilliseconds, greaterThanOrEqualTo(2000));
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(_talking), sampleRate: 16000);
      }
      // A second and a half of quiet — still mid-thought.
      for (var i = 0; i < 15; i++) {
        expect(
          vad.onChunk(_pcm(_quiet), sampleRate: 16000),
          VoiceVerdict.keepListening,
        );
      }
    });

    test('does not cut off a learner pausing to find a word', () {
      // The load-bearing one. A one-second gap mid-sentence is not the end of
      // a turn — it is a B1 learner reaching for vocabulary, which is exactly
      // the moment this app is for.
      final vad = VoiceActivity();
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(_talking), sampleRate: 16000);
      }
      for (var i = 0; i < 10; i++) {
        expect(
          vad.onChunk(_pcm(_quiet), sampleRate: 16000),
          VoiceVerdict.keepListening,
          reason: 'cut off after ${(i + 1) * 100}ms of thinking',
        );
      }
    });

    test('a cough in an empty room never sends a turn', () {
      // Every send costs an upload, a transcription and a model call, and
      // returns nonsense the learner has to read.
      final vad = VoiceActivity();
      vad.onChunk(_pcm(_talking, ms: 120), sampleRate: 16000);
      var verdict = VoiceVerdict.keepListening;
      for (var i = 0; i < 30 && verdict == VoiceVerdict.keepListening; i++) {
        verdict = vad.onChunk(_pcm(_quiet), sampleRate: 16000);
      }
      expect(verdict, isNot(VoiceVerdict.endOfTurn));
    });

    test('asks for a fresh buffer after a long silence', () {
      // NOT the end of listening. The buffer holds only silence and would
      // grow forever, so the caller swaps it — and keeps the mic open, because
      // there is no button left for a learner to restart it with. Closing here
      // is exactly what stranded people in the first version.
      final vad = VoiceActivity();
      var verdict = VoiceVerdict.keepListening;
      for (var i = 0; i < 600 && verdict == VoiceVerdict.keepListening; i++) {
        verdict = vad.onChunk(_pcm(0), sampleRate: 16000);
      }
      expect(verdict, VoiceVerdict.nothingHeard);
    });

    test('a long silence does not end a turn that had speech in it', () {
      // Someone who spoke and then went quiet gets `endOfTurn`; only a wholly
      // silent window recycles. Confusing the two would drop a real answer.
      final vad = VoiceActivity();
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(_talking), sampleRate: 16000);
      }
      var verdict = VoiceVerdict.keepListening;
      for (var i = 0; i < 600 && verdict == VoiceVerdict.keepListening; i++) {
        verdict = vad.onChunk(_pcm(_quiet), sampleRate: 16000);
      }
      expect(verdict, VoiceVerdict.endOfTurn);
    });

    test('scattered noise never adds up to a turn', () {
      // Reported from real sessions: a sound during a pause made the tutor
      // answer something nobody had said. The detector was summing every loud
      // window into one total, so a keyboard, a passing car and a door reached
      // the threshold in unrelated bursts. Speech is a sustained sound; five
      // fragments are not a sentence.
      final vad = VoiceActivity();
      for (var i = 0; i < 12; i++) {
        vad.onChunk(_pcm(_talking, ms: 100), sampleRate: 16000); // a knock
        for (var q = 0; q < 6; q++) {
          vad.onChunk(_pcm(_quiet, ms: 100), sampleRate: 16000); // 600ms quiet
        }
      }
      expect(vad.heardSpeech, isFalse,
          reason: '12 separate knocks totalled 1.2s and must still not count');
    });

    test('a real sentence is heard even with gaps between words', () {
      // The other side of the same rule: normal speech has short gaps in it,
      // and resetting the run on every one of them would mean nobody is ever
      // heard at all.
      final vad = VoiceActivity();
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(_talking, ms: 100), sampleRate: 16000);
        if (i.isEven) {
          vad.onChunk(_pcm(_quiet, ms: 100), sampleRate: 16000); // between words
        }
      }
      expect(vad.heardSpeech, isTrue);
    });

    test('room tone alone is not mistaken for speech', () {
      final vad = VoiceActivity();
      for (var i = 0; i < 40; i++) {
        vad.onChunk(_pcm(_quiet), sampleRate: 16000);
      }
      expect(vad.heardSpeech, isFalse);
    });

    test('a soft speaker is still heard', () {
      // The worse failure of the two: too high a threshold and a quiet learner
      // is ignored entirely, which reads as the app being broken.
      final vad = VoiceActivity();
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(0.12), sampleRate: 16000);
      }
      expect(vad.heardSpeech, isTrue);
    });

    test('reset clears the previous turn', () {
      final vad = VoiceActivity();
      for (var i = 0; i < 10; i++) {
        vad.onChunk(_pcm(_talking), sampleRate: 16000);
      }
      expect(vad.heardSpeech, isTrue);
      vad.reset();
      expect(vad.heardSpeech, isFalse);
    });
  });
}
