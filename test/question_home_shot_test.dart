@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/questions/domain/models.dart';
import 'package:edugain/features/questions/presentation/question_home.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders the four-tile question panel so it can be looked at.
///
///     flutter test test/question_home_shot_test.dart --tags shot --run-skipped --update-goldens
QuestionPart _part(String id, String title, List<String> questions) =>
    QuestionPart(
      id: id,
      title: title,
      subtitle: '',
      topics: [QuestionTopic(id: '$id-t', title: 'Topic', questions: questions)],
    );

final _parts = [
  _part('p1', 'Part 1', ['Do you work or are you a student?']),
  _part('p2', 'Part 2', ['Describe a place you like to visit.']),
  _part('p3', 'Part 3', ['Why do people travel abroad these days?']),
];

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
            Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()));
      await icons.load();
    }
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
            Future.value(File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app() => ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: AppColors.canvas,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
          ),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: Scaffold(
            // The call screen's ground, because that is where it now lives.
            backgroundColor: AppColors.inkDark,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: SingleChildScrollView(
                  child: QuestionHome(
                    parts: _parts,
                    savedCount: 3,
                    embedded: true,
                    onDark: true,
                    onSaved: () {},
                    onPart: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('the panel before and after a draw', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(QuestionHome),
      matchesGoldenFile('shots/question_home.png'),
    );

    // Press Draw: a question must land in the panel above the grid.
    await tester.tap(find.text('Tasodifiy savol'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(QuestionHome),
      matchesGoldenFile('shots/question_home_drawn.png'),
    );
  });
}
