import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/data/speaking_repository.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The minutes a learner sees must be the minutes they have.
///
/// The number is fetched once and then rendered for as long as the screen
/// lives, which is fine until something moves it while nobody is looking. Two
/// things do, and neither is observable from inside a build:
///
///   * the app was in the background — a Telegram Mini App is backgrounded and
///     resumed constantly, and minutes can be spent on another device;
///   * midnight passed on the learner's own clock and the budget refilled.
///
/// Before this, both left the figure frozen until the bot was fully closed and
/// reopened. These tests are what keep it moving.

class _FakeRepo implements SpeakingRepository {
  _FakeRepo(this._quota);

  final SpeakingQuota Function(int call) _quota;
  int calls = 0;

  @override
  Future<SpeakingQuota> quota() async {
    calls += 1;
    return _quota(calls);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SpeakingQuota _quota({int used = 0, int resetsIn = 3600}) => SpeakingQuota(
  sessionsRemaining: 50,
  secondsLimit: 300,
  secondsUsed: used,
  aiUnlocked: true,
  resetsInSeconds: resetsIn,
);

/// A minimal screen that does nothing but watch the budget, so the provider is
/// alive under the tester's clock and its `autoDispose` behaves as in the app.
class _Watcher extends ConsumerWidget {
  const _Watcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(speakingQuotaProvider).valueOrNull;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(q == null ? '...' : '${q.minutesRemaining}'),
    );
  }
}

Future<void> _pumpWatcher(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [speakingRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: _Watcher()),
    ),
  );
  await tester.pump();
}

void main() {
  group('the budget refills without the app being restarted', () {
    testWidgets('midnight refetches on its own', (tester) async {
      // Five minutes spent, one minute of "day" left on the server's clock.
      final repo = _FakeRepo(
        (call) => call == 1
            ? _quota(used: 300, resetsIn: 60)
            : _quota(used: 0, resetsIn: 86400),
      );
      await _pumpWatcher(tester, repo);
      expect(find.text('0'), findsOneWidget, reason: 'the day is spent');

      // Nothing happens early: a timer that fired ahead of the refill would
      // fetch the old figure and schedule another, which is a spin.
      await tester.pump(const Duration(seconds: 55));
      expect(repo.calls, 1);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(repo.calls, 2);
      expect(find.text('5'), findsOneWidget, reason: 'the minutes came back');
    });

    testWidgets('a server that does not say schedules nothing', (tester) async {
      // An older build, or a field that went missing. Treating "no answer" as
      // "now" would refetch immediately, forever.
      final repo = _FakeRepo((_) => _quota(resetsIn: 0));
      await _pumpWatcher(tester, repo);

      await tester.pump(const Duration(hours: 2));
      expect(repo.calls, 1);
    });
  });

  group('coming back to the app', () {
    testWidgets('resuming refetches the budget', (tester) async {
      final repo = _FakeRepo(
        (call) => call == 1 ? _quota(used: 0) : _quota(used: 240),
      );
      await _pumpWatcher(tester, repo);
      expect(find.text('5'), findsOneWidget);

      // Backgrounded — a chat, a call, the phone locking — then back. Walked
      // one state at a time because the framework asserts on the transitions;
      // a shortcut here would test something the platform never does.
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
      await tester.pump();
      await tester.pump();

      expect(repo.calls, 2);
      expect(find.text('1'), findsOneWidget, reason: 'minutes spent elsewhere');
    });

    testWidgets('merely losing focus does not refetch', (tester) async {
      // Refetching on every lifecycle wobble would put the endpoint on a
      // hair trigger; only actually coming back is worth a call.
      final repo = _FakeRepo((_) => _quota());
      await _pumpWatcher(tester, repo);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(repo.calls, 1);
    });
  });

  group('the wire format', () {
    test('the refill countdown is read from the server', () {
      final q = SpeakingQuota.fromJson(const {
        'sessions_remaining': 50,
        'ai_unlocked': true,
        'speaking': {
          'seconds_limit': 300,
          'seconds_used': 120,
          'resets_in_seconds': 7200,
        },
      });
      expect(q.resetsInSeconds, 7200);
      expect(q.secondsRemaining, 180);
      expect(q.minutesRemaining, 3);
    });

    test('an absent countdown reads as "did not say", not as zero time', () {
      final q = SpeakingQuota.fromJson(const {
        'speaking': {'seconds_limit': 300, 'seconds_used': 0},
      });
      expect(q.resetsInSeconds, 0);
    });

    test('the daily budget is five minutes', () {
      // The server owns this number; the client must render whatever it is
      // told rather than assume. Pinned here because a hardcoded default that
      // happened to match would hide a parsing bug.
      final q = SpeakingQuota.fromJson(const {
        'speaking': {'seconds_limit': 300, 'seconds_used': 0},
      });
      expect(q.minutesLimit, 5);
      expect(q.minutesRemaining, 5);
    });
  });
}
