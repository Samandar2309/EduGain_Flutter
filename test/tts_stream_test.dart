import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tutor being cut off halfway through its reply.
///
/// The reply is written sentence by sentence, so the queue runs dry *between*
/// sentences. The player treated an empty queue as "the turn is over": it
/// dropped `speaking`, and the screen — which re-opens the microphone the
/// moment the tutor stops — opened it mid-answer. Learners heard the first
/// sentence or two and nothing else.
class _Recorder extends AudioPlayback {
  final List<Uint8List> played = [];
  final ValueNotifier<double> _level = ValueNotifier<double>(0);

  @override
  ValueListenable<double> get level => _level;

  @override
  Future<void> play(Uint8List bytes) async => played.add(bytes);

  @override
  Future<void> stop() async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async => _level.dispose();
}

void main() {
  late _Recorder playback;
  late TtsService tts;

  setUp(() {
    playback = _Recorder();
    tts = TtsService(serverSpeech: true, 
      synthesize: (text, voice) async => Uint8List.fromList(text.codeUnits),
      playback: playback,
    );
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a gap between sentences does not end the turn', () async {
    tts.beginStream();
    tts.enqueue('First sentence.');
    await settle();
    expect(tts.speaking.value, isTrue);

    // The queue is empty here — the model is still writing. This is the exact
    // moment the turn used to be declared over.
    await settle();
    expect(
      tts.speaking.value,
      isTrue,
      reason: 'still streaming, so the gap is a pause and not the end',
    );

    tts.enqueue('Second sentence.');
    await settle();
    tts.endStream();
    await settle();
    await settle();

    expect(playback.played.length, 2);
    expect(tts.speaking.value, isFalse);
  });

  test('the turn ends once the stream is closed and the queue drains', () async {
    tts.beginStream();
    tts.enqueue('Only one.');
    tts.endStream();
    await settle();
    await settle();
    expect(playback.played.length, 1);
    expect(tts.speaking.value, isFalse);
  });

  test('without a stream, an empty queue still ends the turn', () async {
    // Replays and the greeting enqueue without opening a stream; they must not
    // hold the turn open waiting for text that will never come.
    tts.enqueue('A single line.');
    await settle();
    await settle();
    expect(tts.speaking.value, isFalse);
  });

  test('stop() releases a drain parked between sentences', () async {
    // The deadlock this latch could have introduced: `stop()` awaits the drain,
    // and a drain waiting for a sentence that never arrives would never return.
    tts.beginStream();
    tts.enqueue('Interrupted.');
    await settle();
    await tts.stop().timeout(const Duration(seconds: 2));
    expect(tts.speaking.value, isFalse);
  });

  test('dispose() also releases a parked drain', () async {
    tts.beginStream();
    tts.enqueue('Goodbye.');
    await settle();
    await tts.dispose().timeout(const Duration(seconds: 2));
  });

  test('a stream that never closes is ended by stop, not left hanging', () async {
    tts.beginStream();
    tts.enqueue('One.');
    await settle();
    expect(tts.speaking.value, isTrue);
    await tts.stop().timeout(const Duration(seconds: 2));
    expect(tts.speaking.value, isFalse);
  });
}
