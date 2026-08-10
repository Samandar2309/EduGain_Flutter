@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/games/presentation/games_hub_screen.dart';
import 'package:edugain/features/quiz/application/quiz_controller.dart';
import 'package:edugain/features/quiz/data/quiz_repository.dart';
import 'package:edugain/features/quiz/domain/models.dart';
import 'package:edugain/features/quiz/presentation/quiz_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// What the live quiz actually looks like.
///
///     flutter test test/quiz_shot_test.dart --tags shot --run-skipped --update-goldens
class _ShotRepo implements QuizRepository {
  _ShotRepo(this._state, {this.summary = QuizLive.none});

  final QuizState _state;
  final QuizLive summary;

  @override
  Future<QuizState> state() async => _state;

  @override
  Future<QuizLive> live() async => summary;

  @override
  Future<void> start() async {}

  @override
  Future<void> ready({bool leave = false}) async {}

  @override
  Future<QuizVerdict> answer({
    required int match,
    required int index,
    required int choice,
  }) async => const QuizVerdict(correct: true, correctIndex: 1, points: 143);
}

QuizBoard _board() => const QuizBoard(
  top: [
    QuizPlayer(rank: 1, name: 'Malika', points: 412, isYou: false),
    QuizPlayer(rank: 2, name: 'Aziz', points: 388, isYou: false),
    QuizPlayer(rank: 3, name: 'Siz', points: 275, isYou: true),
    QuizPlayer(rank: 4, name: 'Nodira', points: 240, isYou: false),
    QuizPlayer(rank: 5, name: 'Jasur', points: 196, isYou: false),
  ],
  you: QuizPlayer(rank: 3, name: 'Siz', points: 275, isYou: true),
);

QuizState _state({
  required QuizPhase phase,
  String prompt = '',
  List<String> options = const [],
  String kind = '',
  int index = 2,
  int? correct,
  String note = '',
  double remaining = 11,
  List<QuizSeat> players = const [],
  int needed = 0,
  bool youReady = false,
  String hostName = '',
}) => QuizState(
  match: 4821,
  phase: phase,
  remaining: remaining,
  index: index,
  total: 8,
  players: players,
  needed: needed,
  hostName: hostName,
  youReady: youReady,
  minPlayers: 2,
  question: QuizQuestion(
    kind: kind,
    prompt: prompt,
    options: options,
    correct: correct,
    note: note,
  ),
  matchBoard: _board(),
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
          Future.value(File(path).readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()),
        );
      await icons.load();
    }
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget home, {
    QuizRepository? repo,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (repo != null) quizRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: AppColors.canvas,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
            appBarTheme: const AppBarTheme(
              titleTextStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: home,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('hub, with a lobby waiting for one more', (tester) async {
    await shoot(
      tester,
      'quiz_hub',
      const GamesHubScreen(),
      repo: _ShotRepo(
        _state(phase: QuizPhase.lobby),
        summary: const QuizLive(
          playing: 1,
          live: true,
          running: false,
          hostName: 'Malika',
          needed: 1,
        ),
      ),
    );
  });

  testWidgets('nothing running — the screen offers to start one', (
    tester,
  ) async {
    await shoot(
      tester,
      'quiz_idle',
      const QuizScreen(),
      repo: _ShotRepo(_state(phase: QuizPhase.idle, needed: 2)),
    );
  });

  testWidgets('a lobby waiting for one more player', (tester) async {
    await shoot(
      tester,
      'quiz_lobby',
      const QuizScreen(),
      repo: _ShotRepo(
        _state(
          phase: QuizPhase.lobby,
          needed: 1,
          youReady: true,
          hostName: 'Malika',
          players: const [
            QuizSeat(name: 'Malika', isYou: false),
            QuizSeat(name: 'Siz', isYou: true),
          ],
        ),
      ),
    );
  });

  testWidgets('a grammar question, open', (tester) async {
    await shoot(
      tester,
      'quiz_answer',
      const QuizScreen(),
      repo: _ShotRepo(
        _state(
          phase: QuizPhase.answer,
          kind: 'grammar',
          prompt: 'Look! The baby ___ now.',
          options: const ['sleeps', 'is sleeping', 'slept', 'sleep'],
          players: const [
            QuizSeat(name: 'Malika', isYou: false),
            QuizSeat(name: 'Siz', isYou: true),
            QuizSeat(name: 'Aziz', isYou: false),
          ],
        ),
      ),
    );
  });

  // Rendered as somebody who let the clock run out sees it — the verdict block
  // reads "time up" rather than a score. Naming it otherwise would make the
  // screenshot a claim the code does not make.
  testWidgets('the reveal, seen by somebody who did not answer', (
    tester,
  ) async {
    await shoot(
      tester,
      'quiz_reveal',
      const QuizScreen(),
      repo: _ShotRepo(
        _state(
          phase: QuizPhase.reveal,
          kind: 'grammar',
          prompt: 'Look! The baby ___ now.',
          options: const ['sleeps', 'is sleeping', 'slept', 'sleep'],
          correct: 1,
          note: "Hozir davom etyapti: is + fe'l-ing.",
          remaining: 3,
        ),
      ),
    );
  });

  testWidgets('between matches — the podium', (tester) async {
    await shoot(
      tester,
      'quiz_result',
      const QuizScreen(),
      repo: _ShotRepo(
        _state(phase: QuizPhase.result, kind: 'grammar', remaining: 14),
      ),
    );
  });
}
