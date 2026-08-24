import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saying the whole answer, not the first sentence of it.
///
/// The device engine is handed text, not audio, and how that text is cut up
/// decides whether the learner hears all of it. `speechSynthesis` is specified
/// to queue utterances and play them back to back — but a queued utterance is
/// dropped outright on some engines, and a tutor that says one sentence of a
/// five-sentence answer is a far worse failure than a seam between sentences.
///
/// So the rule these hold is: **a reply that arrives all at once becomes ONE
/// utterance.** That closes the seam without depending on the browser's queue,
/// and it is exactly what a burst of `enqueue` calls has to produce.
class _SilentPlayback extends AudioPlayback {
  @override
  final ValueNotifier<double> level = ValueNotifier<double>(0);
  @override
  Future<void> play(Uint8List bytes) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  late List<String> spoken;

  TtsService make() => TtsService(serverSpeech: true, 
    synthesize: (t, v) async => Uint8List(0),
    playback: _SilentPlayback(),
    useDevice: true,
    speakOnDevice: (text, {required rate, onStart, onWord}) async {
      spoken.add(text);
      onStart?.call();
    },
  );

  setUp(() => spoken = <String>[]);

  /// Wait for the tutor to finish, rather than cutting it off.
  ///
  /// `stop()` would cancel the drain — including the microtask it is now
  /// deliberately deferred onto — and a test that cancels the thing it is
  /// measuring measures nothing.
  Future<void> settle(TtsService tts) async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (i > 2 && !tts.speaking.value) return;
    }
  }

  test('a reply queued in one burst is spoken as one utterance', () async {
    // How a reply actually arrives on the device path: the server renders no
    // audio, so every sentence is queued in a single synchronous loop.
    final tts = make();
    tts.beginStream();
    for (final s in const [
      'Nice to meet you.',
      'I work as a nurse.',
      'What about you?',
      'Do you like your job?',
    ]) {
      tts.enqueue(s);
    }
    tts.endStream();
    await settle(tts);

    expect(spoken.length, 1, reason: 'the reply was split across utterances');
    expect(spoken.single, contains('Nice to meet you.'));
    expect(
      spoken.single,
      contains('Do you like your job?'),
      reason: 'the tutor stopped before the end of its answer',
    );
  });

  test('every sentence survives, in order', () async {
    final tts = make();
    for (var i = 1; i <= 6; i++) {
      tts.enqueue('Sentence $i.');
    }
    await settle(tts);

    final said = spoken.join(' ');
    for (var i = 1; i <= 6; i++) {
      expect(said, contains('Sentence $i.'), reason: 'sentence $i was lost');
    }
    expect(said.indexOf('Sentence 1.'), lessThan(said.indexOf('Sentence 6.')));
  });

  test('a sentence that arrives later is still spoken', () async {
    // The streamed case: the drain has run dry and is waiting for more. It must
    // pick the straggler up rather than treat the reply as finished.
    final tts = make();
    tts.beginStream();
    tts.enqueue('First.');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    tts.enqueue('Second.');
    tts.endStream();
    await settle(tts);

    final said = spoken.join(' ');
    expect(said, contains('First.'));
    expect(said, contains('Second.'));
  });

  test('a single line is one utterance, not split by sentence', () async {
    // The opening greeting. Two sentences, one call, and it must not become two
    // utterances with a gap in the middle.
    final tts = make();
    tts.enqueue('Hello there! What would you like to talk about today?');
    await settle(tts);

    expect(spoken.length, 1);
  });
}
