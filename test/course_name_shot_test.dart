@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Naming the tile that replaced "Grammar" and "Vocabulary".
///
/// "Kurs" says nothing about what is inside it, which is the complaint. The
/// replacement has to survive a 178-wide tile next to "Speaking", so this is a
/// fitting problem as much as a wording one — a name that wraps to three lines
/// pushes the subtitle out of the card.
///
///     flutter test test/course_name_shot_test.dart --tags shot --run-skipped --update-goldens
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

  /// The real `_LessonCard` shape from the Darslar tab.
  Widget tile(String title, String subtitle) => SizedBox(
    width: 178,
    child: Container(
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
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.brand,
              size: 23,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    ),
  );

  /// The home "Modullar" row: three across, one line, 11px. This is the tight
  /// surface — a name that fits the Darslar card can still be clipped here, and
  /// a clipped name is worse than a vague one.
  Widget moduleRow(String courseTitle, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        for (final t in ['Speaking', courseTitle, 'Daraja testi'])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: t == courseTitle
                          ? AppColors.brand
                          : AppColors.inkFaint,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t,
                      maxLines: lines,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> shoot(WidgetTester tester, String name, Widget body) async {
    tester.view.physicalSize = const Size(400 * 3, 760 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: AppColors.canvas,
        ),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: body,
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

  testWidgets('the three places the name appears', (tester) async {
    await shoot(
      tester,
      'course_name_final',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOME — Modullar',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 8),
          moduleRow('Words & Rules'),
          const SizedBox(height: 14),
          const Text(
            'DARSLAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile('Speaking', 'AI bilan jonli suhbat orqali gapirishni mashq qiling'),
              const SizedBox(width: 12),
              tile('Words & Rules', 'Qoidalarni o‘rganing, so‘zlarni yodlang'),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'THE COURSE SCREEN HEADER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: const [
                Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.inkSoft),
                SizedBox(width: 8),
                Text(
                  'Words & Rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'RU / EN — same title, localised subtitle',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile('Words & Rules', 'Учите правила, запоминайте слова'),
              const SizedBox(width: 12),
              tile('Words & Rules', 'Learn the rules, memorise the words'),
            ],
          ),
        ],
      ),
    );
  });
}
