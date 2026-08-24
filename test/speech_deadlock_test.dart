
import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tutor that never stops talking is a microphone that never opens.
///
/// The microphone is deliberately held shut while the tutor speaks, so it does
/// not record the tutor's own voice back through the speaker. That makes "the
/// tutor is speaking" a gate on the learner being heard at all. A clip whose
/// completion never arrives holds that gate closed for the rest of the
/// session — and because typing keeps working, it reads as the microphone
/// breaking after a turn or two rather than as anything to do with speech.
///
/// Three real Android sessions ended exactly there: playback started, the turn
/// reported its first audio, and no further turn was ever sent.
void main() {
  group('a clip is only ever owed its own length', () {
    test('the budget is measured from the audio, not guessed', () {
      // One value per frame at [envelopeFps], so the envelope's length IS the
      // clip's duration — the one measure of it that cannot lie.
      final threeSeconds = List<double>.filled(envelopeFps * 3, 0.5);
      final budget = playbackBudget(threeSeconds);

      expect(
        budget,
        greaterThan(const Duration(seconds: 3)),
        reason: 'a clip must be allowed to finish playing',
      );
      expect(
        budget,
        lessThan(const Duration(seconds: 15)),
        reason: 'three seconds of audio cannot honestly take this long',
      );
    });

    test('a longer clip is given proportionally longer', () {
      final short = playbackBudget(List<double>.filled(envelopeFps * 2, 0.5));
      final long = playbackBudget(List<double>.filled(envelopeFps * 20, 0.5));
      expect(long, greaterThan(short));
      // Still a ceiling, not a wish: twenty seconds of speech, not two minutes.
      expect(long, lessThan(const Duration(seconds: 45)));
    });

    test('audio that could not be parsed is still bounded', () {
      // Length genuinely unknown — a provider returned something other than the
      // PCM WAV it usually does. Long enough never to cut a sentence short,
      // short enough that the session recovers by itself.
      final budget = playbackBudget(const <double>[]);
      expect(budget, const Duration(seconds: 60));
      expect(budget.inMinutes, lessThanOrEqualTo(1), reason: 'unbounded again');
    });
  });
}
