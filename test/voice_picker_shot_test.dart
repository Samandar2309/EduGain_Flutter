@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/speaking/application/providers.dart';
import 'package:edugain/features/speaking/domain/models.dart';
import 'package:edugain/features/speaking/presentation/voice_picker_sheet.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The voice sheet with the "add more voices" panel open.
///
/// The panel exists because of a limit that cannot be engineered away: a web
/// page cannot install a speech voice, so the only honest thing to offer is
/// the path through the platform's own settings. This shot is how that reads.
///
///     flutter test test/voice_picker_shot_test.dart --tags shot --run-skipped --update-goldens
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

  // What a mid-range Android handset actually offers once the male-English
  // filter has run: a couple of Google voices and one unlabelled system one.
  const roster = [
    Voice(
      id: 'Google US English',
      name: 'Google US English',
      gender: 'male',
      accent: 'en-US',
    ),
    Voice(
      id: 'Google UK English Male',
      name: 'Google UK English Male',
      gender: 'male',
      accent: 'en-GB',
    ),
    Voice(
      id: 'en-us-x-sfg#male_1-local',
      name: 'English (United States)',
      gender: '',
      accent: 'en-US',
    ),
  ];

  Future<void> shoot(WidgetTester tester, String name, Locale locale) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voicesProvider.overrideWith((ref) async => roster)],
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
          locale: locale,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showVoicePicker(ctx, showAddVoices: true),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Open the panel: collapsed it is one row, and the point of the shot is
    // whether the instructions read well once they are on screen.
    await tester.tap(find.byIcon(Icons.library_add_rounded));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BottomSheet),
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets(
    'voice picker, add-voices panel open (uz)',
    (tester) async {
      await shoot(tester, 'voice_picker_add_uz', const Locale('uz'));
    },
    tags: ['shot'],
    skip: !Platform.isWindows,
  );

  testWidgets(
    'voice picker, add-voices panel open (en)',
    (tester) async {
      await shoot(tester, 'voice_picker_add_en', const Locale('en'));
    },
    tags: ['shot'],
    skip: !Platform.isWindows,
  );
}
