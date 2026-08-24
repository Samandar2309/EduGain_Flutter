import 'dart:async';
import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pressing Finish must end the session, whatever the tutor is doing.
///
/// Finishing goes quiet first — microphone closed, tutor stopped — and that
/// courtesy used to be able to swallow the whole action. `TtsService.stop()`
/// waits for the speech queue to unwind, and a queue parked on a clip that
/// never reports finishing never unwinds. The button then did nothing at all:
/// no request left the phone, no error appeared, nothing on screen changed.
///
/// Measured over thirty-six hours of production: thirty-two spoken turns
/// reached the server and **not one session ending**.
class _WedgedPlayback extends AudioPlayback {
  final _neverPlays = Completer<void>();
  final _neverStops = Completer<void>();

  @override
  final ValueNotifier<double> level = ValueNotifier<double>(0);

  /// A clip that starts and never reports finishing.
  @override
  Future<void> play(Uint8List bytes) => _neverPlays.future;

  /// And a player that will not even admit to stopping — the call most likely
  /// to be wedged is the one asking a wedged player to stop.
  @override
  Future<void> stop() => _neverStops.future;

  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  test('stop() returns even when the player never does', () async {
    final tts = TtsService(
      serverSpeech: true,
      synthesize: (t, v) async => Uint8List(0),
      playback: _WedgedPlayback(),
      useDevice: false,
    );

    tts.enqueue('Nice to meet you.');
    // Let the drain reach the wedged player.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(tts.speaking.value, isTrue, reason: 'the tutor never started');

    // The real assertion is that this completes at all. A generous ceiling:
    // the point is bounded, not fast.
    await tts.stop().timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail('stop() never returned — Finish would hang here'),
    );

    expect(
      tts.speaking.value,
      isFalse,
      reason: 'the tutor is still believed to be talking after stop()',
    );
  });

  test('a following turn can still speak after a wedged one', () async {
    // The same `stop()` runs at the START of every turn. A wedged clip must
    // not take the rest of the conversation with it.
    final spoken = <String>[];
    final tts = TtsService(
      serverSpeech: true,
      synthesize: (t, v) async {
        spoken.add(t);
        return Uint8List(0);
      },
      playback: _WedgedPlayback(),
      useDevice: false,
    );

    tts.enqueue('The wedged one.');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tts.stop().timeout(const Duration(seconds: 10));

    tts.enqueue('The one after it.');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      spoken,
      contains('The one after it.'),
      reason: 'the conversation died with the clip that wedged',
    );
  });
}
