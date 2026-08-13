import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/coming_soon.dart';
import '../../course/application/providers.dart';
import '../../course/domain/models.dart';
import '../../group/application/group_providers.dart';
import '../../peer/application/peer_call_controller.dart';
import '../../peer/presentation/mic_gate.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/user_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/models.dart';
import '../../gamification/application/providers.dart';
import '../../gamification/domain/leaderboard.dart';
import '../../speaking/application/providers.dart';
import '../../subscriptions/application/providers.dart';

/// Home tab. Rendered inside [MainShell]; provides no Scaffold of its own.
///
/// Two compositions in one, chosen by whether the learner has a measured level.
/// XP, streak, standings — nearly everything here is zero on day one, and a
/// layout designed only for the full version shows a new learner a page of
/// noughts. So the untested state is its own screen: one thing to do, with
/// nothing competing against it.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const AppLoader();
    final placed = (user.cefrLevel ?? '').isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gamificationProfileProvider);
        ref.invalidate(leaderboardProvider(false));
        // The minutes pill is rendered right here on this screen. Leaving it
        // out meant the one gesture a learner makes to fix a stale number was
        // the one that did not fix it.
        ref.invalidate(speakingQuotaProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 100),
        children: [
          SafeArea(bottom: false, child: _TopBar(user: user)),
          const SizedBox(height: AppSpace.md),
          // Only when there is one. An unplaced learner used to get this pill
          // in red, reading "level unknown" — a standing complaint about
          // something that is now optional.
          if (placed) ...[
            _LevelChip(level: user.cefrLevel),
            const SizedBox(height: AppSpace.lg),
          ],
          // The same home for everybody.
          //
          // It used to fork: a learner who had not taken the placement test got
          // a call to take it and a greyed-out tutor instead of the stats and
          // the hero. That made sense while the test decided what the tutor
          // would say — with the tutor closed it is a locked door in front of a
          // locked door, and the test itself is optional now.
          const _StatsRow(),
          const SizedBox(height: AppSpace.lg),
          _AiHeroCard(level: user.cefrLevel ?? ''),
          const SizedBox(height: AppSpace.xl),
          const _Modules(),
          const SizedBox(height: AppSpace.xl),
          const _LeaderboardPreview(),
        ],
      ),
    );
  }
}

// ── header ────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tier = ref.watch(mySubscriptionProvider).asData?.value.tier ?? 'free';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.greeting(user.displayName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          _TierBadge(tier: tier),
        ],
      ),
    );
  }
}

/// The plan, where the streak flame used to sit.
///
/// The streak appeared twice — here and in the stats row — and this is the more
/// useful of the two to carry at the top: it is the piece of state that decides
/// what the app will let the learner do next.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  static const _colours = {
    'free': [Color(0xFFA3AEBE), Color(0xFF7C8AA0)],
    'entry': [Color(0xFF38BDF8), Color(0xFF0284C7)],
    'main': [Color(0xFF34D399), Color(0xFF059669)],
    'pro': [Color(0xFFA78BFA), Color(0xFF6D28D9)],
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colours = _colours[tier] ?? _colours['free']!;
    final label = switch (tier) {
      'entry' => 'Entry',
      'main' => 'Main',
      'pro' => 'Pro',
      _ => l.tierFree,
    };
    return GestureDetector(
      onTap: () => context.push('/subscriptions'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colours,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: colours.last.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The measured level, or the absence of one.
///
/// Tappable either way, and rose rather than grey when missing: "not tested"
/// and "A1" are different facts, and a learner being taught at a guess should
/// be able to see that from the first screen.
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final String? level;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final has = (level ?? '').isNotEmpty;
    final accent = has ? AppColors.brandDeep : const Color(0xFFBE123C);
    final fill = has ? AppColors.brandTint : const Color(0xFFFFE4E6);
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.push('/placement'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                has ? l.levelLabel(level!) : l.homeLevelUnknown,
                style: TextStyle(
                  color: accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: accent.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── stats ─────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(gamificationProfileProvider).asData?.value;
    // The model already owns this rule; recomputing it here would be a second
    // place for the same division to drift.
    final goal = p?.goalRatio ?? 0.0;
    return Row(
      children: [
        Expanded(
          child: _Stat(
            icon: Icons.bolt_rounded,
            colour: AppColors.xp,
            value: '${p?.xp ?? 0}',
            label: l.statXp,
            progress: ((p?.xp ?? 0) % 100) / 100,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _Stat(
            icon: Icons.local_fire_department_rounded,
            colour: AppColors.streak,
            value: '${p?.streak ?? 0}',
            label: l.statStreak,
            progress: (p?.streak ?? 0) > 0 ? 1 : 0,
            tintValue: true,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: _Stat(
            icon: Icons.track_changes,
            colour: AppColors.brand,
            value: '${(goal * 100).round()}%',
            label: l.statGoal,
            progress: goal,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.colour,
    required this.value,
    required this.label,
    required this.progress,
    this.tintValue = false,
  });

  final IconData icon;
  final Color colour;
  final String value;
  final String label;
  final double progress;
  final bool tintValue;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
      boxShadow: AppShadow.soft,
    ),
    child: Column(
      children: [
        Icon(icon, size: 16, color: colour),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: tintValue ? colour : AppColors.ink,
            // Three cards side by side only read as one component if their
            // digits sit on the same rhythm.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.canvasAlt,
            color: colour,
          ),
        ),
      ],
    ),
  );
}

// ── the AI card ───────────────────────────────────────────────────────────

/// The primary action, wearing the same face the learner meets in Speaking.
///
/// A different avatar here would read as a different product. This is the one
/// element tying the home screen to the thing the app is actually for.
class _AiHeroCard extends ConsumerWidget {
  const _AiHeroCard({required this.level});

  final String level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Minutes left today, from the same endpoint the Speaking screen uses. Not
    // "5-10 minutes per session": on the free tier the whole day is eight, so a
    // promise per conversation can exceed the entire budget.
    final quota = ref.watch(speakingQuotaProvider).asData?.value;
    final card = GestureDetector(
      onTap: () => context.push('/speaking'),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: const Color(0xFF150B36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.42),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Three coloured lights over a dark base rather than one flat
            // gradient — the colour keeps moving across the card, which is
            // most of what separates this from a plain rectangle.
            const _Aurora(),
            Positioned(
              left: 0,
              bottom: 0,
              // The uncut artwork, faded out along its right edge.
              //
              // Cutting the boy out was tried and abandoned. The piece was
              // drawn as a whole scene: the rim light on his outline and the
              // shading under his arms only make sense against the background
              // they were painted for. Keying it away left the rim behind as a
              // pink outline and turned the gap under his arm into a black
              // patch — every fix traded one artifact for another, because
              // hair, shadow and background all share the same colours.
              // Kept whole, the lighting stays consistent and it reads as art
              // rather than as a sticker.
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, 0.60, 1],
                ).createShader(r),
                child: Image.asset(
                  'assets/hero/hero_base.png',
                  height: 138,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  // Decoded at display width; the source is 723×1087 and this
                  // runs on cheap Androids.
                  cacheWidth: 260,
                ),
              ),
            ),
            // A single diagonal highlight, the way light crosses glass.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1, -0.7),
                    end: const Alignment(1, 0.7),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.32, 0.48, 0.62],
                  ),
                ),
              ),
            ),
            // The card's only action, so it has to look like one — the old
            // flat translucent circle sank into the gradient and read as
            // decoration. Positioned over the card rather than inside the text
            // row, which is what left the chips no width.
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
            // The lit edge. Small, and it is what stops the card reading as a
            // flat shape cut out of the page.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(116, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.homeAiKicker.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l.homeAiTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.homeAiSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Chips get the row to themselves; the mic is positioned
                      // over the card instead of competing for the same width.
                      // Sharing it truncated both of them to "Daraj…" and
                      // "0 daq…" on a 393-wide screen.
                      if (level.isNotEmpty) _HeroChip(text: level),
                      if (quota != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _HeroChip(
                            text: l.minutesLeft(quota.minutesRemaining),
                            // Amber once the day is nearly spent. This is the
                            // moment the learner meets the wall, and the moment
                            // upgrading starts to mean something.
                            warn: quota.minutesRemaining <= 3,
                          ),
                        ),
                      ],
                      const SizedBox(width: 52),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Veiled while the tutor is still coming. The artwork and the headline are
    // the most convincing thing on this screen and they say what the app is
    // going to be — taking the card away would take that with it, so it stays
    // and the door closes instead.
    return ComingSoonVeil(
      enabled: !ref.watch(aiUnlockedProvider),
      label: l.comingSoon,
      dark: true,
      child: card,
    );
  }
}

/// Violet, indigo and sky bleeding into one another over a near-black base.
///
/// Three radial gradients rather than a `BackdropFilter`: the frosted look is a
/// translucent white fill and a light border, which is indistinguishable here
/// and costs nothing. A real blur is recomputed every frame in the Telegram
/// webview, and this project has already lost a screen to exactly that.
class _Aurora extends StatelessWidget {
  const _Aurora();

  static const _lights = [
    (Alignment(-0.85, -0.75), Color(0xFFA78BFA), 0.62, 1.5),
    (Alignment(0.75, 0.85), Color(0xFF38BDF8), 0.42, 1.4),
    (Alignment(0.2, -0.9), Color(0xFF6366F1), 0.55, 1.6),
  ];

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final (align, colour, alpha, radius) in _lights)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: align,
                radius: radius,
                colors: [
                  colour.withValues(alpha: alpha),
                  colour.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text, this.warn = false});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      gradient: warn
          ? const LinearGradient(
              colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
            )
          : null,
      color: warn ? null : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: Colors.white.withValues(alpha: warn ? 0.14 : 0.3),
      ),
      boxShadow: warn
          ? [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.55),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ── the untested state ────────────────────────────────────────────────────

class _Modules extends ConsumerWidget {
  const _Modules();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionRow(title: l.homeSpeakLive, trailing: l.homeSeeAll),
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
                  colours: const [Color(0xFF6D4BE8), Color(0xFF9F7BFF)],
                  // Real occupancy of the busiest open room, or nothing. The
                  // badge is the answer to "who is in there" and a made-up one
                  // would be found out the moment somebody walked in.
                  badge: ref
                      .watch(groupLobbyProvider)
                      .whenOrNull(
                        data: (rooms) {
                          final open = rooms.where((r) => r.isPublic).toList();
                          if (open.isEmpty) return null;
                          open.sort((a, b) => b.count.compareTo(a.count));
                          return '${open.first.count} / ${open.first.max}';
                        },
                      ),
                  onTap: () => context.push('/speaking/group'),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _LiveCard(
                  icon: Icons.record_voice_over_rounded,
                  title: l.homePeerTitle,
                  subtitle: l.homePeerSubtitle,
                  colours: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                  badge: ref
                      .watch(peerHubProvider)
                      .whenOrNull(
                        data: (hub) =>
                            hub.online > 0 ? l.homeOnlineN(hub.online) : null,
                      ),
                  // Straight into the search — but NOT straight past the
                  // microphone.
                  //
                  // This card is the busiest door into a live call, and it
                  // used to push the call route directly, so it walked around
                  // `ensureMicrophoneReady` entirely. Two learners then met in
                  // a room where NEITHER had ever been asked for a microphone:
                  // both sides negotiated receive-only, both told the other
                  // "my microphone is off", and both concluded the app was
                  // broken. It was reported as an iPhone-versus-Android fault
                  // and it was neither — the Android side had no microphone
                  // either, because nothing had asked for one.
                  //
                  // Every gesture that can start a call has to pass the gate.
                  // Pinned by `test/peer_mic_gate_coverage_test.dart`.
                  onTap: () async {
                    if (!await ensureMicrophoneReady(context, ref)) return;
                    if (!context.mounted) return;
                    context.push(
                      '/peer/call',
                      extra: const PeerLaunchMatch(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        _SectionRow(title: l.modules, trailing: l.homeSeeAll),
        const SizedBox(height: AppSpace.sm),
        // Two, not three. Speaking used to sit here as well — the same locked
        // tutor already filling the hero above, so the first two things on the
        // screen were both things nobody can open yet.
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
                  // Where this learner has got to, not how big the catalogue
                  // is. "91 dars" describes the app; "12 / 91" describes them,
                  // and only the second is a reason to open it.
                  chip: ref
                      .watch(coursePathProvider)
                      .whenOrNull(
                        data: (levels) {
                          var done = 0;
                          var total = 0;
                          for (final level in levels) {
                            for (final unit in level.units) {
                              total += 1;
                              if (unit.state == UnitState.done) done += 1;
                            }
                          }
                          return total > 0
                              ? l.homeLessonsAt(done, total)
                              : null;
                        },
                      ),
                  onTap: () => context.push('/course'),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _ModuleTile(
                  icon: Icons.sports_esports_rounded,
                  colour: AppColors.placement,
                  title: l.gamesTitle,
                  subtitle: l.homeGamesSub,
                  // Solo, against Gainsy, the online duel, spelling, and the
                  // live quiz. A fixed fact about the app, not a guess.
                  chip: l.homeGamesN(5),
                  onTap: () => context.push('/games'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.colour,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.chip,
  });

  final IconData icon;
  final Color colour;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  /// One concrete number — "91 dars", "5 o'yin". Omitted rather than guessed
  /// when the real figure has not loaded.
  final String? chip;

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    clipBehavior: Clip.antiAlias,
    color: AppColors.surface,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
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
      ),
    ),
  );
}

class _LeaderboardPreview extends ConsumerWidget {
  const _LeaderboardPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final board = ref.watch(leaderboardProvider(false)).asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionRow(title: l.leaderboardTitle, trailing: l.leaderboardThisWeek),
        const SizedBox(height: AppSpace.sm),
        if (board == null)
          const SizedBox(height: 64, child: AppLoader())
        else if (board.isEmpty)
          _EmptyBoard(
            message: l.leaderboardEmpty,
            hint: l.leaderboardFirstPlaceOpen,
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadow.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final s in board.top.take(3)) _PreviewRow(standing: s),
                if (board.needsOwnRow) ...[
                  const Divider(height: 1, color: AppColors.line),
                  _PreviewRow(standing: board.you!),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.standing});

  final Standing standing;

  static const _medals = {
    1: [Color(0xFFFCD34D), Color(0xFFD97706)],
    2: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
    3: [Color(0xFFFDBA74), Color(0xFFC2410C)],
  };

  static const _palette = [
    [Color(0xFFF472B6), Color(0xFFDB2777)],
    [Color(0xFF38BDF8), Color(0xFF0369A1)],
    [Color(0xFFA78BFA), Color(0xFF6D28D9)],
    [Color(0xFF34D399), Color(0xFF059669)],
    [Color(0xFFFBBF24), Color(0xFFD97706)],
  ];

  @override
  Widget build(BuildContext context) {
    final medal = _medals[standing.rank];
    final colours = _palette[standing.name.hashCode.abs() % _palette.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 9),
      color: standing.isYou
          ? AppColors.brand.withValues(alpha: 0.09)
          : Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal == null ? AppColors.canvasAlt : null,
              gradient: medal == null ? null : LinearGradient(colors: medal),
            ),
            child: Text(
              '${standing.rank}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: medal == null ? AppColors.inkSoft : Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colours),
              border: Border.all(
                color: standing.isYou ? AppColors.brand : AppColors.line,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: UserPhoto.resolve(standing.avatarUrl) != null
                ? Image.network(
                    UserPhoto.resolve(standing.avatarUrl)!,
                    fit: BoxFit.cover,
                    // Telegram's picture URLs expire; initials beat the broken
                    // image glyph that would otherwise land in the row.
                    errorBuilder: (_, _, _) => _initials(),
                  )
                : _initials(),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              standing.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: standing.isYou ? AppColors.brandDeep : AppColors.ink,
              ),
            ),
          ),
          Text(
            '${standing.xp}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: standing.isYou ? AppColors.brandDeep : AppColors.inkSoft,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials() => Center(
    child: Text(
      standing.initial,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.message, required this.hint});

  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.xl,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 5),
        // Not consolation. With this many learners it is literally true, and
        // it is the strongest thing an empty board can say.
        Text(
          hint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.brandDeep,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, this.trailing});

  final String title;
  final String? trailing;

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
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
    ],
  );
}

/// A live-speaking entry, given the room it deserves.
///
/// Stacked inside and paired outside. Everything else on this screen is
/// practice you do alone; these two are the ones where somebody answers back,
/// which is the whole reason the app exists — so they are the brightest thing
/// on the page and they sit above the rest, not among it.
class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colours,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colours;
  final VoidCallback onTap;

  /// Live occupancy — "7 / 50", "2 online" — or null when there is nobody.
  ///
  /// Never a placeholder. An invented number here is found out the moment
  /// somebody taps through and walks into an empty room, and after that the
  /// real numbers elsewhere stop being believed too.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = badge != null;
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      color: colours.first,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
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
              // Status and headcount on one line: whether there is anything
              // going on, and how much of it.
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
              // The action inside the card. The whole card is tappable, but a
              // button says what happens — and for the partner card what
              // happens is the search itself, not a menu about it.
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
        ),
      ),
    );
  }
}
