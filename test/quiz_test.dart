import 'package:edugain/features/quiz/application/quiz_controller.dart';
import 'package:edugain/features/quiz/data/quiz_repository.dart';
import 'package:edugain/features/quiz/domain/models.dart';
import 'package:edugain/features/quiz/presentation/quiz_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The live quiz screen.
///
/// A match now has a beginning, so the screen has two jobs: get people into a
/// lobby, then run the game. What is pinned here is what a player could
/// exploit or be confused by — the correct answer must not be on screen while
/// the round is open, one tap must send exactly one answer, a lobby must never
/// claim more people than are in it, and somebody opening the app at question
/// six must get a playable screen rather than a waiting room.
///
/// The repository is faked rather than the HTTP layer, because what is being
/// tested is what the screen does with an answer — not how it was fetched.
class _FakeRepo implements QuizRepository {
  _FakeRepo(this._state);

  final QuizState _state;
  int answers = 0;
  int starts = 0;
  int readies = 0;

  @override
  Future<QuizState> state() async => _state;

  @override
  Future<QuizLive> live() async => QuizLive.none;

  @override
  Future<void> start() async => starts += 1;

  @override
  Future<void> ready({bool leave = false}) async => readies += 1;

  @override
  Future<QuizVerdict> answer({
    required int match,
    required int index,
    required int choice,
  }) async {
    answers += 1;
    return const QuizVerdict(correct: true, correctIndex: 1, points: 140);
  }
}

QuizState _state({
  required QuizPhase phase,
  int index = 0,
  int? correct,
  double remaining = 12,
  List<QuizSeat> players = const [],
  int needed = 0,
  bool youReady = false,
  String hostName = '',
}) => QuizState(
  match: 42,
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
    kind: 'grammar',
    prompt: 'He ___ to school every day.',
    options: const ['go', 'goes', 'going', 'gone'],
    correct: correct,
    note: correct == null ? '' : 'Uchinchi shaxs: -s.',
  ),
  matchBoard: const QuizBoard(
    top: [QuizPlayer(rank: 1, name: 'Malika', points: 280, isYou: false)],
  ),
);

void main() {
  Widget harness(_FakeRepo repo) => ProviderScope(
    overrides: [quizRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('uz'),
      home: const QuizScreen(),
    ),
  );

  Future<void> settle(WidgetTester tester) =>
      tester.pumpAndSettle(const Duration(milliseconds: 400));

  // ── getting in ────────────────────────────────────────────────────────────
  testWidgets('with nothing running, the screen offers to start a game', (
    tester,
  ) async {
    final repo = _FakeRepo(_state(phase: QuizPhase.idle, needed: 2));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text('Viktorinani boshlash'), findsWidgets);
    // No question is shown, because there is no match.
    expect(find.text('He ___ to school every day.'), findsNothing);

    await tester.tap(find.text('Viktorinani boshlash').last);
    await tester.pump();
    expect(repo.starts, 1);

    await settle(tester);
  });

  testWidgets('a lobby says how many more are needed, and who is here', (
    tester,
  ) async {
    final repo = _FakeRepo(
      _state(
        phase: QuizPhase.lobby,
        needed: 1,
        hostName: 'Malika',
        players: const [QuizSeat(name: 'Malika', isYou: false)],
      ),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text('Yana 1 kishi kerak'), findsOneWidget);
    expect(find.text('Malika'), findsWidgets);
    expect(find.text('Tayyorman'), findsOneWidget);

    await settle(tester);
  });

  testWidgets('pressing ready sends exactly one ready', (tester) async {
    final repo = _FakeRepo(_state(phase: QuizPhase.lobby, needed: 1));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    await tester.tap(find.text('Tayyorman'));
    await tester.pump();
    expect(repo.readies, 1);

    await settle(tester);
  });

  testWidgets('somebody already in the lobby has nothing left to press', (
    tester,
  ) async {
    final repo = _FakeRepo(
      _state(phase: QuizPhase.lobby, needed: 1, youReady: true),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text("Siz o'yindasiz"), findsOneWidget);
    await tester.tap(find.text("Siz o'yindasiz"));
    await tester.pump();
    // The button is inert, not a second way to join.
    expect(repo.readies, 0);

    await settle(tester);
  });

  testWidgets('a lobby never shows a player nobody is behind', (tester) async {
    // Presence is real or it is nothing. The seats come from the server's
    // pruned set, so an empty lobby draws no seats at all.
    final repo = _FakeRepo(_state(phase: QuizPhase.lobby, needed: 2));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text('LOBBIDA'), findsNothing);

    await settle(tester);
  });

  // ── playing ───────────────────────────────────────────────────────────────
  testWidgets('the answer is not on screen while the round is open', (
    tester,
  ) async {
    // `correct` is null exactly as the server sends it during answering.
    final repo = _FakeRepo(_state(phase: QuizPhase.answer));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text('He ___ to school every day.'), findsOneWidget);
    for (final option in ['go', 'goes', 'going', 'gone']) {
      expect(find.text(option), findsOneWidget);
    }
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await settle(tester);
  });

  testWidgets('the answer is shown once the round has closed', (tester) async {
    final repo = _FakeRepo(_state(phase: QuizPhase.reveal, correct: 1));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('Uchinchi shaxs: -s.'), findsOneWidget);

    await settle(tester);
  });

  testWidgets('tapping an option sends exactly one answer', (tester) async {
    final repo = _FakeRepo(_state(phase: QuizPhase.answer));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    await tester.tap(find.text('goes'));
    await tester.pump();
    // A second tap must not reach the server; the round is spent.
    await tester.tap(find.text('going'), warnIfMissed: false);
    await tester.pump();

    expect(repo.answers, 1);

    await settle(tester);
  });

  testWidgets('opening at question six gives a playable screen, not a lobby', (
    tester,
  ) async {
    final repo = _FakeRepo(_state(phase: QuizPhase.answer, index: 5));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text('He ___ to school every day.'), findsOneWidget);
    expect(find.text('goes'), findsOneWidget);

    await settle(tester);
  });

  testWidgets('between matches the boards take the screen', (tester) async {
    final repo = _FakeRepo(_state(phase: QuizPhase.result, remaining: 12));
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    expect(find.text("O'yin tugadi"), findsOneWidget);
    expect(find.text('Malika'), findsWidgets);

    await settle(tester);
  });
}
