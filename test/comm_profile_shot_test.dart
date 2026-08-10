@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/profile/presentation/profile_screen.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders the communication profile card so it can be looked at.
///
/// The card's problem was never that it crashed — it rendered perfectly and
/// told the learner nothing, which no test can catch and a screenshot can.
///
///     flutter test test/comm_profile_shot_test.dart --tags shot --run-skipped --update-goldens
AbilityTrend _t(double current, double? delta, int samples) =>
    AbilityTrend(current: current, delta: delta, samples: samples);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final file in ['segoeui.ttf', 'segoeuib.ttf']) {
      final path = 'C:/Windows/Fonts/$file';
      if (!File(path).existsSync()) continue;
      final loader = FontLoader('Inter')
        ..addFont(
            Future.value(File(path).readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
    const iconFont =
        'D:/flutter_windows_3.35.4-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(iconFont).existsSync()) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
            Future.value(File(iconFont).readAsBytesSync().buffer.asByteData()));
      await icons.load();
    }
  });

  Widget app(LearnerProfile p, String lang) => MaterialApp(
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
        locale: Locale(lang),
        home: Scaffold(
          backgroundColor: AppColors.canvas,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.md),
            child: CommunicationProfileCard(profile: p),
          ),
        ),
      );

  Future<void> shoot(
      WidgetTester tester, LearnerProfile p, String lang, String name) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(p, lang));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CommunicationProfileCard),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  // The learner from the report: the same scores, pace and tags — including
  // the `other` bucket, so the shot shows it is gone rather than never sent.
  final real = LearnerProfile(
    focusTags: const [
      'word_choice',
      'other',
      'verb_tense',
      'word_order',
      'articles',
    ],
    voicedMinutes: 8.6,
    spokenWords: 534,
    wordsPerMinute: 62,
    wpmTarget: 140,
    hasMemory: true,
    abilities: {
      'grammar': _t(55, -1, 10),
      'vocabulary': _t(50, -4, 10),
      'overall': _t(46, -2, 10),
    },
  );

  testWidgets('the profile as a learner reads it', (tester) async {
    await shoot(tester, real, 'uz', 'comm_profile_uz');
  });

  testWidgets('improving, in English', (tester) async {
    final p = LearnerProfile(
      focusTags: const ['articles', 'preposition'],
      voicedMinutes: 42.0,
      spokenWords: 5210,
      wordsPerMinute: 108,
      wpmTarget: 140,
      hasMemory: true,
      abilities: {'grammar': _t(78, 6, 10), 'vocabulary': _t(64, 4, 10)},
    );
    await shoot(tester, p, 'en', 'comm_profile_en');
  });

  testWidgets('too little history for a direction', (tester) async {
    final p = LearnerProfile(
      focusTags: const ['verb_tense'],
      voicedMinutes: 3.2,
      spokenWords: 190,
      wordsPerMinute: null,
      wpmTarget: 140,
      hasMemory: false,
      abilities: {'grammar': _t(38, null, 2), 'vocabulary': _t(44, null, 2)},
    );
    await shoot(tester, p, 'ru', 'comm_profile_ru_new');
  });
}
