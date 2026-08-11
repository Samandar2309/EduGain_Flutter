@Tags(['shot'])
library;

import 'dart:io';

import 'package:edugain/core/ui/tokens.dart';
import 'package:edugain/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The two rebuilt sections of the home screen, in both states.
///
/// The empty one is rendered because it is the common one: fifty-five learners
/// spread across a day means the rooms are usually quiet, and a card that only
/// looks right when busy is a card most people never see looking right.
///
/// Replica of the real widgets — `_LiveCard` and `_ModuleTile` are private to
/// `home_screen.dart`, and this follows the convention the other shot tests for
/// this screen already use.
///
///     flutter test test/home_sections_shot_test.dart --tags shot --run-skipped --update-goldens
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
    String name, {
    String? groupBadge,
    String? peerBadge,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 470 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('uz'),
        home: Scaffold(
          backgroundColor: AppColors.canvas,
          body: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(title: l.homeSpeakLive, trailing: l.homeSeeAll),
                    const SizedBox(height: AppSpace.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _LiveCard(
                              icon: Icons.people_alt_rounded,
                              title: l.homeGroupTitle,
                              subtitle: l.homeGroupSubtitle,
                              colours: const [
                                Color(0xFF6D4BE8),
                                Color(0xFF9F7BFF),
                              ],
                              badge: groupBadge,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: _LiveCard(
                              icon: Icons.record_voice_over_rounded,
                              title: l.homePeerTitle,
                              subtitle: l.homePeerSubtitle,
                              colours: const [
                                Color(0xFF0EA5E9),
                                Color(0xFF38BDF8),
                              ],
                              badge: peerBadge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    _Section(title: l.modules, trailing: l.homeSeeAll),
                    const SizedBox(height: AppSpace.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _ModuleTile(
                              icon: Icons.menu_book_rounded,
                              colour: AppColors.brand,
                              title: l.homeWordsTitle,
                              subtitle: l.homeWordsSub,
                              chip: l.homeLessonsAt(12, 91),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: _ModuleTile(
                              icon: Icons.sports_esports_rounded,
                              colour: AppColors.placement,
                              title: l.gamesTitle,
                              subtitle: l.homeGamesSub,
                              chip: l.homeGamesN(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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

  testWidgets('rooms busy', (t) async {
    await shoot(t, 'home_sections_live', groupBadge: '7 / 50', peerBadge: '2 online');
  });

  testWidgets('rooms quiet — the usual state', (t) async {
    await shoot(t, 'home_sections_quiet');
  });
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.trailing});
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.ink,
        ),
      ),
      Row(
        children: [
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 15,
            color: AppColors.inkFaint,
          ),
        ],
      ),
    ],
  );
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colours,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colours;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = badge != null;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colours,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: live
                      ? const Color(0xFF34D399)
                      : Colors.white.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  live ? l.homeLiveOpen : l.homeLiveQuiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (live) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            maxLines: 3,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    l.homeJoinChat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colours.first,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: colours.first,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.colour,
    required this.title,
    this.subtitle,
    this.chip,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String? subtitle;
  final String? chip;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.soft,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: colour, size: 20),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.inkFaint,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          title,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: AppColors.inkSoft,
            ),
          ),
        ],
        if (chip != null) ...[
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              chip!,
              style: TextStyle(
                fontSize: 11,
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
