@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/glass.dart';
import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The two moments a learner meets the daily speaking budget.
///
/// The header, which now counts down in real time rather than holding the
/// figure it was handed when the screen opened; and the panel that appears when
/// the day is spent, in each of the three languages.
///
///     flutter test test/daily_minutes_shot_test.dart --tags shot --run-skipped --update-goldens
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

  Future<void> shoot(
    WidgetTester tester,
    String lang,
    String name,
    Widget Function(AppLocalizations l) build,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 420 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
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
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: AppGradients.brand),
              child: Center(
                child: build(AppLocalizations.of(ctx)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  /// A stand-in for the private header clock, built from the same pieces.
  Widget header(AppLocalizations l, String elapsed, int secondsLeft) {
    final low = secondsLeft <= 120;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          elapsed,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
        const Text('·', style: TextStyle(color: Colors.white24, fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          l.minutesShort((secondsLeft / 60).ceil()),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: low ? AppColors.warning : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget spentPanel(AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.quotaExhausted,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: Text(l.finishSession)),
              const SizedBox(width: AppSpace.sm),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                ),
                onPressed: () {},
                child: Text(l.quotaUpgrade),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  testWidgets('the header counts down while the conversation runs', (
    tester,
  ) async {
    await shoot(
      tester,
      'uz',
      'minutes_header',
      (l) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header(l, '00:12', 588),
          const SizedBox(height: 28),
          header(l, '04:30', 330),
          const SizedBox(height: 28),
          // Under two minutes the figure turns amber — late enough not to nag,
          // early enough to finish the sentence in progress.
          header(l, '08:45', 75),
        ],
      ),
    );
  });

  testWidgets('the day is spent, in Uzbek', (tester) async {
    await shoot(tester, 'uz', 'minutes_spent_uz', spentPanel);
  });

  testWidgets('the day is spent, in Russian', (tester) async {
    await shoot(tester, 'ru', 'minutes_spent_ru', spentPanel);
  });

  testWidgets('the day is spent, in English', (tester) async {
    await shoot(tester, 'en', 'minutes_spent_en', spentPanel);
  });
}
