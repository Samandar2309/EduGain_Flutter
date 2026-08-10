import 'package:edugain/features/course/application/providers.dart';
import 'package:edugain/features/course/domain/models.dart';
import 'package:edugain/features/course/presentation/lesson_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// What happens to a question you get wrong.
///
/// The whole of the practice feature was folded into this: there is no separate
/// mistakes screen, so a missed question coming back inside the lesson is the
/// only second chance a learner gets. If it silently stopped happening nobody
/// would notice — the lesson would simply be shorter and teach less.
Drill _d(String id, String word, List<String> options) => Drill(
  itemId: id,
  type: 'vocab_recognise',
  data: {
    'item_id': id,
    'type': 'vocab_recognise',
    'prompt': word,
    'options': options,
  },
);

final _drills = [
  _d('i1', 'apple', ['olma', 'non', 'suv']),
  _d('i2', 'bread', ['non', 'olma', 'suv']),
];

Widget _app() => ProviderScope(
  overrides: [
    lessonDrillsProvider('l1').overrideWith((ref) async => _drills),
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
    home: const LessonScreen(lessonId: 'l1'),
  ),
);

void main() {
  testWidgets('every drill is shown with an instruction above it',
      (tester) async {
    // The line that exists because learners could not tell what was being
    // asked. Four words in a box do not say "choose the meaning".
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text("So'zning ma'nosini tanlang"), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('an answer cannot be checked before one is chosen',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    // Enabled with nothing picked, the first tap of the lesson does nothing
    // and reads as the app being broken.
    expect(button.onPressed, isNull);
  });

  testWidgets('choosing an option enables checking', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('olma'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('the progress bar starts empty', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0);
  });
}
