import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../quiz/application/quiz_controller.dart';
import '../../quiz/domain/models.dart';

/// Everything you play, under one roof.
///
/// The word and grammar screens were removed when the two were folded into a
/// single course path. That was right for a study path — "which half do I do
/// today" is a question nobody answers well — and it took the games with it,
/// which it should not have. A duel against another learner is not half a
/// curriculum.
///
/// So the course keeps the studying and this keeps the playing.
///
/// Grammar drills and spaced review were here briefly and were taken out: the
/// course already teaches the rules and already schedules its own review, so
/// both were a second way into something that has a first one. What is left is
/// what the course does not do — play, and a plain list of the words.
class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l.gamesTitle),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          // The live one leads, and is the only card given the full treatment.
          // It is the only thing here that is happening whether or not you
          // open it — everything else waits for you.
          _LiveQuizCard(
            live: ref.watch(quizLiveProvider).valueOrNull ?? QuizLive.none,
            onTap: () => context.push('/games/quiz'),
          ),
          const SizedBox(height: AppSpace.md),
          // Play first, study second. The order is the point of the screen.
          _GameCard(
            icon: Icons.sports_esports_rounded,
            colour: AppColors.brand,
            title: l.gamesVocabTitle,
            subtitle: l.gamesVocabSubtitle,
            onTap: () => context.push('/vocabulary/play'),
          ),
          const SizedBox(height: AppSpace.md),
          _GameCard(
            icon: Icons.menu_book_rounded,
            colour: AppColors.inkSoft,
            title: l.gamesBrowseTitle,
            subtitle: l.gamesBrowseSubtitle,
            onTap: () => context.push('/vocabulary/learn'),
          ),
        ],
      ),
    );
  }
}

/// The live quiz, given the hero treatment the plain cards deliberately are
/// not: it is the one thing on this screen that is already running.
class _LiveQuizCard extends StatelessWidget {
  const _LiveQuizCard({required this.live, required this.onTap});

  final QuizLive live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Pulse(),
                      const SizedBox(width: 6),
                      Text(
                        // Real presence or nothing. An invented crowd is the
                        // fastest way to lose a room — so with nobody in a
                        // lobby this invites you to open one rather than
                        // implying a game is already going.
                        live.playing > 0
                            ? l.quizPlaying(live.playing)
                            : l.quizStart,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              l.quizHubTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              live.needed > 0 && live.live
                  ? l.quizWaitingFor(live.needed)
                  : l.quizHubSubtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse();

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One small moving thing on an otherwise still screen. Reduced-motion
    // users get a plain dot rather than a heartbeat.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return const _Dot(opacity: 1);
    }
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: const _Dot(opacity: 1),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.colour,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // A wash of the icon's own hue rather than a saturated tile:
                // four bright squares in a column compete and none of them
                // wins.
                color: colour.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: colour, size: 24),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                      height: 1.35,
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
      ),
    );
  }
}
