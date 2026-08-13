import 'package:edugain/core/live_data.dart';
import 'package:edugain/features/gamification/application/providers.dart';
import 'package:edugain/features/gamification/data/gamification_repository.dart';
import 'package:edugain/features/gamification/domain/leaderboard.dart';
import 'package:edugain/features/gamification/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// XP and this week's rank, kept true without the app being restarted.
///
/// Both were fetched once and then shown forever. The tab shell keeps all four
/// tabs alive in an `IndexedStack` on purpose — instant, lossless switching —
/// which also means nothing behind a tab is ever disposed, `autoDispose` never
/// fires, and a provider read at startup is read exactly once. A full restart
/// was the only event that cleared anything, which is exactly what learners
/// reported: close the bot and reopen it, or the numbers do not move.
///
/// The leaderboard has a second reason: it is other people's XP. It goes stale
/// through nothing but the passage of time, with this learner doing nothing at
/// all.

class _FakeRepo implements GamificationRepository {
  _FakeRepo({this.xp = 100, this.rank = 7});

  int xp;
  int rank;
  int profileCalls = 0;
  int boardCalls = 0;

  @override
  Future<GamificationProfile> profile() async {
    profileCalls += 1;
    return GamificationProfile(
      xp: xp,
      level: 1,
      streak: 1,
      dailyGoalTarget: 50,
      dailyGoalProgress: xp,
    );
  }

  @override
  Future<Leaderboard> leaderboard({bool previous = false}) async {
    boardCalls += 1;
    return Leaderboard(
      top: const [],
      you: Standing(
        rank: rank,
        name: 'Me',
        xp: xp,
        avatarUrl: '',
        streak: 1,
        isYou: true,
      ),
      isPrevious: previous,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Watches both figures so the providers are alive, exactly as a tab does.
class _Board extends ConsumerWidget {
  const _Board();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(gamificationProfileProvider).valueOrNull;
    final board = ref.watch(leaderboardProvider(false)).valueOrNull;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text('xp:${xp?.xp ?? -1}'),
          Text('rank:${board?.you?.rank ?? -1}'),
        ],
      ),
    );
  }
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gamificationRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: _Board()),
    ),
  );
  await tester.pump();
}

void _background(WidgetTester tester) {
  // One state at a time: the framework asserts on the transitions, and a
  // shortcut would be testing something the platform never does.
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  group('coming back to the app', () {
    testWidgets('XP earned elsewhere shows up on resume', (tester) async {
      final repo = _FakeRepo(xp: 100);
      await _pump(tester, repo);
      expect(find.text('xp:100'), findsOneWidget);

      // The bot was backgrounded — a chat, a call, the phone locking — and a
      // lesson was finished on another device in the meantime.
      repo.xp = 340;
      _background(tester);
      await tester.pump();
      await tester.pump();

      expect(repo.profileCalls, 2);
      expect(find.text('xp:340'), findsOneWidget);
    });

    testWidgets('the weekly rank moves without this learner doing anything', (
      tester,
    ) async {
      final repo = _FakeRepo(rank: 7);
      await _pump(tester, repo);
      expect(find.text('rank:7'), findsOneWidget);

      // Somebody else earned XP while the app sat in the background.
      repo.rank = 12;
      _background(tester);
      await tester.pump();
      await tester.pump();

      expect(repo.boardCalls, 2);
      expect(find.text('rank:12'), findsOneWidget);
    });

    testWidgets('merely losing focus refetches nothing', (tester) async {
      // Refetching on every lifecycle wobble would put two endpoints on a hair
      // trigger; only actually coming back is worth the calls.
      final repo = _FakeRepo();
      await _pump(tester, repo);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(repo.profileCalls, 1);
      expect(repo.boardCalls, 1);
    });
  });

  group('the route observer the shell listens on', () {
    testWidgets('reports a pushed screen being popped back off', (
      tester,
    ) async {
      // The shell subscribes to this to know a game or a lesson just closed
      // over it. Its own tabs are never rebuilt by that pop, so without this
      // signal the XP earned inside is invisible until something else happens.
      final observer = appRouteObserver;
      var poppedBack = 0;
      final aware = _Aware(() => poppedBack += 1);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => Scaffold(
              body: _Subscriber(aware: aware, observer: observer),
              floatingActionButton: FloatingActionButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('a game')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('a game'), findsOneWidget);
      expect(poppedBack, 0, reason: 'nothing has come back yet');

      final context = tester.element(find.text('a game'));
      Navigator.of(context).pop();
      await tester.pumpAndSettle();

      expect(poppedBack, 1);
    });
  });
}

class _Aware with RouteAware {
  _Aware(this._onPopNext);
  final VoidCallback _onPopNext;

  @override
  void didPopNext() => _onPopNext();
}

class _Subscriber extends StatefulWidget {
  const _Subscriber({required this.aware, required this.observer});
  final _Aware aware;
  final RouteObserver<ModalRoute<void>> observer;

  @override
  State<_Subscriber> createState() => _SubscriberState();
}

class _SubscriberState extends State<_Subscriber> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) widget.observer.subscribe(widget.aware, route);
  }

  @override
  void dispose() {
    widget.observer.unsubscribe(widget.aware);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('the shell');
}
