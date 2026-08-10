import 'package:flutter/material.dart';

import '../../../../core/ui/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models.dart';

/// The scoreboard.
///
/// The first version was a flat list with a number in a box, which reads as a
/// table of results rather than as a game. A quiz's board is the reward — it is
/// the thing people look at between questions — so the top three get a podium
/// with the winner raised, and everybody else gets a clean row underneath.
///
/// It always ends with where *you* stand, even when you are nowhere near the
/// top. A board that stops at tenth says nothing to the eleventh player, and
/// the eleventh player is the one still deciding whether to stay.
class QuizBoardView extends StatelessWidget {
  const QuizBoardView({
    required this.board,
    required this.title,
    this.podium = false,
    this.limit = 3,
    super.key,
  });

  final QuizBoard board;
  final String title;

  /// Full treatment: three columns on a podium, then the rest as rows. Used
  /// between matches, where the board is the whole screen.
  final bool podium;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = board.top;
    final you = board.you;

    if (podium && all.length >= 3) {
      final rest = all.skip(3).take(limit).toList();
      final youIsListed = all.take(3 + rest.length).any((p) => p.isYou);
      return _Shell(
        title: title,
        children: [
          _Podium(top: all.take(3).toList()),
          if (rest.isNotEmpty) const SizedBox(height: AppSpace.md),
          for (final player in rest) _Row(player: player, dense: false),
          if (you != null && !youIsListed) ...[
            const Divider(height: AppSpace.xl, color: AppColors.line),
            _Row(player: you, dense: false),
          ],
        ],
      );
    }

    final shown = all.take(limit).toList();
    final youIsListed = shown.any((p) => p.isYou);
    return _Shell(
      title: title,
      children: [
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Text(
              l10n.quizNoScoreYet,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkFaint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (final player in shown) _Row(player: player, dense: !podium),
        if (you != null && !youIsListed) ...[
          const Divider(height: AppSpace.lg, color: AppColors.line),
          _Row(player: you, dense: !podium),
        ],
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.md,
      AppSpace.lg,
      AppSpace.lg,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadow.soft,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.inkFaint,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        ...children,
      ],
    ),
  );
}

/// Second, first, third — the arrangement everybody already reads without
/// being told, which is why the winner is in the middle and not on the left.
class _Podium extends StatelessWidget {
  const _Podium({required this.top});

  final List<QuizPlayer> top;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(child: _Step(player: top[1], height: 58)),
      const SizedBox(width: AppSpace.sm),
      Expanded(child: _Step(player: top[0], height: 78)),
      const SizedBox(width: AppSpace.sm),
      Expanded(child: _Step(player: top[2], height: 44)),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.player, required this.height});

  final QuizPlayer player;
  final double height;

  Color get _medal => switch (player.rank) {
    1 => AppColors.xp,
    2 => AppColors.inkFaint,
    _ => AppColors.streak,
  };

  @override
  Widget build(BuildContext context) {
    final winner = player.rank == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Avatar(
          initial: player.initial,
          colour: _medal,
          size: winner ? 48 : 40,
          ring: player.isYou,
        ),
        const SizedBox(height: 6),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: player.isYou ? FontWeight.w800 : FontWeight.w700,
            color: player.isYou ? AppColors.brandDeep : AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: _medal.withValues(alpha: winner ? 0.18 : 0.10),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
          ),
          child: Text(
            '${player.points}',
            style: TextStyle(
              fontSize: winner ? 17 : 15,
              fontWeight: FontWeight.w800,
              color: _medal == AppColors.inkFaint ? AppColors.inkSoft : _medal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.colour,
    required this.size,
    this.ring = false,
  });

  final String initial;
  final Color colour;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.16),
      shape: BoxShape.circle,
      border: ring ? Border.all(color: AppColors.brand, width: 2) : null,
    ),
    child: Text(
      initial,
      style: TextStyle(
        fontSize: size * 0.42,
        fontWeight: FontWeight.w800,
        color: colour == AppColors.inkFaint ? AppColors.inkSoft : colour,
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.player, required this.dense});

  final QuizPlayer player;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final medal = switch (player.rank) {
      1 => AppColors.xp,
      2 => AppColors.inkFaint,
      3 => AppColors.streak,
      _ => AppColors.line,
    };
    final highlight = player.isYou;
    return Container(
      margin: EdgeInsets.only(bottom: dense ? 4 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: highlight ? 10 : 0,
        vertical: dense ? 5 : 8,
      ),
      decoration: highlight
          ? BoxDecoration(
              color: AppColors.brandTint.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              player.rank > 0 ? '${player.rank}' : '–',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: player.rank <= 3 ? medal : AppColors.inkFaint,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          _Avatar(
            initial: player.initial,
            colour: player.rank <= 3 ? medal : AppColors.inkFaint,
            size: dense ? 26 : 32,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 14 : 15,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppColors.brandDeep : AppColors.ink,
              ),
            ),
          ),
          Text(
            '${player.points}',
            style: TextStyle(
              fontSize: dense ? 14 : 15,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.brandDeep : AppColors.inkSoft,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
