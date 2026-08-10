import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/user_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/leaderboard.dart';

/// The weekly XP board.
///
/// Last week sits behind a toggle rather than being dropped: this week's
/// standings reset at midnight on Sunday, so without it the winner's name
/// disappears before anyone sees it and the board becomes a scoreboard nobody
/// reads the end of.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _previous = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final board = ref.watch(leaderboardProvider(_previous));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.leaderboardTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  _WeekToggle(
                    previous: _previous,
                    onChanged: (v) => setState(() => _previous = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: board.when(
                loading: () => const AppLoader(),
                error: (_, _) => Center(child: Text(l.loadFailed)),
                data: (b) => b.isEmpty
                    ? _Empty(previous: _previous)
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(leaderboardProvider(_previous)),
                        child: _Board(board: b),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekToggle extends StatelessWidget {
  const _WeekToggle({required this.previous, required this.onChanged});

  final bool previous;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.canvasAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          _seg(l.leaderboardThisWeek, !previous, () => onChanged(false)),
          _seg(l.leaderboardLastWeek, previous, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: on ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: on ? AppShadow.soft : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: on ? AppColors.brandDeep : AppColors.inkSoft,
        ),
      ),
    ),
  );
}

class _Board extends StatelessWidget {
  const _Board({required this.board});

  final Leaderboard board;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 110),
      children: [
        _Podium(places: board.podium),
        const SizedBox(height: AppSpace.md),
        if (board.you != null) ...[
          _YouCard(board: board),
          const SizedBox(height: AppSpace.md),
        ],
        if (board.rest.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadow.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [for (final s in board.rest) _Row(standing: s)],
            ),
          ),
        if (board.you == null) ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            l.leaderboardNotRankedYet,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

// ── the podium ────────────────────────────────────────────────────────────

/// First, second and third, each given its own look.
///
/// A ranked list already says who won; the podium says it is worth winning.
/// First is raised, wider and crowned so the difference reads before any number
/// does — the ranking is the information, this is the reason to care about it.
class _Podium extends StatelessWidget {
  const _Podium({required this.places});

  final List<Standing> places;

  @override
  Widget build(BuildContext context) {
    // Second, first, third — first in the middle and standing highest.
    final second = places.length > 1 ? places[1] : null;
    final first = places.isNotEmpty ? places[0] : null;
    final third = places.length > 2 ? places[2] : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(flex: 10, child: _Place(standing: second, place: 2)),
          const SizedBox(width: 6),
          Expanded(flex: 12, child: _Place(standing: first, place: 1)),
          const SizedBox(width: 6),
          Expanded(flex: 10, child: _Place(standing: third, place: 3)),
        ],
      ),
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.standing, required this.place});

  final Standing? standing;
  final int place;

  static const _ring = {
    1: Color(0xFFFBBF24),
    2: Color(0xFFCBD5E1),
    3: Color(0xFFFDBA74),
  };
  static const _medal = {
    1: [Color(0xFFFCD34D), Color(0xFFD97706)],
    2: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
    3: [Color(0xFFFDBA74), Color(0xFFC2410C)],
  };
  @override
  Widget build(BuildContext context) {
    final s = standing;
    // A board with only two people still has a first and a second. The empty
    // plinth keeps the shape rather than reflowing it into something else.
    if (s == null) return const SizedBox(height: 190);

    final first = place == 1;
    final size = first ? 70.0 : 50.0;
    return Padding(
      // The height difference has to be obvious before any number is read —
      // that is the whole job of a podium.
      padding: EdgeInsets.fromLTRB(2, first ? 0 : 22, 2, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            child: first
                ? const Icon(
                    Icons.military_tech,
                    size: 18,
                    color: Color(0xFFD97706),
                  )
                : null,
          ),
          _Avatar(standing: s, size: size, ring: _ring[place]!, ringWidth: 3),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _medal[place]!),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Text(
                '$place',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: first ? 13.5 : 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${s.xp}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDeep,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (s.streak > 0) ...[
            const SizedBox(height: 5),
            _Streak(days: s.streak, size: 10),
          ],
          const SizedBox(height: 8),
          _Plinth(place: place, tall: first),
        ],
      ),
    );
  }
}

/// The step each winner stands on.
///
/// Height is the whole point: the ranking has to be readable across the room,
/// before any name or number is. Deliberately in the app's own tints rather
/// than the dark blue-and-gold of the reference — a leaderboard that arrives
/// in another app's palette reads as a page someone else built.
class _Plinth extends StatelessWidget {
  const _Plinth({required this.place, required this.tall});

  final int place;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final shade = _Place._medal[place]!;
    return Container(
      height: tall ? 62 : 36,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            shade[0].withValues(alpha: 0.55),
            shade[1].withValues(alpha: 0.28),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Text(
        '$place',
        style: TextStyle(
          fontSize: tall ? 26 : 20,
          fontWeight: FontWeight.w900,
          height: 1,
          color: shade[1].withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

// ── your standing ─────────────────────────────────────────────────────────

/// Where the learner is, and what it would take to move up one.
///
/// The gap is the part that matters: a rank on its own is a verdict, while
/// "40 XP to 6th" is something to do this evening. It is computed from the
/// list already on screen, so it costs nothing to show.
class _YouCard extends StatelessWidget {
  const _YouCard({required this.board});

  final Leaderboard board;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final you = board.you!;
    final next = board.toNextPlace;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.brandTint,
            AppColors.brandTint.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  l.leaderboardYou.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '#${you.rank}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDeep,
                  letterSpacing: -1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpace.md),
          _Avatar(
            standing: you,
            size: 44,
            ring: AppColors.brand,
            ringWidth: 2.5,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  you.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${next.rank}${l.leaderboardPlaceSuffix} '),
                        TextSpan(
                          text: '${next.xp} XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDeep,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: board.gapProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      color: AppColors.brand,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    l.leaderboardYouAreFirst,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.brandDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${you.xp}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                'XP',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── the rest of the list ──────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({required this.standing});

  final Standing standing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 9),
    decoration: BoxDecoration(
      color: standing.isYou
          ? AppColors.brand.withValues(alpha: 0.09)
          : Colors.transparent,
      border: const Border(top: BorderSide(color: AppColors.line, width: 0.6)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '${standing.rank}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.inkFaint,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        _Avatar(standing: standing, size: 32, ring: AppColors.line),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                standing.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: standing.isYou ? AppColors.brandDeep : AppColors.ink,
                ),
              ),
              if (standing.streak > 0) _Streak(days: standing.streak),
            ],
          ),
        ),
        Text(
          '${standing.xp}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: standing.isYou ? AppColors.brandDeep : AppColors.inkSoft,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

class _Streak extends StatelessWidget {
  const _Streak({required this.days, this.size = 10.5});

  final int days;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          size: size + 2,
          color: AppColors.streak,
        ),
        const SizedBox(width: 2),
        Text(
          l.leaderboardStreakDays(days),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: AppColors.streak,
          ),
        ),
      ],
    );
  }
}

/// The Telegram picture, or initials.
///
/// A private profile has no photo, and that is ordinary rather than broken —
/// so the fallback is designed. The colour comes from the name so it is the
/// same every time they appear; a random one would reshuffle the list on every
/// open.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.standing,
    required this.size,
    required this.ring,
    this.ringWidth = 2,
  });

  final Standing standing;
  final double size;
  final Color ring;
  final double ringWidth;

  static const _palette = [
    [Color(0xFFF472B6), Color(0xFFDB2777)], // pink
    [Color(0xFF38BDF8), Color(0xFF0369A1)], // sky
    [Color(0xFFA78BFA), Color(0xFF6D28D9)], // violet
    [Color(0xFF34D399), Color(0xFF059669)], // emerald
    [Color(0xFFFBBF24), Color(0xFFD97706)], // amber
    [Color(0xFFFB7185), Color(0xFFBE123C)], // rose
    [Color(0xFF2DD4BF), Color(0xFF0F766E)], // teal
    [Color(0xFF818CF8), Color(0xFF4338CA)], // indigo
  ];

  /// Spread the palette by mixing every character.
  ///
  /// `String.hashCode` is not uniform over a small modulus for short names —
  /// Ali, Aziz and Dilnoza all landed on the same green, so the whole podium
  /// came out one colour and looked like a bug.
  static int _slot(String name) {
    var h = 7;
    for (final unit in name.codeUnits) {
      h = (h * 31 + unit) & 0x7FFFFFFF;
    }
    return h % _palette.length;
  }

  @override
  Widget build(BuildContext context) {
    final colours = _palette[_slot(standing.name)];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colours,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: ring, width: ringWidth),
        boxShadow: [
          BoxShadow(
            color: ring.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // ClipOval rather than relying on the Container's own clip.
      //
      // `clipBehavior` with `BoxShape.circle` is supposed to be enough and is
      // what this used to do — but the photo came out SQUARE in the 32px list
      // rows while the larger podium ones were round, so whatever the cause,
      // the guarantee was not one. An explicit clip is a guarantee.
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: UserPhoto.resolve(standing.avatarUrl) != null
          ? Image.network(
              UserPhoto.resolve(standing.avatarUrl)!,
              fit: BoxFit.cover,
              // Telegram's picture URLs expire; initials beat the broken-image
              // glyph that would otherwise land in the row.
              errorBuilder: (_, _, _) => _initials(),
              loadingBuilder: (_, child, p) => p == null ? child : _initials(),
              // Fill the circle: without it a non-square source is letterboxed
              // and the gradient shows through as two bright wedges.
              width: size,
              height: size,
            )
          : _initials(),
      ),
    );
  }

  Widget _initials() => Center(
    child: Text(
      standing.initial,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.4,
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.previous});

  final bool previous;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 54,
              color: AppColors.inkFaint,
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              previous ? l.leaderboardEmptyLastWeek : l.leaderboardEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
            ),
            if (!previous) ...[
              const SizedBox(height: AppSpace.sm),
              // Not a consolation message. With this many learners it is
              // literally true, and it is the strongest thing an empty board
              // can say.
              Text(
                l.leaderboardFirstPlaceOpen,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.brandDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                l.leaderboardResetsMonday,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
