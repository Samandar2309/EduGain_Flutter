import 'package:edugain/core/api/api_exception.dart';
import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/speaking_repository.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/speaking_chat_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tutor's voice now arrives with its words, on the reply stream.
///
/// The screen has to hold two things apart that used to be one: the text it
/// splits into sentences, and the audio the server sends for those sentences.
/// Speaking from both would say every line twice; speaking from neither would
/// leave the tutor silent against an older backend. These tests pin down which
/// one wins, and when.
class _Recorder extends AudioPlayback {
  final List<Uint8List> played = [];

  @override
  final ValueNotifier<double> level = ValueNotifier<double>(0);
  @override
  Future<void> play(Uint8List bytes) async => played.add(bytes);
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}
}

/// Replays a canned turn. Everything else a screen might ask for fails the way
/// a dead network does — which is what the other chat tests already run with.
class _ScriptedRepo implements SpeakingRepository {
  _ScriptedRepo(this._events);

  final List<SpeakingEvent> _events;
  String? voiceAsked;

  @override
  Stream<SpeakingEvent> streamReply(
    String sessionId,
    String text, {
    String? voice,
    String? prerender,
    String? requestId,
  }) async* {
    voiceAsked = voice;
    for (final event in _events) {
      yield event;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw ApiException.network();
}

const _sessionId = '11111111-1111-1111-1111-111111111111';

SpeakingLaunch _launch() => SpeakingLaunch(
      title: 'Ordering coffee',
      backdropKey: 'cafe',
      started: StartedSession(
        session: SpeakingSession(
          id: _sessionId,
          status: 'active',
          turnCount: 1,
          maxTurns: 10,
          quotaRemaining: 3,
        ),
        firstMessage: const ChatMessage(role: 'assistant', content: 'Hello!'),
      ),
    );

SpeakingSession _session() => SpeakingSession(
      id: _sessionId,
      status: 'active',
      turnCount: 2,
      maxTurns: 10,
      quotaRemaining: 3,
    );

Uint8List _clip(String label) => Uint8List.fromList(label.codeUnits);

void main() {
  late _Recorder playback;
  late List<String> fetched;

  Widget app(_ScriptedRepo repo) {
    playback = _Recorder();
    fetched = [];
    return ProviderScope(
      overrides: [
        speakingRepositoryProvider.overrideWithValue(repo),
        ttsServiceProvider.overrideWithValue(
          TtsService(serverSpeech: true, 
            // Standing in for `POST /speaking/tts` — the round trip this whole
            // change exists to remove. Anything recorded here is a sentence the
            // server did not speak for us.
            synthesize: (text, voice) async {
              fetched.add(text);
              return _clip('fetched:$text');
            },
            playback: playback,
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
  }

  /// Take a turn by typing, which drives the same stream handling as speaking
  /// without needing a microphone.
  Future<void> takeTurn(WidgetTester tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('uz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l.switchToTyping));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'A coffee please');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the sentence the server spoke is played, not fetched again',
      (tester) async {
    final repo = _ScriptedRepo([
      const ChunkEvent('Of course.'),
      const ChunkEvent(' Right this way!'),
      AudioEvent(1, 'Of course.', _clip('spoken:1')),
      AudioEvent(2, 'Right this way!', _clip('spoken:2')),
      DoneEvent(_session()),
    ]);
    await tester.pumpWidget(app(repo));
    await takeTurn(tester);

    expect(playback.played, [_clip('spoken:1'), _clip('spoken:2')]);
    expect(fetched, isEmpty, reason: 'the audio was already here');
    // And the server was told which voice to speak in — without that it sends
    // no audio at all, and this test would be passing on an empty stream.
    expect(repo.voiceAsked, isNotNull);
  });

  testWidgets('a sentence the server could not speak is still spoken',
      (tester) async {
    final repo = _ScriptedRepo([
      const ChunkEvent('Of course. Right this way!'),
      AudioEvent(1, 'Of course.', _clip('spoken:1')),
      const AudioEvent(2, 'Right this way!', null), // provider failed on this one
      DoneEvent(_session()),
    ]);
    await tester.pumpWidget(app(repo));
    await takeTurn(tester);

    expect(fetched, ['Right this way!']);
    expect(playback.played, [_clip('spoken:1'), _clip('fetched:Right this way!')]);
  });

  testWidgets('a server that sends no audio at all leaves nothing unsaid',
      (tester) async {
    // An older backend: text only. The tutor must still be heard — silence
    // here would be a version mismatch the learner experiences as a fault.
    final repo = _ScriptedRepo([
      const ChunkEvent('Of course.'),
      const ChunkEvent(' Right this way!'),
      DoneEvent(_session()),
    ]);
    await tester.pumpWidget(app(repo));
    await takeTurn(tester);

    expect(fetched, ['Of course.', 'Right this way!']);
  });

  testWidgets('a stream that breaks part-way still says the rest',
      (tester) async {
    // Audio for the first sentence arrived, then the stream died: the second
    // sentence is ours to say, and only the second.
    final repo = _ScriptedRepo([
      const ChunkEvent('Of course. Right this way!'),
      AudioEvent(1, 'Of course.', _clip('spoken:1')),
      const StreamErrorEvent('AI_UNAVAILABLE', 'down'),
    ]);
    await tester.pumpWidget(app(repo));
    await takeTurn(tester);

    expect(fetched, ['Right this way!']);
    expect(playback.played, [_clip('spoken:1'), _clip('fetched:Right this way!')]);
  });
}
