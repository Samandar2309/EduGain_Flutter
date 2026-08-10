@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/vocabulary/application/word_pool.dart';
import 'package:edugain/features/vocabulary/domain/models.dart';
import 'package:edugain/features/vocabulary/presentation/game_modes_screen.dart';
import 'package:edugain/features/vocabulary/presentation/words_to_learn_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The two doors out of the games hub, after they stopped asking for a set.
///
///     flutter test test/games_flow_shot_test.dart --tags shot --run-skipped --update-goldens
VocabSet _set(String title, String level) => VocabSet(
  id: title,
  slug: title,
  title: title,
  cefrLevel: level,
  category: 'x',
  isPremium: false,
  isLocked: false,
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
          Future.value(File(path).readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()),
        );
      await icons.load();
    }
  });

  // Words shaped like the ones production actually holds — a set of fifteen,
  // Uzbek translations, an English example.
  final words = [
    for (final w in const [
      ('device', 'qurilma', 'This device charges quickly.'),
      ('network', 'tarmoq', 'The network is down again.'),
      ('screen', 'ekran', 'Wipe the screen with a soft cloth.'),
      ('battery', 'batareya', 'My battery lasts all day.'),
      ('software', 'dasturiy taʼminot', 'The software needs an update.'),
      ('keyboard', 'klaviatura', 'She spilled tea on the keyboard.'),
      ('storage', 'xotira', 'Cloud storage is cheaper now.'),
      ('signal', 'signal', 'There is no signal in the tunnel.'),
    ])
      VocabItem(
        id: w.$1,
        word: w.$1,
        translationUz: w.$2,
        definitionEn: '',
        example: w.$3,
      ),
  ];

  Future<void> shoot(WidgetTester tester, String name, Widget home) async {
    tester.view.physicalSize = const Size(390 * 3, 700 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The pool is what both screens are built around, so it is the one
          // thing that has to be real here.
          learningWordsProvider.overrideWith((ref) async => words),
          wordGroupsProvider.overrideWith(
            (ref) async => [
              VocabGroup(
                set: _set('Ish va karyera', 'B1'),
                items: words.take(20).toList(),
              ),
              VocabGroup(
                set: _set('Atrof-muhit', 'B1'),
                items: words.take(20).toList(),
              ),
              VocabGroup(
                set: _set('Sayohat va transport', 'B1'),
                items: words.take(20).toList(),
              ),
              VocabGroup(
                set: _set('Biznes va muzokara', 'B2'),
                items: words.take(20).toList(),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: AppColors.canvas,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
            appBarTheme: const AppBarTheme(
              titleTextStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
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
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('the game types, straight away', (tester) async {
    await shoot(tester, 'game_modes', const GameModesScreen());
  });

  testWidgets('the words to memorise', (tester) async {
    await shoot(tester, 'words_to_learn', const WordsToLearnScreen());
  });
}
