import 'package:edugain/core/ui/back_or_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Getting out of a screen a notification opened.
///
/// The bot's messages deep-link straight into the quiz, the partner search and
/// a group room. Arriving that way the tapped route *is* the whole stack, so
/// Flutter draws no back arrow at all — and where one was drawn by hand it
/// called `maybePop()`, which with nothing to pop does nothing. Both looked
/// the same to a learner: no way out but closing the Mini App and reopening
/// it, which is what was reported.
///
/// So the rule is pinned here rather than left to each screen: the way out is
/// always present, and it leads back when there is a back, and home when there
/// is not.
void main() {
  Widget harness(GoRouter router) => MaterialApp.router(routerConfig: router);

  GoRouter build({required String start}) => GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/games',
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.push('/games/quiz'),
              child: const Text('open quiz'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/games/quiz',
        builder: (_, _) => Scaffold(
          appBar: AppBar(leading: const BackOrHome(), title: const Text('quiz')),
          body: const Text('quiz body'),
        ),
      ),
    ],
  );

  testWidgets('a deep-linked screen still has a way out', (tester) async {
    // Straight in, exactly as tapping "Join the quiz" does.
    await tester.pumpWidget(harness(build(start: '/games/quiz')));
    await tester.pumpAndSettle();

    expect(find.text('quiz body'), findsOneWidget);
    // The control exists at all — this is what Flutter would not have drawn.
    expect(find.byType(BackOrHome), findsOneWidget);

    await tester.tap(find.byType(BackOrHome));
    await tester.pumpAndSettle();

    // And it goes somewhere: no back stack, so home.
    expect(find.text('home'), findsOneWidget);
    expect(find.text('quiz body'), findsNothing);
  });

  testWidgets('reached normally, it goes back rather than home', (
    tester,
  ) async {
    await tester.pumpWidget(harness(build(start: '/games')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open quiz'));
    await tester.pumpAndSettle();
    expect(find.text('quiz body'), findsOneWidget);

    await tester.tap(find.byType(BackOrHome));
    await tester.pumpAndSettle();

    // Back to where they came from — not thrown out to home.
    expect(find.text('open quiz'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });
}
