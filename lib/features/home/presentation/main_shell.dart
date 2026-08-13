import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/live_data.dart';
import '../../../core/providers.dart';
import '../../../core/ui/coming_soon.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../gamification/application/providers.dart';
import '../../gamification/presentation/leaderboard_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../speaking/application/providers.dart';
import 'home_screen.dart';

/// Root authenticated shell: a [NavigationBar] over four tabs kept alive via
/// an [IndexedStack]. Deeper flows (speaking, vocabulary…) are pushed on top.
///
/// Keeping the tabs alive is what makes switching between them instant and
/// lossless — scroll position, a half-typed answer, an open sheet. It is also
/// why the figures on them used to need the app restarting: nothing behind a
/// tab is ever disposed, so `autoDispose` never fires and a provider read once
/// at startup is read once, full stop.
///
/// So the shell re-reads them itself, at the two moments the learner would
/// expect a number to be current: coming back to a tab, and coming back from
/// an activity that changed it. (The third moment — coming back to the app —
/// belongs to the providers, via `refreshOnResume`.)
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with RouteAware {
  int _index = 0;

  // Leaderboard sits in the bar rather than behind the home screen: a weekly
  // board is only motivating if checking it is one tap, and a rank buried two
  // levels deep is one nobody watches change.
  static const _tabs = [
    HomeTab(),
    LessonsTab(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  /// Everything on these tabs that the server owns and an activity can move.
  ///
  /// Listed here rather than left to each screen because the alternative is
  /// every flow that earns XP remembering to invalidate on its way out — and
  /// the number of flows that remembered was zero, which is precisely how XP
  /// came to need a restart to appear.
  ///
  /// Invalidating a provider nobody is watching is a no-op, so naming all of
  /// them costs nothing on a tab that shows none.
  static final _live = <ProviderOrFamily>[
    gamificationProfileProvider,
    xpHistoryProvider,
    leaderboardProvider,
    speakingQuotaProvider,
  ];

  void _refreshLive() {
    for (final provider in _live) {
      ref.invalidate(provider);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// A game, a lesson or a conversation just closed over this shell.
  ///
  /// Whatever it earned was earned server-side while these tabs sat untouched
  /// underneath, so this is the moment their numbers are known to be wrong.
  @override
  void didPopNext() => _refreshLive();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == _index) return;
          setState(() => _index = i);
          // The tab being opened has been sitting there with its first answer
          // since the app started. Looking at it is the moment it has to be
          // right.
          _refreshLive();
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_outlined),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_outlined),
            label: l.navLessons,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events),
            selectedIcon: const Icon(Icons.emoji_events),
            label: l.navLeaderboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}

/// "Darslar" tab — the four modules, and nothing else.
///
/// A continue card and a track carousel lived here briefly and were removed:
/// with blocks above and below them the four modules stopped being the point of
/// the screen, and a catalogue turned into a feed. Two rows of two is the whole
/// tab, and it mirrors the Speaking hub so the app reads as one thing.
class LessonsTab extends ConsumerWidget {
  const LessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final level = ref.watch(authControllerProvider).user?.cefrLevel ?? '';
    final placed = level.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 110),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, AppSpace.xl, 2, AppSpace.lg),
            child: Text(
              l.lessonsTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),
        _pair(
          // The tutor is the last thing to open. Blurred in place rather than
          // taken out of the grid: the tab is two rows of two, and removing a
          // tile would rearrange the screen around an absence nobody can see.
          ComingSoonVeil(
            enabled: !ref.watch(aiUnlockedProvider),
            label: l.comingSoon,
            radius: 18,
            compact: true,
            child: _LessonCard(
              icon: Icons.record_voice_over_rounded,
              colour: AppColors.speaking,
              title: 'Speaking',
              subtitle: l.lessonSpeakingSubtitle,
              onTap: () => context.push('/speaking'),
            ),
          ),
          // One card where there were two.
          //
          // Grammar and Vocabulary each taught half a thing and left the
          // learner to decide which half to do today — a decision nobody can
          // make well, and the one the course exists to take away.
          _LessonCard(
            icon: Icons.school_rounded,
            colour: AppColors.brand,
            title: l.lessonCourseTitle,
            subtitle: l.lessonCourseSubtitle,
            onTap: () => context.push('/course'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        // The second pair, matching the first. Two full-width bars under a row
        // of two made the tab read as though it had run out of things to say
        // halfway down; a 2×2 grid is one shape rather than two.
        _pair(
          // Grammar sat beside this for a day; the course already teaches the
          // rules, so it was a second door into one room.
          _LessonCard(
            icon: Icons.sports_esports_rounded,
            colour: AppColors.vocabulary,
            title: l.gamesTitle,
            subtitle: l.gamesVocabSubtitle,
            onTap: () => context.push('/games'),
          ),
          _LessonCard(
            icon: Icons.assignment_turned_in_rounded,
            colour: AppColors.placement,
            title: l.lessonPlacementTitle,
            subtitle: l.lessonPlacementSubtitle,
            // The level, or the fact that there is not one. Not a warning any
            // more: taking the test is optional, so an untested learner is not
            // in a state that needs flagging in red.
            meta: placed ? level : l.homeLevelUnknown,
            onTap: () => context.push('/placement'),
          ),
        ),
      ],
    );
  }

  /// Two cards side by side, matched in height.
  ///
  /// `IntrinsicHeight` is what makes `stretch` legal: inside a ListView the row
  /// has no height to stretch against, and a bare `stretch` collapsed the whole
  /// second row off the screen without raising anything.
  static Widget _pair(Widget left, Widget right) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpace.md),
        Expanded(child: right),
      ],
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.meta,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    // No warning variant any more. It existed to paint "level unknown" red,
    // and an untested learner is no longer in a state worth alarming about.
    final accent = colour;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x240F172A),
              blurRadius: 16,
              spreadRadius: -8,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        // A wash of the icon's own hue with the glyph in it.
                        // Four saturated tiles compete and none of them wins.
                        color: colour.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: colour, size: 23),
                    ),
                  ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  meta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
