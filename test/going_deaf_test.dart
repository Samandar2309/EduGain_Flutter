import 'package:edugain/features/speaking/data/capture_health.dart';
import 'package:edugain/features/speaking/data/voice_activity.dart';
import 'package:flutter_test/flutter_test.dart';

/// The microphone that stops hearing the learner while everything looks fine.
///
/// Reported over and over as "after two turns it doesn't hear us". Eight causes
/// were found and fixed and it kept coming back, because every one of them was
/// a cause and none of them was THIS one.
///
/// Production telemetry finally named it: two good turns, then no turn ever
/// again — with `busy_deadlocks: 0`, `speech_deadlocks: 0`, audio still
/// arriving and no error anywhere. Nothing was stuck. The app simply could no
/// longer hear speech.
///
/// Two mechanisms produce exactly that, and both are silent.
void main() {
  group('the bar must stay within reach of a human voice', () {
    test('a loud room cannot raise it past what a person can produce', () {
      // THE BUG. `_maxFloor` capped the floor at 0.2 and the bar is 2.5x the
      // floor, so the bar could reach 0.5 — an RMS a voice does not make. A
      // phone with automatic gain puts ordinary speech near 0.05-0.2 and a
      // shout near 0.3. Past that the app is deaf for the rest of the session.
      final vad = VoiceActivity();
      // Thirteen seconds of unbroken loud room. That crosses `_sustained`,
      // the escape hatch that hands a too-long "run" to the floor — and it is
      // the path that poisons it: the floor jumps straight to 0.19, so the bar
      // would become 0.19 x 2.5 = 0.475 without the cap.
      for (var i = 0; i < 260; i++) {
        vad.onLevel(0.19, const Duration(milliseconds: 50));
      }
      expect(
        vad.speechBar,
        lessThanOrEqualTo(0.22),
        reason: 'the bar climbed past any voice that could answer it',
      );
    });

    test('a normal speaking voice still clears the bar after that room', () {
      final vad = VoiceActivity();
      for (var i = 0; i < 260; i++) {
        vad.onLevel(0.19, const Duration(milliseconds: 50));
      }
      // 0.25 is an ordinary voice raised over a noisy room. It has to register.
      var heard = false;
      for (var i = 0; i < 60; i++) {
        vad.onLevel(0.25, const Duration(milliseconds: 50));
        if (vad.heardSpeech) heard = true;
      }
      expect(heard, isTrue, reason: 'the learner shouted and was not heard');
    });
  });

  group('a room estimate that went wrong can be abandoned', () {
    test('forgetRoom brings the bar back to the floor', () {
      final vad = VoiceActivity();
      for (var i = 0; i < 260; i++) {
        vad.onLevel(0.19, const Duration(milliseconds: 50));
      }
      final poisoned = vad.speechBar;
      expect(poisoned, greaterThan(0.05), reason: 'the room was not poisoned');
      vad.forgetRoom();
      expect(vad.noiseFloor, 0);
      expect(vad.speechBar, lessThan(poisoned));
    });

    test('the estimate survives an ordinary turn, as it is meant to', () {
      // `forgetRoom` must not become "reset every turn" — the floor describes
      // where the learner is sitting and is worth more on turn two than on
      // turn one.
      final vad = VoiceActivity();
      for (var i = 0; i < 40; i++) {
        vad.onLevel(0.03, const Duration(milliseconds: 50));
      }
      final learned = vad.noiseFloor;
      expect(learned, greaterThan(0));
      vad.reset();
      expect(vad.noiseFloor, learned, reason: 'reset threw away the room');
    });

    test('the peak is reported, and is what makes a deaf turn diagnosable', () {
      // Read beside the bar: a peak far below it is the signature of a bar
      // that has run away, and it shows up nowhere else at all.
      final vad = VoiceActivity();
      vad.onLevel(0.08, const Duration(milliseconds: 50));
      vad.onLevel(0.14, const Duration(milliseconds: 50));
      vad.onLevel(0.02, const Duration(milliseconds: 50));
      expect(vad.peakLevel, closeTo(0.14, 0.001));
      vad.reset();
      expect(vad.peakLevel, 0, reason: 'the peak is per turn, not per session');
    });
  });

  group('a track that delivers only silence is not a healthy track', () {
    test('buffers of digital silence are not counted as health', () {
      // The hole the original design could not see: it asked "did audio
      // arrive?", and a muted track arrives — as zeros, several times a second,
      // for ever. Every check answered "healthy" while the learner talked to
      // something that could not hear them.
      var now = DateTime(2026);
      final health = CaptureHealth(now: () => now)..opened();

      for (var i = 0; i < 200; i++) {
        now = now.add(const Duration(milliseconds: 50));
        health.heard(silent: true);
      }
      expect(health.isStalled, isFalse, reason: 'data really is arriving');
      expect(
        health.isDeaf,
        isTrue,
        reason: 'ten seconds of pure silence is a muted track, not a quiet room',
      );
    });

    test('a quiet moment is not mistaken for a dead microphone', () {
      // A learner thinking, or a gap between sentences. Rebuilding the capture
      // under them would drop the words they are about to say.
      var now = DateTime(2026);
      final health = CaptureHealth(now: () => now)..opened();
      for (var i = 0; i < 40; i++) {
        now = now.add(const Duration(milliseconds: 50));
        health.heard(silent: true);
      }
      expect(health.isDeaf, isFalse, reason: 'two seconds is just a pause');
    });

    test('any real sound clears it', () {
      var now = DateTime(2026);
      final health = CaptureHealth(now: () => now)..opened();
      for (var i = 0; i < 200; i++) {
        now = now.add(const Duration(milliseconds: 50));
        health.heard(silent: true);
      }
      expect(health.isDeaf, isTrue);
      health.heard(); // one buffer with sound in it
      expect(health.isDeaf, isFalse);
    });
  });
}
