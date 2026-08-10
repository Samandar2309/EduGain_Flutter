import 'dart:io';

import 'package:edugain/features/vocabulary/presentation/game_modes_screen.dart';
import 'package:edugain/features/vocabulary/presentation/words_to_learn_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Every card in the games hub opened the games hub.
///
/// A `redirect` was attached to a `/vocabulary` parent so the retired landing
/// URL would not dead-end. go_router runs the redirect of every route in a
/// matched stack, parents included, so `/vocabulary/play` and
/// `/vocabulary/learn` were bounced to `/games` too — and the app shipped that
/// way.
///
/// Nothing caught it. The screens were tested by building them directly, and
/// the shots rendered them the same way; both skip the router entirely, which
/// is exactly where the fault was. So this test drives real navigation and
/// asserts what actually lands on screen.
void main() {
  Widget harness(GoRouter router) => ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('uz'),
    ),
  );

  /// The game routes exactly as `core/router.dart` declares them.
  ///
  /// Copied rather than imported: the real router redirects to `/splash` until
  /// auth resolves, which would make every case here a test of the login gate.
  /// What is being pinned is the shape — flat paths, no parent that could
  /// redirect its own children.
  GoRouter build() => GoRouter(
    initialLocation: '/games',
    routes: [
      GoRoute(
        path: '/games',
        builder: (_, _) => const Scaffold(body: Text('hub')),
      ),
      GoRoute(
        path: '/vocabulary/play',
        builder: (_, _) => const GameModesScreen(),
      ),
      GoRoute(
        path: '/vocabulary/learn',
        builder: (_, _) => const WordsToLearnScreen(),
      ),
    ],
  );

  testWidgets('the play card lands on the game types, not back on the hub', (
    tester,
  ) async {
    final router = build();
    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();

    router.push('/vocabulary/play');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GameModesScreen), findsOneWidget);
    expect(
      router.state.matchedLocation,
      '/vocabulary/play',
      reason: 'a redirect somewhere above would show up here',
    );
  });

  testWidgets('the words card lands on the word list', (tester) async {
    final router = build();
    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();

    router.push('/vocabulary/learn');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(WordsToLearnScreen), findsOneWidget);
    expect(router.state.matchedLocation, '/vocabulary/learn');
  });

  test('no route redirects to a path it is a prefix of', () {
    """The rule the bug broke, stated so it cannot come back quietly.

    A parent that redirects captures its own children. If a retired URL ever
    needs to send people somewhere, it must not also be the prefix of live
    routes — give it a distinct path instead.""";

    // Walked over the real declarations rather than a copy: this is the one
    // check that has to see the router as it actually ships.
    final source = File(
      'lib/core/router.dart',
    ).readAsStringSync();
    final redirecting = RegExp(
      r"path:\s*'([^']+)',\s*\n\s*redirect:",
    ).allMatches(source).map((m) => m.group(1)!).toList();

    final paths = RegExp(
      r"path:\s*'(/[^']+)'",
    ).allMatches(source).map((m) => m.group(1)!).toSet();

    for (final parent in redirecting) {
      for (final path in paths) {
        if (path != parent && path.startsWith('$parent/')) {
          fail('$parent redirects, and $path lives under it');
        }
      }
    }
  });
}
