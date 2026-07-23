import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/glass.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'lesson_launch.dart';
import 'scenario_theme.dart';
import 'widgets/lesson_widgets.dart';

/// The goal-first Speaking home, designed so the learner never wonders "what
/// now?". Top to bottom it answers: where did I stop (Continue), what's today's
/// quick win (Daily Mission), what should I do next (Recommended), the full
/// goal map (Tracks), and how far I've come (Progress) — speaking is ≤2 taps away.
class SpeakingHomeScreen extends ConsumerStatefulWidget {
  const SpeakingHomeScreen({super.key});

  @override
  ConsumerState<SpeakingHomeScreen> createState() => _SpeakingHomeScreenState();
}

class _SpeakingHomeScreenState extends ConsumerState<SpeakingHomeScreen> {
  bool _starting = false;

  Future<void> _launch(String lessonKey, String backdrop, String title) async {
    await launchLesson(
      context,
      ref,
      lessonKey: lessonKey,
      backdropKey: backdrop,
      title: title,
      onBusy: (b) {
        if (mounted) setState(() => _starting = b);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(speakingHomeProvider);
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: AppColors.canvasDark,
        body: Stack(
          children: [
            const Positioned.fill(
              child: ImmersiveBackground(accent: AppColors.speaking),
            ),
            SafeArea(
              child: home.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _HomeError(
                  onRetry: () => ref.invalidate(speakingHomeProvider),
                ),
                data: (data) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(speakingHomeProvider);
                    ref.invalidate(speakingQuotaProvider);
                  },
                  child: _HomeBody(
                    home: data,
                    onLaunch: _launch,
                    onOpenTrack: (t) => context.push('/speaking/track', extra: t),
                  ),
                ),
              ),
            ),
            if (_starting)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

typedef _Launch = void Function(String lessonKey, String backdrop, String title);

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.home,
    required this.onLaunch,
    required this.onOpenTrack,
  });

  final SpeakingHome home;
  final _Launch onLaunch;
  final void Function(TrackSummary) onOpenTrack;

  @override
  Widget build(BuildContext context) {
    final mission = home.dailyMission;
    final rec = home.recommendedLesson;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _TopBar(level: home.cefrLevel),
        const SizedBox(height: 6),
        // Two ways to speak: the AI tutor (this page) or live with people.
        const _ModeSwitchRow(),
        const SizedBox(height: 14),
        // 1 · Continue Learning — the single most important element.
        _ContinueHero(home: home, onLaunch: onLaunch, onOpenTrack: onOpenTrack),
        const SizedBox(height: 14),
        // Today's minutes — the tier made visible. Hidden while loading/failed.
        const _QuotaCard(),
        const SizedBox(height: 22),
        // 2 · Daily mission.
        if (mission != null) ...[
          const _SectionLabel('Daily mission'),
          const SizedBox(height: 10),
          _DailyMissionCard(mission: mission, onLaunch: onLaunch),
          const SizedBox(height: 22),
        ],
        // 3 · Recommended lesson.
        if (rec != null) ...[
          const _SectionLabel('Recommended for you'),
          const SizedBox(height: 10),
          LessonTile(
            title: rec.title,
            subtitle: rec.subtitle,
            difficulty: rec.difficulty,
            estMinutes: rec.estMinutes,
            xpReward: rec.xpReward,
            grammarFocus: rec.grammarFocus,
            accent: backdropForKey(rec.backdrop).accent,
            isPremium: rec.isPremium,
            isLocked: rec.isLocked,
            isDone: rec.isDone,
            onTap: () => rec.isLocked
                ? _lockedSnack(context, rec)
                : onLaunch(rec.key, rec.backdrop, rec.title),
          ),
          const SizedBox(height: 22),
        ],
        // 4 · The goal tracks.
        const _SectionLabel('Explore by goal'),
        const SizedBox(height: 10),
        ...home.tracks.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TrackCard(
              track: t,
              isContinuing: home.continueLesson?.track == t.track,
              onTap: () => onOpenTrack(t),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 5 · Progress summary.
        _ProgressSummary(
          done: home.lessonsDone,
          total: home.lessonsTotal,
        ),
      ],
    );
  }
}

/// The two speaking modes, side by side: the AI tutor (this page — active)
/// and live conversations with real people (the peer hub).
class _ModeSwitchRow extends StatelessWidget {
  const _ModeSwitchRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.smart_toy_rounded,
            title: 'AI tutor',
            subtitle: 'Shaxsiy o‘qituvchi',
            active: true,
            onTap: null, // already here
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: _ModeCard(
            icon: Icons.record_voice_over_rounded,
            title: 'Jonli suhbat',
            subtitle: 'Odamlar bilan',
            active: false,
            onTap: () => context.push('/peer'),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.speaking;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.md),
          decoration: BoxDecoration(
            gradient: active ? AppGradients.accent(accent) : null,
            color: active ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: active ? null : Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? Colors.white : accent, size: 22),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: active ? Colors.white70 : AppColors.inkSoft,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _lockedSnack(BuildContext context, TrackLesson lesson) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        lesson.isPremium
            ? 'This lesson is part of Premium.'
            : 'Reach ${lesson.cefrMin} to unlock this lesson.',
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const SizedBox(width: 2),
        const Expanded(
          child: Text(
            'Speaking',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
        ),
        if (level.isNotEmpty) _LevelPill(level: level),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── 1 · Continue Learning ────────────────────────────────────────────────────
class _ContinueHero extends StatelessWidget {
  const _ContinueHero({
    required this.home,
    required this.onLaunch,
    required this.onOpenTrack,
  });

  final SpeakingHome home;
  final _Launch onLaunch;
  final void Function(TrackSummary) onOpenTrack;

  @override
  Widget build(BuildContext context) {
    final cont = home.continueLesson;
    // Nothing started yet → a friendly first-lesson prompt.
    if (cont == null) {
      final rec = home.recommendedLesson;
      final accent = backdropForKey(rec?.backdrop ?? 'default').accent;
      return _HeroShell(
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroEyebrow(icon: Icons.rocket_launch_rounded, text: 'Get started'),
            const SizedBox(height: 12),
            const Text(
              'Start your first lesson',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rec != null
                  ? '${rec.title} · ${rec.estMinutes} min'
                  : 'Pick a goal and begin speaking in seconds.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _HeroButton(
              label: 'Start now',
              accent: accent,
              onTap: () {
                if (rec != null && !rec.isLocked) {
                  onLaunch(rec.key, rec.backdrop, rec.title);
                } else if (home.tracks.isNotEmpty) {
                  onOpenTrack(home.tracks.first);
                }
              },
            ),
          ],
        ),
      );
    }

    final accent = backdropForKey(cont.backdrop).accent;
    return _HeroShell(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _HeroEyebrow(
                icon: Icons.play_circle_fill_rounded,
                text: 'Continue learning',
              ),
              const SizedBox(width: 8),
              if (cont.lastOpened != null)
                Expanded(
                  child: Text(
                    _relativeDay(cont.lastOpened!),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${cont.trackTitle} · ${cont.cefrMin}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cont.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: cont.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(cont.progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _HeroButton(
            label: cont.isCompleted ? 'Practice again' : 'Continue',
            accent: accent,
            onTap: () => onLaunch(cont.lessonKey, cont.backdrop, cont.title),
          ),
        ],
      ),
    );
  }
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.accent, required this.child});
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.glow(accent),
      ),
      child: GlassPanel(
        radius: AppRadius.xl,
        opacity: 0.14,
        borderOpacity: 0.4,
        padding: const EdgeInsets.all(AppSpace.xl),
        child: child,
      ),
    );
  }
}

class _HeroEyebrow extends StatelessWidget {
  const _HeroEyebrow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.accent(accent),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Today's speaking minutes (the tier, made visible) ────────────────────────
class _QuotaCard extends ConsumerWidget {
  const _QuotaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(speakingQuotaProvider);
    // No skeleton, no error card: the ring appears when it's known and the
    // home never jumps around because of it.
    final q = quota.valueOrNull;
    if (q == null || q.secondsLimit <= 0) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final ratio = q.remainingRatio;
    final ringColor = q.isExhausted
        ? AppColors.danger
        : ratio <= 0.25
            ? AppColors.warning
            : AppColors.brand;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: ratio,
            size: 52,
            stroke: 6,
            color: ringColor,
            trackColor: Colors.white.withValues(alpha: 0.14),
            center: Text(
              '${q.minutesRemaining}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.quotaTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  q.isExhausted
                      ? l.quotaExhausted
                      : l.quotaUsedOf(q.minutesUsed, q.minutesLimit),
                  style: TextStyle(
                    color: q.isExhausted ? AppColors.warning : Colors.white60,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (q.isExhausted) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/subscriptions'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                l.quotaUpgrade,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 2 · Daily mission ────────────────────────────────────────────────────────
class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard({required this.mission, required this.onLaunch});
  final DailyMission mission;
  final _Launch onLaunch;

  @override
  Widget build(BuildContext context) {
    final accent = backdropForKey(mission.backdrop).accent;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => onLaunch(mission.lessonKey, mission.backdrop, mission.title),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppGradients.accent(AppColors.streak),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadow.glow(AppColors.streak),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Speaking Mission",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DifficultyBadge(difficulty: mission.difficulty),
                      MetaChip(
                        icon: Icons.schedule_rounded,
                        label: '${mission.estMinutes} min',
                      ),
                      MetaChip(
                        icon: Icons.bolt_rounded,
                        label: '+${mission.xpReward} XP',
                        color: AppColors.xp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

// ── 4 · Track card ───────────────────────────────────────────────────────────
class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.isContinuing,
    required this.onTap,
  });

  final TrackSummary track;
  final bool isContinuing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = backdropForKey(track.backdrop).accent;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(AppSpace.lg),
          borderOpacity: track.isRecommended ? 0.5 : 0.18,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent(accent),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: AppShadow.glow(accent),
                      ),
                      child: Icon(_iconFor(track.icon),
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            track.subtitle,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: track.progress,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${track.lessonsDone}/${track.lessonsTotal} lessons',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (track.isRecommended)
          Positioned(top: -10, right: 16, child: _Badge(
            accent: accent, icon: Icons.auto_awesome_rounded,
            text: 'Recommended for you',
          )),
        if (!track.isRecommended && isContinuing)
          Positioned(top: -10, right: 16, child: _Badge(
            accent: accent, icon: Icons.play_arrow_rounded, text: 'Continue',
          )),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.accent, required this.icon, required this.text});
  final Color accent;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppGradients.accent(accent),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadow.glow(accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5 · Progress summary ─────────────────────────────────────────────────────
class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white70, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of $total lessons completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.brand),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Couldn't load Speaking.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String key) => switch (key) {
  'graduation' => Icons.school_rounded,
  'microphone' => Icons.mic_rounded,
  'globe' => Icons.public_rounded,
  'book' => Icons.menu_book_rounded,
  'briefcase' => Icons.work_rounded,
  _ => Icons.auto_awesome_rounded,
};

/// "today" / "yesterday" / "N days ago" for the Continue card's last-opened hint.
String _relativeDay(DateTime when) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(when.year, when.month, when.day))
      .inDays;
  return switch (days) {
    <= 0 => 'Last opened today',
    1 => 'Last opened yesterday',
    _ => 'Last opened $days days ago',
  };
}
