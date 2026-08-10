@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Darslar tab after Games and the placement test were paired.
///
/// It used to be a row of two followed by two full-width bars, which read as
/// though the screen had run out of things to say halfway down. Two rows of
/// two is one shape.
///
/// The fitting risk is the placement card: it is the only one carrying a chip
/// ("Daraja: aniqlanmagan"), and it has just lost half its width. Rendered at
/// the true half-width to check the chip survives it.
///
/// Replica of `_LessonCard`, following the convention this screen's other shot
/// test already set — the real widget is private to `main_shell.dart`.
///
///     flutter test test/learn_pairs_shot_test.dart --tags shot --run-skipped --update-goldens
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

  testWidgets('two rows of two, with the chip at half width', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 430 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.canvas,
          body: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              children: [
                _pair(
                  const _Card(
                    icon: Icons.record_voice_over_rounded,
                    colour: AppColors.speaking,
                    title: 'Speaking',
                    subtitle: 'AI bilan jonli suhbat orqali gapirishni mashq '
                        'qiling',
                  ),
                  const _Card(
                    icon: Icons.school_rounded,
                    colour: AppColors.brand,
                    title: 'Words & Rules',
                    subtitle: "Qoidalarni o'rganing, so'zlarni yodlang",
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                _pair(
                  const _Card(
                    icon: Icons.sports_esports_rounded,
                    colour: AppColors.vocabulary,
                    title: "O'yinlar",
                    subtitle: "Yolg'iz, Gainsy bilan yoki jonli raqib bilan",
                  ),
                  const _Card(
                    icon: Icons.assignment_turned_in_rounded,
                    colour: AppColors.placement,
                    title: 'Daraja testi',
                    subtitle: 'CEFR darajangizni aniqlang',
                    meta: 'Daraja: aniqlanmagan',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('shots/learn_pairs.png'),
    );
  });
}

Widget _pair(Widget left, Widget right) => IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: left),
      const SizedBox(width: AppSpace.sm),
      Expanded(child: right),
    ],
  ),
);

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    this.meta,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final String? meta;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.soft,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: colour, size: 21),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.inkFaint,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: AppColors.inkSoft,
          ),
        ),
        if (meta != null) ...[
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              meta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: colour,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
