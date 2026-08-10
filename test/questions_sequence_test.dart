import 'package:edugain/features/questions/application/providers.dart';
import 'package:edugain/features/questions/domain/models.dart';
import 'package:edugain/features/questions/presentation/questions_sheet.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The browse order: part → topics → questions.
///
/// It has been changed twice — flattened to questions, then put back — so it is
/// pinned here. Each step has to be a step: skipping the topics hides the way
/// the exam is organised, and skipping the parts drops sixty questions into one
/// scroll.
final _bank = [
  QuestionPart(
    id: 'p1',
    title: 'Part 1',
    subtitle: '',
    topics: const [
      QuestionTopic(id: 'home', title: 'Hometown',
          questions: ['Where are you from?']),
      QuestionTopic(id: 'work', title: 'Work', questions: ['Do you work?']),
    ],
  ),
  QuestionPart(
    id: 'p3',
    title: 'Part 3',
    subtitle: '',
    topics: const [
      QuestionTopic(id: 'soc', title: 'Society',
          questions: ['Why do cities grow?']),
    ],
  ),
];

Widget _app({int? partIndex}) => ProviderScope(
      overrides: [
        questionBankProvider.overrideWith((ref) async => _bank),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('uz'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showQuestionsSheet(context, partIndex: partIndex),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the tile grid comes first when no part was named',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Tasodifiy savol'), findsOneWidget);
    // Not straight into anybody's questions.
    expect(find.text('Where are you from?'), findsNothing);
  });

  testWidgets('a named part opens its TOPICS, not its questions',
      (tester) async {
    await tester.pumpWidget(_app(partIndex: 0));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Hometown'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    // The middle step is the point: questions are one tap further on.
    expect(find.text('Where are you from?'), findsNothing);
  });

  testWidgets('a topic then opens its questions', (tester) async {
    await tester.pumpWidget(_app(partIndex: 0));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hometown'));
    await tester.pumpAndSettle();

    expect(find.text('Where are you from?'), findsOneWidget);
    // ...and only that topic's.
    expect(find.text('Do you work?'), findsNothing);
  });

  testWidgets('a named part shows THAT part, not the first one',
      (tester) async {
    await tester.pumpWidget(_app(partIndex: 1));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Society'), findsOneWidget);
    expect(find.text('Hometown'), findsNothing);
  });

  testWidgets('back walks the sequence in reverse', (tester) async {
    await tester.pumpWidget(_app(partIndex: 0));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hometown'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Back from questions lands on the topics, not out of the sheet.
    expect(find.text('Hometown'), findsOneWidget);
    expect(find.text('Where are you from?'), findsNothing);
  });
}
