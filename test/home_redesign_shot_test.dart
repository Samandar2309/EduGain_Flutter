@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Two ways to rebuild the home screen, against what the poll actually said.
///
/// Half of ten voters picked "the home screen — I did not understand where to
/// start", and half picked "live conversation — with whom, when". Those were
/// the top two answers in all three snapshots as the sample doubled, while
/// "there are problems with how it looks" stayed bottom every time. So this is
/// not a visual refresh: it is about what the screen offers first.
///
/// Today the largest block is a blurred "coming soon", and the locked Speaking
/// tile appears a second time in the module row underneath — so the first two
/// things a learner sees are both things they cannot use.
///
/// Both variants: one clear action first, the partner card answering "who and
/// when" with real numbers, the locked tutor demoted and shown ONCE.
///
///     flutter test test/home_redesign_shot_test.dart --tags shot --run-skipped --update-goldens
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

  Future<void> shoot(WidgetTester tester, String name, List<Widget> body) async {
    tester.view.physicalSize = const Size(390 * 3, 1180 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: body,
              ),
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

  testWidgets('A — the lesson leads', (tester) async {
    await shoot(tester, 'home_v_lesson_first', [
      const _Header(),
      const SizedBox(height: AppSpace.lg),
      const _Stats(),
      const SizedBox(height: AppSpace.xl),
      // First, and deliberately: it is the one thing that is always there.
      // Leading with live conversation would put an empty room at the top of
      // the screen most of the day, which is the mistake being fixed.
      const _ContinueHero(),
      const SizedBox(height: AppSpace.lg),
      const _SectionTitle('Jonli'),
      const SizedBox(height: AppSpace.sm),
      const _PartnerCard(online: 3),
      const SizedBox(height: AppSpace.md),
      const _GroupRow(),
      const SizedBox(height: AppSpace.xl),
      const _SectionTitle('Mashq'),
      const SizedBox(height: AppSpace.sm),
      const _PracticePair(),
      const SizedBox(height: AppSpace.md),
      const _LockedRow(),
      const SizedBox(height: AppSpace.xl),
      const _Leaderboard(),
    ]);
  });

  testWidgets('B — live leads, lesson second', (tester) async {
    await shoot(tester, 'home_v_live_first', [
      const _Header(),
      const SizedBox(height: AppSpace.lg),
      const _Stats(),
      const SizedBox(height: AppSpace.xl),
      const _SectionTitle('Hozir jonli'),
      const SizedBox(height: AppSpace.sm),
      const _PartnerCard(online: 3),
      const SizedBox(height: AppSpace.md),
      const _GroupRow(),
      const SizedBox(height: AppSpace.xl),
      const _SectionTitle('Darsingiz'),
      const SizedBox(height: AppSpace.sm),
      const _ContinueQuiet(),
      const SizedBox(height: AppSpace.md),
      const _PracticePair(),
      const SizedBox(height: AppSpace.md),
      const _LockedRow(),
      const SizedBox(height: AppSpace.xl),
      const _Leaderboard(),
    ]);
  });
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AppColors.ink,
      letterSpacing: -0.2,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'Salom, Samandar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.ink,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brandTint,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Text(
          'B2',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.brandDeep,
          ),
        ),
      ),
    ],
  );
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) => Row(
    children: const [
      Expanded(child: _Stat('1250', 'XP', AppColors.xp)),
      SizedBox(width: AppSpace.sm),
      Expanded(child: _Stat('14', 'Kunlik seriya', AppColors.streak)),
      SizedBox(width: AppSpace.sm),
      Expanded(child: _Stat('80%', 'Maqsad', AppColors.brand)),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.colour);
  final String value;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colour,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.inkFaint),
        ),
      ],
    ),
  );
}

/// The answer to "I did not understand where to start" — a named next step,
/// not a menu.
class _ContinueHero extends StatelessWidget {
  const _ContinueHero();

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
              child: const Text(
                'BUGUN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '5-dars · 8 daqiqa',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        const Text(
          'There is / There are',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Qoldingan joyingizdan davom eting',
          style: TextStyle(
            fontSize: 12.5,
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
          child: const Text(
            'Davom etish',
            style: TextStyle(
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

/// The same step, when it is not the loudest thing on the screen.
class _ContinueQuiet extends StatelessWidget {
  const _ContinueQuiet();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.card,
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.brandDeep,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'There is / There are',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '5-dars · 8 daqiqa qoldi',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
      ],
    ),
  );
}

/// The answer to "with whom, when" — both numbers are real: presence for the
/// count, 112 recorded calls for the hours.
class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.online});
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
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$online kishi hozir onlayn',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDeep,
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
            children: const [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.inkFaint,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Odatda 12:00–14:00 va 20:00–23:00 da faol',
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
          ),
          child: const Text(
            'Sherik topish',
            style: TextStyle(
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

class _GroupRow extends StatelessWidget {
  const _GroupRow();

  @override
  Widget build(BuildContext context) => const _Tile(
    icon: Icons.groups_rounded,
    colour: Color(0xFF8B5CF6),
    title: 'Guruh suhbati',
    subtitle: '50 kishigacha ochiq xonada gapiring',
  );
}

class _PracticePair extends StatelessWidget {
  const _PracticePair();

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Expanded(
          child: _Tile(
            icon: Icons.school_rounded,
            colour: AppColors.brand,
            title: 'Words & Rules',
            subtitle: 'Qoida va so‘z',
            compact: true,
          ),
        ),
        SizedBox(width: AppSpace.sm),
        Expanded(
          child: _Tile(
            icon: Icons.sports_esports_rounded,
            colour: AppColors.vocabulary,
            title: 'O‘yinlar',
            subtitle: 'Viktorina, duel',
            compact: true,
          ),
        ),
      ],
    ),
  );
}

/// Once, small, and last. It used to be the biggest block on the screen and
/// then appear a second time in the module row underneath.
class _LockedRow extends StatelessWidget {
  const _LockedRow();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.md,
    ),
    decoration: BoxDecoration(
      color: AppColors.canvasAlt,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.inkFaint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 17,
            color: AppColors.inkFaint,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI ustoz bilan suhbat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Tez kunda ochiladi',
                style: TextStyle(fontSize: 11.5, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.soft,
    ),
    child: compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colour, size: 20),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: colour, size: 21),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaint,
              ),
            ],
          ),
  );
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.md,
      AppSpace.lg,
      AppSpace.md,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Reyting',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Spacer(),
            Text(
              'Bu hafta',
              style: TextStyle(fontSize: 11.5, color: AppColors.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        for (final r in const [
          (1, 'Samandar', 505, AppColors.xp),
          (2, 'Jurakulov Akbar', 445, AppColors.inkFaint),
          (3, 'Nigina', 215, AppColors.streak),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '${r.$1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: r.$4,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    r.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '${r.$3}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
