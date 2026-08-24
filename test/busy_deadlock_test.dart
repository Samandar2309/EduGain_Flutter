import 'dart:async';
import 'dart:typed_data';

import 'package:edugain/core/api/api_exception.dart';
import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/audio_recorder.dart';
import 'package:edugain/features/speaking/data/speaking_repository.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/speaking_chat_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A turn that never ends holds the microphone shut just as surely as a
/// microphone that broke.
///
/// `_busy` means "a turn is in flight", and while it is set the microphone
/// stays closed. Every early exit is supposed to clear it — `_resumeListening`
/// exists so none of them forget — and that is a convention, held in seven
/// places, inside a method that can throw. Its own doc comment names the
/// consequence: *"the flag that, left set, silently ends the conversation."*
///
/// Eight separate causes have now been found for "the microphone stops working
/// after two or three turns". Every fix was correct and none of them could be
/// the last one, because each addressed a cause. This guard addresses the
/// SYMPTOM — the learner unable to speak — and so does not need to know what
/// caused it.
class _StuckRecorder implements SpeechRecorder {
  int starts = 0;
  int refreshes = 0;

  /// `stop()` never returns — the shape of any turn that dies between "a turn
  /// has begun" and the `finally` that would have ended it.
  final _never = Completer<AudioClip?>();

  void Function(double, Duration)? _sink;
  Timer? _feed;

  /// Loud enough to count as speech, until told otherwise.
  double level = 0.4;

  @override
  String lastFallbackReason = '';
  @override
  bool get isDeaf => false;
  @override
  bool get isStalled => false;
  @override
  Duration get sinceLastAudio => Duration.zero;
  @override
  int get sampleRate => 16000;
  @override
  bool get rateMeasured => true;

  @override
  Future<void> start({
    void Function(double level) onLevel = _noLevel,
    void Function(double level, Duration span)? onSpan,
  }) async {
    starts++;
    _sink = onSpan;
    _feed?.cancel();
    _feed = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _sink?.call(level, const Duration(milliseconds: 100));
    });
  }

  static void _noLevel(double _) {}

  @override
  Future<AudioClip?> stop({void Function(String stage)? onStage}) => _never.future;

  @override
  Future<void> refreshCapture() async => refreshes++;
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

class _DeadRepo implements SpeakingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw ApiException.network();
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
  testWidgets('a turn that never ends still gives the microphone back', (
    tester,
  ) async {
    final recorder = _StuckRecorder();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechRecorderProvider.overrideWithValue(recorder),
          speakingRepositoryProvider.overrideWithValue(_DeadRepo()),
          ttsServiceProvider.overrideWithValue(
            TtsService(
              serverSpeech: true,
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
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));

    // Speak, then go quiet: the detector ends the turn, and `stop()` never
    // comes back. From here the screen believes a turn is in flight for ever.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    recorder.level = 0.0005; // silence
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final openedBefore = recorder.starts;

    // Long past any turn that was ever going to arrive. Pumped a second at a
    // time because the guard lives on a periodic timer whose callback awaits.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(
      recorder.starts > openedBefore || recorder.refreshes > 0,
      isTrue,
      reason: 'the turn never ended and the microphone was never handed back — '
          'the learner is mute for the rest of the session',
    );

    // Unmount rather than settle: the watchdog is a periodic timer that by
    // design never stops while the screen is up.
    await tester.pumpWidget(const SizedBox());
  });
}
