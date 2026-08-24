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

  /// The FLOOR under which nothing is ever treated as speech, 0..1 RMS.
  ///
  /// Back at the level that demonstrably worked: twenty-seven real turns went
  /// through at 0.055, and raising it stopped every one of them. So it is not
  /// raised — it is now a floor rather than the whole rule, with the room's own
  /// noise lifting the bar on top of it (see [_speechBar]).
  ///
  /// A fixed number cannot do this job alone. It was set for one quiet room; in
  /// a louder one the same value sits *below* the hiss, so the hiss reads as
  /// speech and gets uploaded — which is exactly how a turn came back
  /// transcribed as words nobody said. Pushed high enough to reject that room,
  /// it makes the app deaf to a quiet learner, and being ignored after speaking
  /// is the worse failure by far, because it reads as broken rather than strict.
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

  /// How far above the room's own noise a window must sit to *start* being
  /// speech, and how far above it to *keep* a turn alive. Two numbers, not one,
  /// and the gap between them is the whole design: strict about deciding
  /// somebody began talking, generous about deciding they have not finished.
  ///
  /// One number cannot be both. Strict, and a learner who drops their voice at
  /// the end of a sentence is cut off; generous, and a fan or a television
  /// holds the turn open forever. Since the two mistakes are made at different
  /// moments, they get different bars.
  static const _speechOverFloor = 2.5;
  static const _keepAliveOverFloor = 1.4;

  /// The room, as heard between words: a running estimate of its noise.
  ///
  /// Deliberately NOT cleared by [reset]. It describes where the learner is
  /// sitting, not what they just said, and it is worth more at the start of the
  /// second turn than it was at the start of the first. It rises slowly (so one
  /// loud word cannot make the app deaf) and falls fast (so leaving a noisy
  /// room restores sensitivity within a breath).
  double _floor = 0;

  /// The loudest reading of the current turn — see [peakLevel].
  double _peak = 0;

  /// Capped, because a floor that runs away deafens the app completely — the
  /// one failure this must never produce, whatever the microphone reports.
  static const _maxFloor = 0.2;

  /// How much room the estimate has been fed. Not per turn — see [_floor].
  Duration _learned = Duration.zero;

  /// How long the estimate converges hard before it starts being protected.
  static const _settling = Duration(milliseconds: 600);

  bool get _settled => _learned >= _settling;

  /// Longer than any human says in one unbroken breath.
  ///
  /// This is the escape hatch for the one trap an adaptive threshold falls
  /// into, and it is worth naming because it is not obvious. The floor may only
  /// learn from what is NOT speech — otherwise a soft learner's own voice
  /// teaches the app that they are the room, and it goes deaf to them. But in a
  /// room whose hiss already clears [threshold], that hiss is classified as
  /// speech, so it never teaches the floor, so it stays classified as speech:
  /// the estimate can never discover the room it is sitting in.
  ///
  /// Level cannot break that tie — a quiet learner and a loud room are the same
  /// number. Time can. Speech stops; a room does not. A "run" of speech that
  /// has gone on this long without a single half-second dip is not a person, so
  /// it is handed to the floor and struck from the record — those readings were
  /// scored against a bar the app now knows was wrong.
  static const _sustained = Duration(seconds: 12);

  /// The loudest a speech bar may ever be.
  ///
  /// This is the guard that was missing, and its absence is the whole bug.
  /// `_maxFloor` capped the FLOOR at 0.2, and the bar is 2.5x the floor — so
  /// the bar could reach **0.5**, an RMS a human voice does not produce. A
  /// phone microphone with automatic gain puts an ordinary speaking voice
  /// around 0.05-0.2 and a shout near 0.3.
  ///
  /// Once the bar passed what the learner could reach, the app was deaf for the
  /// rest of the session — and deaf in the way that is hardest to see: audio
  /// still arriving, no error anywhere, every flag healthy, and simply no turn
  /// ever ending again. Measured in production as exactly two good turns
  /// followed by silence, with all three deadlock guards reading zero.
  ///
  /// 0.22 sits above any room this has to survive and below any voice it has to
  /// hear. Capping the floor was not enough; the thing that must be reachable
  /// is the bar.
  static const _maxSpeechBar = 0.22;

  double get _speechBar => math.min(
        _maxSpeechBar,
        math.max(threshold, _floor * _speechOverFloor),
      );
  double get _keepAliveBar =>
      math.max(threshold * 0.6, _floor * _keepAliveOverFloor);

  /// The current unbroken run of speech.
  Duration _run = Duration.zero;

  /// The longest unbroken run seen this turn — what `heardSpeech` judges.
  Duration _longestRun = Duration.zero;
  Duration _silence = Duration.zero;
  Duration _total = Duration.zero;

  bool get heardSpeech => _longestRun >= minSpeech;

  /// How long it has been quiet, as this detector counts it.
  ///
  /// Observation only — nothing here decides anything, and the value is exactly
  /// the counter [onLevel] was already keeping. It is exposed because the moment
  /// this rises from zero is the moment the learner actually stopped talking,
  /// and that is the start of the only latency number that matters. Reading it
  /// from outside is the alternative to a second silence counter that could
  /// disagree with this one.
  ///
  /// Note it resets when the keep-alive band is cleared — a trailing syllable
  /// restarts the grace period — so the rising edge that survives to
  /// [VoiceVerdict.endOfTurn] is the true end of speech, not the first pause.
  Duration get silence => _silence;

  void reset() {
    _peak = 0;
    _run = Duration.zero;
    _longestRun = Duration.zero;
    _silence = Duration.zero;
    _total = Duration.zero;
  }

  /// Nothing was heard for a whole turn. Stop believing the room estimate.
  ///
  /// The floor is deliberately kept across turns — it describes where the
  /// learner is sitting. That is right while it is right, and it is exactly
  /// wrong once it has climbed past the learner's own voice, because from then
  /// on every turn hears nothing and every turn teaches it nothing. It is
  /// self-sealing: the only readings that could correct it are the ones it is
  /// now rejecting.
  ///
  /// A turn that heard no speech at all is the evidence that breaks the seal.
  /// A real microphone in a real room, with a learner talking at it, does not
  /// produce nothing — so the estimate, not the learner, is what is wrong.
  void forgetRoom() {
    _floor = 0;
    _learned = Duration.zero;
  }

  /// The current estimate and the bar it implies, for telemetry. A session that
  /// went deaf should say so in numbers rather than as "it stopped hearing me".
  double get noiseFloor => _floor;
  double get speechBar => _speechBar;

  /// The loudest thing heard this turn. Read together with [speechBar]: a peak
  /// well below the bar is the signature of a bar that has run away.
  double get peakLevel => _peak;

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
    if (level > _peak) _peak = level;
    final speechBar = _speechBar;
    if (level >= speechBar) {
      _run += elapsed;
      if (_run >= _sustained) {
        // Not a person (see [_sustained]). Hand it to the floor and forget it.
        _floor = level.clamp(0.0, _maxFloor);
        _learned = Duration.zero;
        _run = Duration.zero;
        _longestRun = Duration.zero;
        return VoiceVerdict.keepListening;
      }
      if (_run > _longestRun) _longestRun = _run;
      _silence = Duration.zero;
      return VoiceVerdict.keepListening;
    }
    // Below the bar, so it is the room and not the learner: this is the only
    // thing the estimate is allowed to learn from. Gating it the other way —
    // folding in everything — lets a soft speaker's own voice become the floor,
    // and the app goes deaf to exactly the person it was widened for.
    _trackFloor(level, elapsed);
    if (level >= _keepAliveBar) {
      // Too quiet to be called the start of speech, too loud to call the room
      // empty — a trailing syllable, a word said towards the floor. It does not
      // extend the run, but it does stop the clock that ends the turn. This is
      // what stops a learner being cut off for finishing a sentence softly.
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

  /// Fold one reading into the noise estimate.
  ///
  /// Asymmetric on purpose, and the three rates are the whole estimator.
  /// Rising is the dangerous direction — it raises the bar the learner has to
  /// clear — so in steady state it is done a hair at a time: a few seconds of
  /// somebody talking moves it a little, and the pause afterwards undoes that
  /// within half a second, because falling only ever makes the app more
  /// sensitive and so is done quickly. From cold there is nothing to protect
  /// yet and everything to learn, so it converges hard for the first moment.
  void _trackFloor(double level, Duration elapsed) {
    final rate = level < _floor
        ? 0.3
        : _settled
            ? 0.002
            : 0.4;
    _floor = (_floor + (level - _floor) * rate).clamp(0.0, _maxFloor);
    if (!_settled) _learned += elapsed;
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
