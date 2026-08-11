@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Four ways to put "find a partner" on the home screen as one button.
///
/// The poll said the live conversation was unclear — "with whom, when" — and
/// that is not a tap-count problem. One button only gets somebody to an empty
/// search faster. So every variant here carries the two facts that actually
/// answer it, both of which are real: how many are online now (pruned
/// presence), and when people actually call (112 calls of history peak at
/// 12–14 and 20–23 Tashkent time).
///
/// Rendered in both states, because the empty one is the common one and it is
/// where honesty matters: a button that hides an empty room is the version
/// people stop trusting.
///
///     flutter test test/partner_button_shot_test.dart --tags shot --run-skipped --update-goldens
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

  Future<void> sheet(WidgetTester tester, String name, int online) async {
    tester.view.physicalSize = const Size(390 * 3, 880 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.canvas,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label('A — jonli lenta'),
                _LiveBand(online: online),
                const SizedBox(height: AppSpace.xxl),
                _Label('B — sokin qator'),
                _QuietRow(online: online),
                const SizedBox(height: AppSpace.xxl),
                _Label('C — vaqtni aytadigan karta'),
                _InformedCard(online: online),
                const SizedBox(height: AppSpace.xxl),
                _Label('D — faqat tugma'),
                _ButtonOnly(online: online),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('shots/$name.png'),
    );
  }

  testWidgets('three people online', (t) => sheet(t, 'partner_btn_live', 3));
  testWidgets('nobody online', (t) => sheet(t, 'partner_btn_empty', 0));
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AppColors.inkFaint,
      ),
    ),
  );
}

/// Shared: the honest line about when people actually are here.
const _hours = 'Odatda 12:00–14:00 va 20:00–23:00 da faol';

class _Dot extends StatelessWidget {
  const _Dot({required this.live, this.size = 8});
  final bool live;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: live ? AppColors.success : AppColors.inkFaint,
      shape: BoxShape.circle,
      boxShadow: live
          ? [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ]
          : null,
    ),
  );
}

/// A — a wide gradient band. Loud; earns its space only if this is the thing
/// you most want people doing.
class _LiveBand extends StatelessWidget {
  const _LiveBand({required this.online});
  final int online;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.xl),
    decoration: BoxDecoration(
      gradient: AppGradients.brand,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: AppShadow.glow(AppColors.brand),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(live: online > 0, size: 7),
                  const SizedBox(width: 6),
                  Text(
                    online > 0 ? '$online kishi onlayn' : 'Hozir hech kim yo\u2019q',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        const Text(
          'Sherik bilan gaplashing',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          online > 0 ? 'Bir bosish — va suhbat boshlanadi' : _hours,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            online > 0 ? 'Sherik topish' : 'Birinchi bo\u2019lib kiring',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.brandDeep,
            ),
          ),
        ),
      ],
    ),
  );
}

/// B — a slim row. Cheap in vertical space, so it can sit high on the page
/// without pushing everything else down.
class _QuietRow extends StatelessWidget {
  const _QuietRow({required this.online});
  final int online;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.md,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.soft,
    ),
    child: Row(
      children: [
        SizedBox(
          width: online > 0 ? 52 : 40,
          height: 36,
          child: Stack(
            children: [
              for (var i = 0; i < (online > 0 ? 3 : 1); i++)
                Positioned(
                  left: i * 14,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: online > 0
                          ? [
                              AppColors.brandTint,
                              AppColors.canvasAlt,
                              AppColors.brandTint,
                            ][i]
                          : AppColors.canvasAlt,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: online > 0
                          ? AppColors.brandDeep
                          : AppColors.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Dot(live: online > 0, size: 7),
                  const SizedBox(width: 6),
                  Text(
                    online > 0
                        ? '$online kishi onlayn'
                        : 'Hozir hech kim yo\u2019q',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: online > 0
                          ? AppColors.brandDeep
                          : AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Sherik bilan gaplashing',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
      ],
    ),
  );
}

/// C — says when, not only how many. The only variant that answers the second
/// half of "with whom, WHEN" even when the room is empty.
class _InformedCard extends StatelessWidget {
  const _InformedCard({required this.online});
  final int online;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.speaking.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: AppColors.speaking,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sherik bilan suhbat',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _Dot(live: online > 0, size: 7),
                      const SizedBox(width: 6),
                      Text(
                        online > 0
                            ? '$online kishi hozir onlayn'
                            : 'Hozir hech kim yo\u2019q',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: online > 0
                              ? AppColors.brandDeep
                              : AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.canvasAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.inkFaint,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  _hours,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadow.glow(AppColors.brand),
          ),
          child: Text(
            online > 0 ? 'Sherik topish' : 'Birinchi bo\u2019lib kiring',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// D — the count lives inside the button. Nothing else on screen.
class _ButtonOnly extends StatelessWidget {
  const _ButtonOnly({required this.online});
  final int online;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadow.glow(AppColors.brand),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 19,
            ),
            const SizedBox(width: 10),
            const Text(
              'Sherik topish',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(live: online > 0, size: 6),
                  const SizedBox(width: 5),
                  Text(
                    online > 0 ? '$online' : '0',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 7),
      Text(
        online > 0 ? _hours : 'Hozir hech kim yo\u2019q \u00b7 $_hours',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.inkFaint,
        ),
      ),
    ],
  );
}
