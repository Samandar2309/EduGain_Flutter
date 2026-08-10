import 'dart:math' as math;
import 'dart:typed_data';

/// Decides when a spoken turn has ended, so nobody has to press anything.
///
/// The rule is deliberately generous in one direction and strict in the other.
/// Ending a turn too early cuts someone off mid-thought, which is worse than
/// any delay; sending a turn that contains no speech costs real money (upload,
/// transcription, a model call) and returns nonsense the learner then has to
/// read. So: a long silence is required to end, and speech has to have been
/// heard at all before ending is even considered.
class VoiceActivity {
  VoiceActivity({
    this.threshold = 0.05,
    // Two seconds — long enough to reach for a word, short enough that the
    // reply does not feel late.
    //
    // Every earlier value here was chosen under a broken clock: the detector
    // was told a flat 120 ms had passed on every reading while on the web they
    // arrive several times faster, so a "1.6 second" window behaved like about
    // half a second and was raised to three to compensate. The clock is
    // measured properly now, which makes those old numbers meaningless — and a
    // real three seconds, plus a second to transcribe and a second to answer,
    // is five seconds of a learner waiting.
    this.silenceToEnd = const Duration(seconds: 2),
    this.minSpeech = const Duration(milliseconds: 500),
    this.maxSilenceBeforeGivingUp = const Duration(seconds: 30),
  });

  /// Loudness (0..1 RMS) above which a window counts as speech.
  ///
  /// Back at the level that demonstrably worked: twenty-seven real turns went
  /// through at 0.055, and raising it stopped every one of them.
  ///
  /// The defence against noise is the run rule below, not this number. Pushed
  /// high enough to reject a busy room, it also makes the app deaf to a quiet
  /// learner — and being ignored after speaking is the worse failure by far,
  /// because it reads as broken rather than as strict.
  final double threshold;

  /// How long it must stay quiet before the turn is sent.
  ///
  /// Three seconds. It was 1.6s, and learners were being cut off mid-sentence:
  /// a non-native speaker hunting for a word pauses for two or three seconds
  /// routinely, which is precisely the person this product exists for.
  ///
  /// The two failures are not equal. Ending early breaks the conversation — the
  /// tutor answers half a thought and the learner feels misheard. Waiting too
  /// long is merely slow. So when in doubt this errs towards waiting, and the
  /// cost is about a second and a half of quiet at the end of each turn.
  final Duration silenceToEnd;

  /// How long speech must run CONTINUOUSLY before a turn may be sent.
  ///
  /// Continuously, not in total — that distinction is the fix. Summed across a
  /// window, five unrelated 100 ms noises reached the old threshold and sent a
  /// clip containing no speech at all. Nobody talks in fragments that short; a
  /// sentence is a sustained sound.
  final Duration minSpeech;

  /// How long a wholly silent recording may run before it is swapped for a
  /// fresh one.
  ///
  /// This is a memory bound, not a decision to stop listening: the buffer only
  /// holds silence, and 30s of it is about a megabyte. Recycling far more
  /// often would be worse than the leak it prevents — each swap tears the
  /// media stream down and back up, and a word spoken in that gap is lost.
  final Duration maxSilenceBeforeGivingUp;

  /// How long a gap may last before it breaks the run.
  ///
  /// Generous, and that is the correction: speech is not a steady tone. A
  /// vowel is loud and the consonant after it can drop below any threshold, so
  /// requiring an unbroken 700 ms above the line meant a real sentence never
  /// qualified and nothing was ever sent. Zero turns reached the server for
  /// forty minutes.
  ///
  /// Half a second still separates a sentence from scattered knocks — those
  /// are seconds apart — while leaving the dips inside ordinary words alone.
  static const _runGap = Duration(milliseconds: 500);

  /// The current unbroken run of speech.
  Duration _run = Duration.zero;

  /// The longest unbroken run seen this turn — what `heardSpeech` judges.
  Duration _longestRun = Duration.zero;
  Duration _silence = Duration.zero;
  Duration _total = Duration.zero;

  bool get heardSpeech => _longestRun >= minSpeech;

  void reset() {
    _run = Duration.zero;
    _longestRun = Duration.zero;
    _silence = Duration.zero;
    _total = Duration.zero;
  }

  /// Feed one chunk of PCM-16 audio. Returns what should happen next.
  VoiceVerdict onChunk(Uint8List pcm16, {required int sampleRate}) {
    final frames = pcm16.length ~/ 2;
    if (frames == 0) return VoiceVerdict.keepListening;
    final elapsed = Duration(
      microseconds: (frames / sampleRate * 1e6).round(),
    );
    return onLevel(rms(pcm16), elapsed);
  }

  /// The same decision from a level that was measured elsewhere — native
  /// platforms report amplitude instead of handing over the samples.
  VoiceVerdict onLevel(double level, Duration elapsed) {
    _total += elapsed;
    if (level >= threshold) {
      _run += elapsed;
      if (_run > _longestRun) _longestRun = _run;
      _silence = Duration.zero;
      return VoiceVerdict.keepListening;
    }
    // A gap breaks the run. Short gaps happen inside real speech — between
    // words — so the run only resets once the quiet has lasted longer than
    // that, otherwise every sentence would be scored as a string of fragments.
    _silence += elapsed;
    if (_silence >= _runGap) _run = Duration.zero;
    if (heardSpeech && _silence >= silenceToEnd) {
      return VoiceVerdict.endOfTurn;
    }
    // Nothing has been said for a long while. The caller swaps the buffer
    // for a fresh one and keeps listening — this is a memory bound, not the
    // end of the learner's turn.
    if (!heardSpeech && _total >= maxSilenceBeforeGivingUp) {
      return VoiceVerdict.nothingHeard;
    }
    return VoiceVerdict.keepListening;
  }
}

enum VoiceVerdict {
  keepListening,

  /// Speech happened and has now stopped — send it.
  endOfTurn,

  /// Nothing has been said for a long while. Recycle the buffer and carry on
  /// listening; ending here would strand a learner who has no button to press.
  nothingHeard,
}

/// Root-mean-square loudness of a little-endian PCM-16 buffer, 0..1.
///
/// Subsampled for the same reason the lip-sync envelope is: this runs on the
/// UI thread — Dart on web has no isolate to move it to — and reading every
/// sample of every chunk, many times a second, is what makes an app stutter
/// while someone is speaking into it.
double rms(Uint8List pcm16, {int maxSamples = 256}) {
  final frames = pcm16.length ~/ 2;
  if (frames == 0) return 0;
  final view = ByteData.sublistView(pcm16);
  final stride = math.max(1, frames ~/ maxSamples);
  var sumSq = 0.0;
  var n = 0;
  for (var i = 0; i < frames; i += stride) {
    final v = view.getInt16(i * 2, Endian.little) / 32768.0;
    sumSq += v * v;
    n++;
  }
  return n == 0 ? 0 : math.sqrt(sumSq / n);
}
