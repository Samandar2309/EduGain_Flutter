@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/media/microphone_service.dart';
import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/features/peer/presentation/mic_gate.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The microphone dialog, as it will actually appear.
///
/// The real `showMicProblem` is rendered, not a copy — a shot of a
/// reimplementation would prove nothing about what ships.
///
/// Two variants matter and they are deliberately different: `denied` offers
/// "try again", because the prompt can still be shown; `blocked` does not,
/// because nothing the learner does inside the app can reopen a permission the
/// platform has stopped asking about, and a button that cannot work is worse
/// than no button.
///
///     flutter test test/mic_gate_shot_test.dart --tags shot --run-skipped --update-goldens
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
    String code,
    MicFailure failure,
    String name,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // Same harness as every other shot in this suite: `AppTheme.light()`
        // cannot be used here because it builds its text theme through
        // `GoogleFonts`, which goldens run with runtime fetching disabled.
        //
        // The seeded scheme is not a stand-in for the dialog's colour: the app
        // theme does not override `surfaceContainerHigh`, which is what M3
        // paints an AlertDialog with — so the faint emerald cast below is the
        // real one.
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
        locale: Locale(code),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () => showMicProblem(ctx, failure),
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
      find.byType(AlertDialog),
      matchesGoldenFile('shots/mic_${name}_$code.png'),
    );
  }

  Future<void> shootPrimer(WidgetTester tester, String code) async {
    tester.view.physicalSize = const Size(390 * 3, 780 * 3);
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
        locale: Locale(code),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () => showMicPrimer(ctx),
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
      matchesGoldenFile('shots/mic_primer_$code.png'),
    );
  }

  testWidgets('primer — Uzbek', (t) async => shootPrimer(t, 'uz'));
  testWidgets('primer — English', (t) async => shootPrimer(t, 'en'));
  testWidgets('primer — Russian', (t) async => shootPrimer(t, 'ru'));

  testWidgets(
    'denied — Uzbek',
    (t) async => shoot(t, 'uz', MicFailure.denied, 'denied'),
  );
  testWidgets(
    'denied — English',
    (t) async => shoot(t, 'en', MicFailure.denied, 'denied'),
  );
  testWidgets(
    'blocked — Uzbek',
    (t) async => shoot(t, 'uz', MicFailure.blocked, 'blocked'),
  );
  testWidgets(
    'busy — Uzbek',
    (t) async => shoot(t, 'uz', MicFailure.busy, 'busy'),
  );
}
