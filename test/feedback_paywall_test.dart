import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/feedback_view.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(FeedbackReport report) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () => showFeedbackSheet(context, report),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  const scores = FeedbackScores(
    grammar: 70,
    vocabulary: 65,
    fluency: 60,
    pronunciation: 55,
    overall: 66,
  );

  testWidgets('locked report shows the teaser error + blur paywall CTA', (
    tester,
  ) async {
    const report = FeedbackReport(
      cefrEstimate: 'B1',
      summary: 'Nice work today.',
      scores: scores,
      errors: [
        FeedbackError(
          original: 'He go to school',
          correction: 'He goes to school',
          type: 'grammar',
          explanation: 'Third person -s',
        ),
      ],
      strengths: [],
      isLocked: true,
    );

    await tester.pumpWidget(host(report));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The one teaser error is real and visible.
    expect(find.text('He goes to school'), findsOneWidget);
    // The paywall sits on the redacted rest of the report, below the fold —
    // scroll the sheet's list to build it.
    await tester.drag(find.text('He goes to school'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Unlock your full report'), findsOneWidget);
    expect(find.text('See plans'), findsOneWidget);
  });

  testWidgets('unlocked report has no paywall and shows deltas', (
    tester,
  ) async {
    const report = FeedbackReport(
      cefrEstimate: 'B1',
      summary: 'Nice work today.',
      scores: scores,
      errors: [],
      strengths: ['Clear answers'],
      isLocked: false,
      scoreDeltas: {'grammar': 7},
    );

    await tester.pumpWidget(host(report));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Unlock your full report'), findsNothing);
    expect(find.text('Clear answers'), findsOneWidget);
    // The grammar improvement arrow value is rendered.
    expect(find.text('7'), findsOneWidget);
  });
}
