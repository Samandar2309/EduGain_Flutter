/// Whether the microphone is still delivering audio.
///
/// This exists because of the one microphone failure that has no symptom. A
/// browser does not report it: the track mutes, or the audio context the
/// capture worklet runs on is suspended — by the speech engine speaking, by a
/// spell in the background, by memory pressure in a WebView — and the stream
/// neither ends nor errors. Every handle is still non-null, every flag still
/// says "listening", and no audio will ever arrive again.
///
/// It cannot be prevented, only noticed, and it can only be noticed by asking
/// the question no flag can fake: **has any audio arrived recently?** That is
/// the whole of this class.
///
/// The distinction it draws is between an open capture and a *working* one.
/// "Nobody is talking" and "the microphone stopped existing" look identical
/// from every other angle — silence still arrives, as chunks of silence — and
/// telling them apart is what lets the app rebuild the one and leave the other
/// alone.
class CaptureHealth {
  CaptureHealth({
    this.stallAfter = const Duration(milliseconds: 1500),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Longer than any gap a working capture leaves between deliveries.
  ///
  /// The web path delivers many times a second and native reports amplitude
  /// every 120 ms, so a second and a half of nothing is never a quiet room.
  /// Short enough that a learner notices at most a beat; long enough that a
  /// browser scheduling hiccup is not mistaken for a dead device.
  final Duration stallAfter;

  final DateTime Function() _now;

  /// When audio last arrived, or null when no capture is open.
  ///
  /// Null is a third state, not a missing second one: a capture that is closed
  /// is not stalled, and a healer that could not tell those apart would rebuild
  /// in a loop for as long as the app was idle.
  DateTime? _lastAudio;

  /// A capture was just opened. It counts as healthy from this moment, so the
  /// stall window measures from the open and not from some earlier session —
  /// a stream that never delivers a single chunk has to age like one that
  /// stopped delivering, since to the learner they are the same failure.
  void opened() {
    _lastAudio = _now();
    _lastSound = _now();
  }

  /// Audio arrived. Called from the raw delivery callback, BEFORE any decision
  /// about whether this turn is keeping it: this measures the microphone, not
  /// the conversation.
  ///
  /// [silent] says the buffer contained no sound at all — see [_lastSound].
  void heard({bool silent = false}) {
    final now = _now();
    _lastAudio = now;
    if (!silent) _lastSound = now;
  }

  /// When a buffer last contained anything other than digital silence.
  ///
  /// The hole in the original design, and the one this class was least able to
  /// see. It asked "did audio arrive?" — and a track the browser has muted
  /// still arrives, as buffers of zeros, several times a second, for ever. Every
  /// question this class knew how to ask answered "healthy" while the learner
  /// talked to something that could not hear them.
  ///
  /// A real microphone never returns silence this pure. Even an empty room has
  /// a noise floor; even a muted room has dither. Exact, sustained zero is not
  /// quiet — it is disconnected.
  DateTime? _lastSound;

  /// How long only silence has been arriving.
  Duration get sinceSound {
    final at = _lastSound;
    return at == null ? Duration.zero : _now().difference(at);
  }

  /// Delivering, but delivering nothing. Longer than [stallAfter] because this
  /// one has to survive a genuinely quiet moment: a learner thinking, a gap
  /// between sentences. Eight seconds of ABSOLUTE silence, with the app
  /// listening, is a track that has been muted.
  static const deafAfter = Duration(seconds: 8);

  bool get isDeaf => _lastSound != null && sinceSound > deafAfter;

  void closed() {
    _lastAudio = null;
    _lastSound = null;
  }

  bool get isOpen => _lastAudio != null;

  /// How long the capture has been delivering nothing; zero when closed.
  Duration get sinceLastAudio {
    final at = _lastAudio;
    return at == null ? Duration.zero : _now().difference(at);
  }

  /// Open, but silent for longer than any working capture ever is.
  bool get isStalled {
    final at = _lastAudio;
    return at != null && _now().difference(at) > stallAfter;
  }
}
