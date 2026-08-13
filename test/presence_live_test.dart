import 'package:edugain/core/live_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// "How many learners are online right now", kept true while somebody looks.
///
/// Reported: the peer hub and the group lobby only showed a new count after
/// fully closing and reopening the app. Both were one-shot fetches, so the
/// figure was whatever it had been when the screen happened to load.
///
/// This is the one number in the app that a timer is the right answer for, and
/// the reason is worth keeping straight. XP and rank move a handful of times a
/// day, always because of something this app just did — so they can be re-read
/// when that happens. Presence moves continuously, moves because of strangers,
/// and no event on this device marks it. There is nothing to wake up on.
///
/// It is also the number a learner reads to decide whether waiting for a
/// partner is worth it, so a stale one sends them to an empty queue.

/// Stands in for the hub/lobby endpoint.
final _sourceProvider = Provider<_Source>((_) => _Source());

class _Source {
  int online = 3;
  int calls = 0;

  int read() {
    calls += 1;
    return online;
  }
}

final _onlineProvider = FutureProvider.autoDispose<int>((ref) async {
  refreshEvery(ref, const Duration(seconds: 12));
  return ref.read(_sourceProvider).read();
});

class _Watcher extends ConsumerWidget {
  const _Watcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(_onlineProvider).valueOrNull;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('online:${n ?? -1}'),
    );
  }
}

Future<_Source> _pump(WidgetTester tester) async {
  final source = _Source();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [_sourceProvider.overrideWithValue(source)],
      child: const MaterialApp(home: _Watcher()),
    ),
  );
  await tester.pump();
  return source;
}

void _lifecycle(WidgetTester tester, List<AppLifecycleState> states) {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

const _toBackground = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];
const _toForeground = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

void main() {
  group('the count follows the room, not the app launch', () {
    testWidgets('somebody arriving shows up without a restart', (tester) async {
      final source = await _pump(tester);
      expect(find.text('online:3'), findsOneWidget);

      source.online = 8; // two strangers joined the queue
      await tester.pump(const Duration(seconds: 12));
      await tester.pump();

      expect(source.calls, 2);
      expect(find.text('online:8'), findsOneWidget);
      await tester.pump(const Duration(seconds: 12)); // drain the timer
    });

    testWidgets('it keeps following, not just once', (tester) async {
      final source = await _pump(tester);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 12));
        await tester.pump();
      }
      expect(source.calls, 4, reason: 'the first read plus three ticks');
    });

    testWidgets('nothing is asked before the interval is up', (tester) async {
      final source = await _pump(tester);
      await tester.pump(const Duration(seconds: 11));
      expect(source.calls, 1);
      await tester.pump(const Duration(seconds: 12));
    });
  });

  group('a screen nobody is looking at costs nothing', () {
    testWidgets('the timer stops while the app is in the background', (
      tester,
    ) async {
      // A Mini App left open behind another Telegram chat would otherwise ask
      // forever about a screen nobody can see. Browsers throttle hidden timers
      // but do not stop them, so this cannot be left to the platform.
      final source = await _pump(tester);
      expect(source.calls, 1);

      _lifecycle(tester, _toBackground);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 12));
      }
      expect(source.calls, 1, reason: 'a minute hidden, nothing asked');
    });

    testWidgets('coming back re-reads at once rather than waiting a tick', (
      tester,
    ) async {
      final source = await _pump(tester);
      _lifecycle(tester, _toBackground);
      await tester.pump(const Duration(seconds: 12));
      expect(source.calls, 1);

      source.online = 15;
      _lifecycle(tester, _toForeground);
      await tester.pump();
      await tester.pump();

      expect(source.calls, 2);
      expect(find.text('online:15'), findsOneWidget);
      await tester.pump(const Duration(seconds: 12));
    });

    testWidgets('the timer resumes after coming back', (tester) async {
      final source = await _pump(tester);
      _lifecycle(tester, _toBackground);
      await tester.pump(const Duration(seconds: 12));
      _lifecycle(tester, _toForeground);
      await tester.pump();
      final afterResume = source.calls;

      await tester.pump(const Duration(seconds: 12));
      await tester.pump();
      expect(source.calls, afterResume + 1);
      await tester.pump(const Duration(seconds: 12));
    });

    testWidgets('closing the screen stops it for good', (tester) async {
      final source = await _pump(tester);
      expect(source.calls, 1);

      // Nobody watching -> autoDispose -> the timer must go with it. A leaked
      // one would keep polling for the rest of the session.
      //
      // Same override list, only the child changes: Riverpod refuses a scope
      // whose override COUNT differs between builds, and swapping the whole
      // scope would tear down the container rather than test the provider.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [_sourceProvider.overrideWithValue(source)],
          child: const MaterialApp(home: SizedBox()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));

      expect(source.calls, 1);
    });
  });
}
