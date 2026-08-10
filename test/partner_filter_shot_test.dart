@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/peer/presentation/partner_filter_sheet.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "who would you like to talk to?" sheet.
///
///     flutter test test/partner_filter_shot_test.dart --tags shot --run-skipped --update-goldens
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

  Future<void> shoot(
      WidgetTester tester, String lang, String name, PartnerFilter pick) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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
        locale: Locale(lang),
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showPartnerFilterSheet(ctx, online: 12, initial: pick),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BottomSheet),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('default: anyone', (tester) async {
    await shoot(tester, 'uz', 'partner_filter_uz', PartnerFilter.any);
  });

  testWidgets('narrowed, with the wait warning', (tester) async {
    await shoot(tester, 'uz', 'partner_filter_uz_female', PartnerFilter.female);
  });

  testWidgets('in English', (tester) async {
    await shoot(tester, 'en', 'partner_filter_en', PartnerFilter.male);
  });
}
