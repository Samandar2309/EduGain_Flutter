@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/features/course/application/providers.dart';
import 'package:edugain/features/course/domain/models.dart';
import 'package:edugain/features/course/presentation/path_screen.dart';
import 'package:edugain/features/course/presentation/lesson_screen.dart';
import 'package:edugain/features/course/presentation/unit_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the course path so it can be looked at.
///
///     flutter test test/course_path_shot_test.dart --tags shot --run-skipped --update-goldens
UnitNode _u(int n, String title, UnitState state, {int mastery = 0}) => UnitNode(
  id: 'u$n',
  number: '$n',
  title: title,
  grammar: title,
  vocab: 'Salomlashish',
  state: state,
  mastery: mastery,
  maxMastery: 5,
  lessonsDone: 0,
  lessonCount: 3,
  isPremium: state == UnitState.premium,
);

final _levels = [
  CourseLevel(
    id: 'c1',
    slug: 'course-a1',
    title: 'Beginner 1',
    subtitle: 'A1',
    cefrLevel: 'A1',
    percent: 25,
    units: [
      _u(1, 'Present Simple', UnitState.done, mastery: 3),
      _u(2, 'Present Continuous', UnitState.done, mastery: 1),
      _u(3, 'Artikllar: a / an / the', UnitState.done, mastery: 2),
      _u(4, "Ko'plik (Plural)", UnitState.done, mastery: 1),
      _u(5, 'There is / There are', UnitState.current),
      _u(6, "Can / Can't", UnitState.locked),
      _u(7, 'Verb to be', UnitState.locked),
      _u(8, 'have got', UnitState.premium),
    ],
  ),
  CourseLevel(
    id: 'c2',
    slug: 'course-a2',
    title: 'Beginner 2',
    subtitle: 'A2',
    cefrLevel: 'A2',
    percent: 0,
    units: [
      _u(1, 'Past Simple', UnitState.locked),
      _u(2, 'Comparatives', UnitState.locked),
    ],
  ),
];


const _unit = UnitDetail(
  id: 'u5',
  number: '5',
  title: 'There is / There are',
  grammar: 'There is / There are',
  explanation:
      "**There is** — bitta narsa uchun, **There are** — bir nechta narsa uchun "
      "ishlatiladi. Masalan: There is a book on the table. There are two books "
      "on the table. Savol qilishda so'z tartibi almashadi: Is there a book?",
  vocab: 'Uy va xona',
  mastery: 2,
  lessons: [
    LessonRef(id: 'l1', index: 0, itemCount: 8, state: LessonState.done),
    LessonRef(id: 'l2', index: 1, itemCount: 8, state: LessonState.current),
    LessonRef(id: 'l3', index: 2, itemCount: 6, state: LessonState.locked),
  ],
);

final _drills = [
  Drill(itemId: 'i1', type: 'vocab_recognise', data: const {
    'item_id': 'i1',
    'type': 'vocab_recognise',
    'prompt': 'delicious',
    'options': ['mazali', 'menyu', 'och', 'achchiq'],
    'example': 'This soup is delicious.',
  }),
  Drill(itemId: 'i2', type: 'grammar_reorder', data: const {
    'item_id': 'i2',
    'type': 'grammar_reorder',
    'prompt': 'Gapni tuzing',
    'tiles': ['There', 'is', 'a', 'book', 'on', 'the', 'table'],
  }),
];

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final f = FontLoader('MaterialIcons')
        ..addFont(Future.value(
            File(iconFont).readAsBytesSync().buffer.asByteData()));
      await f.load();
    }
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(Future.value(
            File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  });

  Widget app(Widget home, List<Override> overrides) => ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          // Wrapped in a Navigator so `context.canPop()` has something to
          // answer — the screen offers a way out, and a shot has to render the
          // same widget the app does.
          home: Navigator(onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => home)),
        ),
      );

  testWidgets('the course path', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      const CoursePathScreen(),
      [coursePathProvider.overrideWith((ref) async => _levels)],
    ));
    // Explicit frames, never pumpAndSettle: the "start" callout bobs for ever,
    // so settling never happens and the shot is never taken. Enough of them to
    // carry the 420ms scroll-to-current animation to its end.
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    await expectLater(
      find.byType(CoursePathScreen),
      matchesGoldenFile('shots/course_path.png'),
    );
  });

  testWidgets('a unit', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      const UnitScreen(unitId: 'u5'),
      [unitDetailProvider('u5').overrideWith((ref) async => _unit)],
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(UnitScreen),
      matchesGoldenFile('shots/course_unit.png'),
    );
  });

  testWidgets('a lesson question', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      const LessonScreen(lessonId: 'l2'),
      [lessonDrillsProvider('l2').overrideWith((ref) async => _drills)],
    ));
    await tester.pumpAndSettle();

    // Pick an option, so the shot shows the state a learner is actually in
    // when they are about to press Check.
    await tester.tap(find.text('mazali'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LessonScreen),
      matchesGoldenFile('shots/course_lesson.png'),
    );
  });

  testWidgets('the word-tile question', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(
      const LessonScreen(lessonId: 'l3'),
      [lessonDrillsProvider('l3').overrideWith((ref) async => [_drills[1]])],
    ));
    await tester.pumpAndSettle();
    for (final word in ['There', 'is', 'a', 'book']) {
      await tester.tap(find.text(word).last);
      await tester.pumpAndSettle();
    }

    await expectLater(
      find.byType(LessonScreen),
      matchesGoldenFile('shots/course_lesson_tiles.png'),
    );
  });
}
