import 'dart:io';
import 'dart:ui' as ui;

import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/application/voice_controller.dart';
import 'package:edugain/features/speaking/data/audio_playback.dart';
import 'package:edugain/features/speaking/data/tts_service.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/speaking_chat_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget coverage for the Speaking chat controls — the surface that had none.
/// Verifies the learner-facing affordances added for people who cannot (or do
/// not want to) speak out loud, and dumps a render for visual review when
/// `VECTOR_DUMP_DIR` is set.
const _openingLine = 'Hi there! What would you like to order today?';

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

SpeakingLaunch _launch({String status = 'active'}) => SpeakingLaunch(
      title: 'Ordering coffee',
      backdropKey: 'cafe',
      started: StartedSession(
        session: SpeakingSession(
          id: '11111111-1111-1111-1111-111111111111',
          status: status,
          turnCount: 1,
          maxTurns: 10,
          quotaRemaining: 3,
        ),
        firstMessage: const ChatMessage(
          role: 'assistant',
          content: _openingLine,
        ),
      ),
    );

/// Records the voice each utterance was rendered in.
final List<String> renderedVoices = [];

Widget _app(
  WidgetRef Function()? _, {
  String status = 'active',
  Future<List<Voice>> Function()? voices,
}) =>
    ProviderScope(
      overrides: [
        ttsServiceProvider.overrideWithValue(
          TtsService(
            synthesize: (t, v) async {
              renderedVoices.add(v);
              return Uint8List(0);
            },
            playback: _SilentPlayback(),
          ),
        ),
        voicesProvider.overrideWith(
          (ref) async => voices == null ? const <Voice>[] : await voices(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('uz'),
        home: RepaintBoundary(
          key: _shot,
          child: SpeakingChatScreen(launch: _launch(status: status)),
        ),
      ),
    );

final _shot = GlobalKey();

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('offers replay, slower and a way to type instead of speaking',
      (tester) async {
    await tester.pumpWidget(_app(null));
    await _settle(tester);
    final l = await AppLocalizations.delegate.load(const Locale('uz'));

    // A learner who missed the line can hear it again — both ways.
    expect(find.text(l.sayAgain), findsOneWidget);
    expect(find.text(l.saySlower), findsOneWidget);
    // …and can answer without speaking out loud.
    expect(find.text(l.switchToTyping), findsOneWidget);
  });

  testWidgets('switching to typing shows a composer and a way back to the mic',
      (tester) async {
    await tester.pumpWidget(_app(null));
    await _settle(tester);
    final l = await AppLocalizations.delegate.load(const Locale('uz'));

    await tester.tap(find.text(l.switchToTyping));
    await _settle(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l.switchToSpeaking), findsOneWidget);

    // The turn is capped where the server caps it, so a long answer cannot be
    // typed only to be rejected.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 500);

    await tester.tap(find.text(l.switchToSpeaking));
    await _settle(tester);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a finished session cannot be continued by typing',
      (tester) async {
    await tester.pumpWidget(_app(null, status: 'completed'));
    await _settle(tester);
    final l = await AppLocalizations.delegate.load(const Locale('uz'));

    // The affordance is visible but inert — tapping must not open a composer
    // for a conversation that is already over.
    await tester.tap(find.text(l.switchToTyping), warnIfMissed: false);
    await _settle(tester);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('render for visual review', (tester) async {
    final dumpDir = Platform.environment['VECTOR_DUMP_DIR'];
    if (dumpDir == null) return;
    Directory(dumpDir).createSync(recursive: true);
    tester.view
      ..physicalSize = const Size(1080, 2160)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final l = await AppLocalizations.delegate.load(const Locale('uz'));
    for (final (name, typing) in [('chat_speak', false), ('chat_type', true)]) {
      await tester.pumpWidget(_app(null));
      await _settle(tester);
      if (typing) {
        await tester.tap(find.text(l.switchToTyping));
        await _settle(tester);
      }
      final img = await _capture(tester);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dumpDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });

  testWidgets('the greeting waits for the voice, so it never changes mid-line',
      (tester) async {
    // The catalogue answers late — exactly the real first-open case that made
    // the opening sentence play in the fallback voice and the next one in the
    // learner's real voice.
    SharedPreferences.setMockInitialValues({});
    renderedVoices.clear();
    await tester.pumpWidget(_app(
      null,
      voices: () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return const [
          Voice(id: 'diana', name: 'Diana', gender: 'female', accent: 'us'),
        ];
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(renderedVoices, isEmpty,
        reason: 'nothing may be spoken before the voice is known');

    // NB: never pumpAndSettle here — the avatar animates continuously, so the
    // tree never goes quiet. Pump explicit frames instead.
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(renderedVoices, isNotEmpty, reason: 'the greeting must still happen');
    expect(renderedVoices.toSet(), {'diana'},
        reason: 'one conversation, one voice');
  });

  testWidgets('the greeting uses the saved voice, not the catalogue default',
      (tester) async {
    // The reported bug: the tutor opened in a woman's voice and only switched
    // to the learner's choice from the second reply. The catalogue resolves
    // fast; the saved choice comes off disk and arrives after it. Defaulting on
    // the catalogue alone picks whoever happens to be listed first.
    SharedPreferences.setMockInitialValues({
      VoiceController.prefsKey: 'troy',
    });
    renderedVoices.clear();
    await tester.pumpWidget(_app(
      null,
      voices: () async => const [
        Voice(id: 'diana', name: 'Diana', gender: 'female', accent: 'us'),
        Voice(id: 'troy', name: 'Troy', gender: 'male', accent: 'us'),
      ],
    ));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(renderedVoices, isNotEmpty, reason: 'the greeting must happen');
    expect(renderedVoices.toSet(), {'troy'},
        reason: "the first word must already be in the voice they chose");
  });

  testWidgets('tapping the bubble hides the line, tapping again brings it back',
      (tester) async {
    // The bubble is the switch: no separate control, and the hidden state says
    // how to undo itself.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(_openingLine), findsOneWidget, reason: 'visible by default');

    await tester.tap(find.text(_openingLine));
    await tester.pump();
    expect(find.text(_openingLine), findsNothing, reason: 'a tap hides it');
    expect(find.text('Ko\u2018rsatish uchun bosing'), findsOneWidget);

    await tester.tap(find.text('Ko\u2018rsatish uchun bosing'));
    await tester.pump();
    expect(find.text(_openingLine), findsOneWidget, reason: 'tapping again shows it');
  });

  testWidgets('the preference is remembered, so the line opens hidden',
      (tester) async {
    SharedPreferences.setMockInitialValues({'speaking.listen_mode': true});
    await tester.pumpWidget(_app(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(_openingLine), findsNothing);
    expect(find.text('Ko\u2018rsatish uchun bosing'), findsOneWidget);
  });
}

Future<ui.Image> _capture(WidgetTester tester) async {
  final ro = _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return ro.toImage(pixelRatio: 1.0);
}
