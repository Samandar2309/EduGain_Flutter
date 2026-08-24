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

/// Recovering from a microphone that stopped without saying so.
///
/// The bug this covers was reported three times in the same words: after a
/// couple of turns the app stops hearing the learner, while typing still works.
/// The cause is a capture that is open and delivering nothing — a muted track,
/// a suspended audio context — which no browser reports and no flag reveals.
/// Nothing in the app noticed, so the learner talked to a screen that would
/// never answer.
///
/// So the app stops trusting its flags and watches the audio itself. These
/// tests hold that watch in place: it must rebuild when the capture goes quiet,
/// it must NOT rebuild while audio is flowing, and it must not rebuild between
/// turns when there is deliberately no capture at all.
class _FakeRecorder implements SpeechRecorder {
  /// Delivering nothing while still open — the failure with no symptom.
  bool stalled = false;

  /// The device refuses to open at all.
  bool startThrows = false;

  int refreshes = 0;
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
  bool get isStalled => stalled;

  @override
  Duration get sinceLastAudio =>
      stalled ? const Duration(seconds: 5) : Duration.zero;

  @override
  Future<void> start({
    void Function(double level) onLevel = _noLevel,
    void Function(double level, Duration span)? onSpan,
  }) async {
    starts++;
    if (startThrows) throw StateError('device busy');
    _sink = onSpan;
    _feed?.cancel();
    // A healthy capture delivers constantly, silence included. The level is
    // far below the speech threshold on purpose: this is a quiet room, not a
    // learner talking, so no turn is ever sent from inside these tests.
    _feed = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (stalled) return; // a stalled capture delivers nothing at all
      _sink?.call(0.001, const Duration(milliseconds: 100));
    });
  }

  @override
  Future<void> refreshCapture() async {
    refreshes++;
    stalled = false; // a rebuild gives back a working capture
  }

  static void _noLevel(double _) {}

  @override
  Future<AudioClip?> stop({void Function(String stage)? onStage}) async => null;
  @override
  Future<AudioClip?> snapshot() async => null;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> endSession() async {
    _feed?.cancel();
  }

  @override
  Future<void> dispose() async {}
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> isRecording() async => true;
}

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

Widget _app(_FakeRecorder recorder) => ProviderScope(
  overrides: [
    speechRecorderProvider.overrideWithValue(recorder),
    ttsServiceProvider.overrideWithValue(
      TtsService(serverSpeech: true, 
        synthesize: (t, v) async => Uint8List(0),
        playback: _SilentPlayback(),
        useDevice: false,
      ),
    ),
    voicesProvider.overrideWith((ref) async => const <Voice>[]),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('uz'),
    home: SpeakingChatScreen(launch: _launch()),
  ),
);

void main() {
  testWidgets('a capture that goes quiet is rebuilt without being asked', (
    tester,
  ) async {
    final recorder = _FakeRecorder();
    await tester.pumpWidget(_app(recorder));
    await tester.pump(const Duration(seconds: 1));
    // The microphone opens by itself — the learner presses nothing.
    await tester.pump(const Duration(seconds: 3));
    final openedBefore = recorder.starts;
    expect(openedBefore, greaterThan(0), reason: 'never started listening');

    // The track mutes. Nothing errors; audio simply stops arriving.
    recorder.stalled = true;
    await tester.pump(const Duration(seconds: 2));

    expect(recorder.refreshes, greaterThan(0), reason: 'never rebuilt');
    await tester.pump(const Duration(seconds: 3));
    expect(
      recorder.starts,
      greaterThan(openedBefore),
      reason: 'rebuilt but never reopened — the learner is still unheard',
    );
    // Unmount rather than settle: the listening watchdog is a periodic timer
    // that by design never stops while the screen is up.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a working capture is left alone', (tester) async {
    final recorder = _FakeRecorder();
    await tester.pumpWidget(_app(recorder));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 10));
    // Ten seconds of a healthy microphone. Rebuilding one of those drops the
    // audio the learner is in the middle of speaking.
    expect(recorder.refreshes, 0);
    // Unmount rather than settle: the listening watchdog is a periodic timer
    // that by design never stops while the screen is up.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a device that fails AFTER working is retried, not written off', (
    tester,
  ) async {
    // A transient failure used to latch the "allow the microphone" wall, which
    // nothing clears but a button most learners never find — one of the ways
    // speaking died after two turns despite permission having been granted at
    // the start of the very same conversation.
    final recorder = _FakeRecorder();
    await tester.pumpWidget(_app(recorder));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2)); // it works: audio flows
    final workedFor = recorder.starts;

    // Now the device starts refusing, the way a WebView does under pressure.
    recorder
      ..stalled = true
      ..startThrows = true;
    // Pumped a second at a time, not in one long jump: the retry lives on a
    // periodic timer whose callback awaits, and a single large elapse does not
    // give those continuations the frames they need.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        ).micPermission,
      ),
      findsNothing,
    );
    expect(
      recorder.starts,
      greaterThan(workedFor + 2),
      reason: 'gave up after the first failure instead of retrying',
    );
    expect(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        ).micPermission,
      ),
      findsNothing,
      reason: 'showed a permission wall for a permission already granted',
    );
    // Unmount rather than settle: the listening watchdog is a periodic timer
    // that by design never stops while the screen is up.
    await tester.pumpWidget(const SizedBox());
  });
}
