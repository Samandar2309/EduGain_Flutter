import 'dart:async';
import 'dart:typed_data';

import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/audio_recorder.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/speaking_chat_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The microphone must never be held shut by a flag alone.
///
/// It is deliberately kept closed while the tutor speaks, so that it does not
/// record the tutor's own voice back through the speaker. That makes "the
/// tutor is speaking" a gate on the learner being heard at all — and a gate
/// that never opens ends the session without saying so. Typing goes on
/// working, so it reads as the microphone breaking after a turn or two.
///
/// Measured, not imagined: three real Android sessions stopped there. Each one
/// began a server-spoken turn, reported its first audio, and never sent another
/// turn.
///
/// The individual ways to get stuck are fixed where they live — every wait on
/// the playback path is now bounded by the clip's own length. This test covers
/// the guard that does not depend on having found them all.
class _WedgedPlayback extends AudioPlayback {
  /// The failure exactly: a clip that starts and never reports finishing.
  final _never = Completer<void>();

  @override
  final ValueNotifier<double> level = ValueNotifier<double>(0);
  @override
  Future<void> play(Uint8List bytes) => _never.future;
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}
}

class _CountingRecorder implements SpeechRecorder {
  int starts = 0;
  void Function(double, Duration)? _sink;
  Timer? _feed;

  @override
  String lastFallbackReason = '';
  @override
  int get sampleRate => 16000;
  @override
  bool get rateMeasured => true;
  @override
  bool get isDeaf => false;
  @override
  bool get isStalled => false;
  @override
  Duration get sinceLastAudio => Duration.zero;

  @override
  Future<void> start({
    void Function(double level) onLevel = _noLevel,
    void Function(double level, Duration span)? onSpan,
  }) async {
    starts++;
    _sink = onSpan;
    _feed?.cancel();
    // A healthy, quiet room: audio always flows, far below the speech bar, so
    // no turn is ever sent from inside this test.
    _feed = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _sink?.call(0.001, const Duration(milliseconds: 100));
    });
  }

  static void _noLevel(double _) {}

  @override
  Future<void> refreshCapture() async {}
  @override
  Future<AudioClip?> stop({void Function(String stage)? onStage}) async => null;
  @override
  Future<AudioClip?> snapshot() async => null;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> endSession() async => _feed?.cancel();
  @override
  Future<void> dispose() async {}
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> isRecording() async => true;
}

SpeakingLaunch _launch() => SpeakingLaunch(
  title: 'Ordering coffee',
  backdropKey: 'cafe',
  started: StartedSession(
    session: SpeakingSession(
      id: '11111111-1111-1111-1111-111111111111',
      status: 'active',
      turnCount: 1,
      maxTurns: 10,
      quotaRemaining: 3,
    ),
    firstMessage: const ChatMessage(
      role: 'assistant',
      content: 'Hello! What would you like to drink?',
    ),
  ),
);

void main() {
  testWidgets('a tutor that never stops talking still gives the mic back', (
    tester,
  ) async {
    final recorder = _CountingRecorder();
    // The real service, with a player that wedges — so the latch under test is
    // the app's own `speaking` flag, reached the way production reaches it.
    final tts = TtsService(
      serverSpeech: true,
      synthesize: (t, v) async => Uint8List(0),
      playback: _WedgedPlayback(),
      useDevice: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechRecorderProvider.overrideWithValue(recorder),
          ttsServiceProvider.overrideWithValue(tts),
          voicesProvider.overrideWith((ref) async => const <Voice>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: SpeakingChatScreen(launch: _launch()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));

    // The greeting wedges the player. From here the app believes the tutor is
    // talking, and will believe it for ever unless something says otherwise.
    tts.enqueue('Hello! What would you like to drink?');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tts.speaking.value, isTrue, reason: 'the tutor never started');

    final openedBefore = recorder.starts;

    // Long enough that no honest reply could still be playing. Pumped a second
    // at a time because the recovery runs on a periodic timer whose callback
    // awaits, and one long elapse gives those continuations no frames.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(
      tts.speaking.value,
      isFalse,
      reason: 'the tutor is still believed to be talking a minute later',
    );
    expect(
      recorder.starts,
      greaterThan(openedBefore),
      reason: 'the microphone never reopened — the learner cannot be heard',
    );

    // Unmount rather than settle: the listening watchdog is a periodic timer
    // that by design never stops while the screen is up.
    await tester.pumpWidget(const SizedBox());
  });
}
