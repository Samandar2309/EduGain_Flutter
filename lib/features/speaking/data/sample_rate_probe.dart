/// The capture's true sample rate, measured from the audio rather than assumed.
///
/// The app asks `getUserMedia` for 16 kHz and then believed it got it, in six
/// places: the WAV header it writes, the duration it reports for each loudness
/// reading, and the silence it trims off each end.
///
/// A browser is free to refuse. `record_web` builds its `AudioContext` at the
/// **track's** rate, not the requested one — so when the constraint is honoured
/// the assumption holds, and when it is ignored every one of those six places
/// is wrong by the same factor, silently.
///
/// Android Chrome honours it, which is why this never showed up. Safari and the
/// iOS WKWebView that Telegram Mini Apps run in are the documented case that
/// does not: they hand back the device rate, typically 48 kHz. Three times too
/// many samples, described by a header that says 16 kHz, produces
///
///   * a recording the transcriber hears at a third of speed, deep and slurred,
///     which comes back as nonsense or as nothing;
///   * a silence detector told that every reading covers three times the time
///     it really does, so a turn ends after a third of the intended pause —
///     the learner is cut off mid-sentence, every sentence.
///
/// Neither failure looks like a sample rate. Both look like "it doesn't work on
/// iPhone".
///
/// Measuring costs nothing: the frames are already arriving and the clock is
/// already running. Counting them is the one answer that cannot be refused.
library;

/// Rates a capture device actually runs at. A measurement lands near one of
/// these and is snapped to it, so ordinary jitter in chunk delivery cannot
/// leave the header a few hertz out.
const List<int> standardRates = [8000, 16000, 22050, 24000, 32000, 44100, 48000];

/// Snap [measured] to the nearest plausible rate, or null when it is nowhere
/// near one — a wild reading means the measurement is not ready, not that the
/// device runs at 19 kHz.
int? snapToStandardRate(double measured) {
  if (measured <= 0) return null;
  var best = standardRates.first;
  var bestGap = (measured - best).abs();
  for (final rate in standardRates.skip(1)) {
    final gap = (measured - rate).abs();
    if (gap < bestGap) {
      best = rate;
      bestGap = gap;
    }
  }
  // Within 15%: enough to absorb bursty delivery, tight enough that 16 k and
  // 24 k can never be mistaken for one another.
  return bestGap / best <= 0.15 ? best : null;
}

/// Watches the arriving audio and reports the rate it is really coming in at.
class SampleRateProbe {
  SampleRateProbe({this.requested = 16000, Duration Function()? elapsed})
      : _elapsed = elapsed ?? _stopwatchClock();

  static Duration Function() _stopwatchClock() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  /// What was asked for, and what is reported until enough audio has arrived to
  /// say otherwise. Being wrong for the first second is harmless — the WAV
  /// header is written when a turn ENDS, by which time this has settled.
  final int requested;

  final Duration Function() _elapsed;

  int _frames = 0;

  /// When the FIRST chunk arrived — not when this object was built.
  ///
  /// The distinction is the whole measurement. A capture is negotiated before
  /// it delivers: `getUserMedia`, an `AudioContext`, a worklet. Counting that
  /// dead time as though audio had been flowing through it halves the answer —
  /// measured on a real phone, a 16 kHz stream reported 8 kHz, which is a
  /// header describing audio at half speed and a silence detector cutting every
  /// learner off in half the intended pause.
  Duration? _openedAt;

  int? _measured;

  /// Long enough for bursty delivery to average out. A capture delivers many
  /// times a second, so this is a fraction of the first turn.
  static const _minWindow = Duration(milliseconds: 800);

  /// Audio arrived. [frames] is samples per channel, not bytes.
  void heard(int frames) {
    if (frames <= 0) return;
    final now = _elapsed();
    final opened = _openedAt;
    if (opened == null) {
      // The window opens here. This chunk's frames are NOT counted: they were
      // captured before the window existed, and counting them against a span
      // that starts now would overstate the rate as badly as the old code
      // understated it.
      _openedAt = now;
      return;
    }
    _frames += frames;
    final span = now - opened;
    if (span < _minWindow) return;
    final seconds = span.inMicroseconds / 1e6;
    if (seconds <= 0) return;
    final snapped = snapToStandardRate(_frames / seconds);
    if (snapped != null) _measured = snapped;
  }

  /// The rate to write into headers and to divide durations by.
  int get rate => _measured ?? requested;

  /// Whether the answer is still the assumption. Reported with the turn, so a
  /// device that never settles is visible rather than mysterious.
  bool get isMeasured => _measured != null;

  /// A fresh capture is a fresh measurement — a rebuilt stream can come back at
  /// a different rate than the one that died.
  void reset() {
    _frames = 0;
    _openedAt = null;
    _measured = null;
  }
}
