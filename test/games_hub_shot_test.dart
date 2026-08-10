@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/games/presentation/games_hub_screen.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The games, back under one roof.
///
/// The screens themselves were restored from the commit that removed them, so
/// they are not new code — but the hub is, and nothing had ever drawn these
/// four together on one screen before.
///
///     flutter test test/games_hub_shot_test.dart --tags shot --run-skipped --update-goldens
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

  Future<void> shoot(WidgetTester tester, String code) async {
    tester.view.physicalSize = const Size(390 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
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
          locale: Locale(code),
          home: const GamesHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GamesHubScreen),
      matchesGoldenFile('shots/games_hub_$code.png'),
    );
  }

  testWidgets('Uzbek', (tester) async => shoot(tester, 'uz'));
  testWidgets('English', (tester) async => shoot(tester, 'en'));
}
