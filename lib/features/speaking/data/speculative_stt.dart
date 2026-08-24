import 'dart:async';
import 'dart:typed_data';

/// Transcribing the learner's answer during the pause, instead of after it.
///
/// When somebody stops talking the detector waits two seconds before committing
/// the turn, in case they were only reaching for a word. The utterance is
/// already complete by then — those two seconds are spent doing nothing at all,
/// and they are the largest single item in the wait before the tutor answers.
///
/// This fills them. The moment the silence begins, the clip so far is sent to be
/// transcribed. If the learner resumes, the result is thrown away and nothing
/// has been lost but one request. If the turn commits, the transcript is already
/// waiting and the turn skips transcription entirely.
///
/// **It is a shortcut, never a dependency.** Every path through this class ends
/// with the caller able to fall back to the ordinary upload: a failure, a
/// timeout, an unsupported platform and a resumed sentence all look the same
/// from outside — `useSnapshot` is false and the turn proceeds as it always did.
///
/// The generation counter is what keeps turns apart. A speculation belongs to
/// the silence that started it; anything that ends that silence — the learner
/// resuming, the turn committing, the screen closing — moves the generation on,
/// and a late reply for a superseded generation is discarded rather than
/// attached to whatever turn happens to be current. That is the race this class
/// exists to make impossible.
class SpeculativeStt {
  SpeculativeStt({required this.transcribe, this.maxPerTurn = 3});

  /// Sends a clip to be transcribed ahead of the turn. Completes normally when
  /// the server has cached the transcript; throws on anything else.
  final Future<void> Function(Uint8List bytes, String filename) transcribe;

  /// How many speculations one turn may pay for.
  ///
  /// A hesitant learner who pauses repeatedly would otherwise buy a
  /// transcription per pause. Three covers the ordinary "…umm… and then…"
  /// answer; past that the turn simply waits like it used to, which is slower
  /// but free.
  final int maxPerTurn;

  int _generation = 0;
  int _spent = 0;
  _Attempt? _current;

  /// Whether a speculation is in flight or finished for the current silence.
  bool get isActive => _current != null;

  /// Test/diagnostic view of how many were paid for in this turn.
  int get attemptsThisTurn => _spent;

  /// Begin transcribing [clip] during the grace period.
  ///
  /// Does nothing when one is already running for this silence, when the turn
  /// has spent its budget, or when the caller had no snapshot to give.
  void begin(Uint8List bytes, String filename) {
    if (_current != null || _spent >= maxPerTurn) return;
    final generation = _generation;
    _spent++;
    final attempt = _Attempt(bytes: bytes, filename: filename);
    _current = attempt;
    // The future is held, not awaited. Errors are captured onto the attempt so
    // nothing here can surface as an unhandled exception in a turn that was
    // otherwise fine.
    attempt.done = transcribe(bytes, filename).then(
      (_) {
        if (generation == _generation) attempt.ok = true;
      },
      onError: (Object _) {
        if (generation == _generation) attempt.ok = false;
      },
    );
  }

  /// The learner started speaking again — this speculation is not about the
  /// turn that will eventually be sent, so it is abandoned.
  ///
  /// The request itself is left to finish: there is no way to un-send it, and
  /// its only effect is a cache entry keyed by audio that will never be
  /// uploaded again. Moving the generation on is what guarantees the answer
  /// cannot be mistaken for the next turn's.
  void discard() {
    _generation++;
    _current = null;
  }

  /// A new turn is starting: forget everything, including the spend budget.
  void reset() {
    discard();
    _spent = 0;
  }

  /// The bytes to upload for the committed turn, or null to use the ordinary
  /// recording.
  ///
  /// Returns the speculated clip ONLY once the server has confirmed it
  /// transcribed — which also proves those exact bytes are decodable, so the
  /// turn is never sent audio that has not already been read successfully. A
  /// speculation still in flight is waited for, because it is nearly always
  /// closer than starting again; a failed or missing one yields null and the
  /// caller uploads the full recording exactly as before.
  Future<Uint8List?> settle({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final attempt = _current;
    if (attempt == null) return null;
    final generation = _generation;
    try {
      await attempt.done?.timeout(timeout);
    } catch (_) {
      // A timeout or a failure both mean "do not trust it".
    }
    // Superseded while we waited — the learner resumed, or the screen closed.
    if (generation != _generation) return null;
    // `ok` is null until the server has answered — unknown is not yes.
    return attempt.ok == true ? attempt.bytes : null;
  }

  /// The filename that belongs to the settled bytes, so the extension the
  /// recogniser reads for the codec stays the one that was actually recorded.
  String? get filename => _current?.filename;
}

class _Attempt {
  _Attempt({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
  Future<void>? done;

  /// Null until the server has answered: unknown, not "no".
  bool? ok;
}
