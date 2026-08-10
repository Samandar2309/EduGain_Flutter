@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/coming_soon.dart';
import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The AI tutor, held back behind glass.
///
/// Two treatments, because the two cards are doing different jobs. The home
/// hero is artwork and a promise — it stays, blurred, with the words on it. The
/// Speaking tile is one of four in a grid, where a sentence would not fit and
/// a padlock says the same thing in less room.
///
///     flutter test test/coming_soon_shot_test.dart --tags shot --run-skipped --update-goldens
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
    String name,
    Widget Function(AppLocalizations l) build, {
    Size size = const Size(390, 220),
  }) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
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
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: build(AppLocalizations.of(ctx))),
            ),
          ),
        ),
      ),
    );
    // Assets do not decode inside the test's fake async zone, so a golden taken
    // straight after pumpAndSettle shows the card with the artwork missing —
    // which is exactly the composition this shot exists to judge. Draining a
    // real event loop lets the image finish.
    await tester.runAsync(() async {
      for (final e in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(e.image, tester.element(find.byType(MaterialApp)));
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  /// Stands in for the home hero: dark, artwork-led, a headline and chips.
  Widget hero(AppLocalizations l) => Container(
    height: 138,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E1065), Color(0xFF4338CA), Color(0xFF1E1B4B)],
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.60, 1],
            ).createShader(r),
            child: Image.asset(
              'assets/hero/hero_base.png',
              height: 138,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(116, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.homeAiKicker.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l.homeAiTitle,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l.homeAiSubtitle,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Stands in for one tile of the four in "Darslar".
  Widget tile(AppLocalizations l) => Container(
    width: 178,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.speaking.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.record_voice_over_rounded,
            color: AppColors.speaking,
            size: 23,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Speaking',
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          l.lessonSpeakingSubtitle,
          maxLines: 3,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    ),
  );

  testWidgets('the home hero, veiled', (tester) async {
    await shoot(
      tester,
      'coming_soon_hero',
      (l) => ComingSoonVeil(
        enabled: true,
        label: l.comingSoon,
        dark: true,
        child: hero(l),
      ),
      size: const Size(390, 180),
    );
  });

  testWidgets('the Speaking tile, locked', (tester) async {
    await shoot(
      tester,
      'coming_soon_tile',
      (l) => ComingSoonVeil(
        enabled: true,
        label: l.comingSoon,
        radius: 18,
        compact: true,
        child: tile(l),
      ),
      size: const Size(240, 210),
    );
  });

  testWidgets('unlocked leaves the card exactly as it was', (tester) async {
    // The flag has to be a true no-op, not "almost the same". On launch day
    // one env var flips it for everybody and nobody should be able to tell
    // this widget was ever in the tree.
    await shoot(
      tester,
      'coming_soon_unlocked',
      (l) => ComingSoonVeil(
        enabled: false,
        label: l.comingSoon,
        radius: 18,
        compact: true,
        child: tile(l),
      ),
      size: const Size(240, 210),
    );
  });
}
