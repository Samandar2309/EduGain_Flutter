@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/features/questions/application/providers.dart';
import 'package:edugain/features/questions/domain/models.dart';
import 'package:edugain/features/questions/presentation/questions_sheet.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:google_fonts/google_fonts.dart';
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
        // Without this the shot renders every glyph as a black box: the test
        // loads Segoe under the name 'Inter', and nothing asks for it.
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
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
        ..addFont(
            Future.value(File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the two steps behind a part tile', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(partIndex: 0));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('shots/questions_topics.png'));

    await tester.tap(find.text('Hometown'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('shots/questions_of_topic.png'));
  });
}
