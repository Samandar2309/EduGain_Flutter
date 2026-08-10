import 'package:flutter/material.dart';

import '../../../../core/ui/glass.dart';
import '../../../../core/ui/tokens.dart';

/// A coloured Easy / Medium / Hard pill (the lesson's difficulty at a glance).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({required this.difficulty, super.key});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final (label, color, dot) = switch (difficulty) {
      'easy' => ('Easy', AppColors.success, '🟢'),
      'hard' => ('Hard', AppColors.danger, '🔴'),
      _ => ('Medium', AppColors.warning, '🟡'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$dot $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A compact "icon + label" meta chip (estimated time, XP reward, CEFR…).
class MetaChip extends StatelessWidget {
  const MetaChip({
    required this.icon,
    required this.label,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// A reusable lesson row: title + subtitle + a meta line (difficulty · time ·
/// XP) with done / locked / premium affordances. Used on the Speaking home
/// (recommended) and inside a track. Pure presentation — the parent supplies the
/// accent + tap handler.
class LessonTile extends StatelessWidget {
  const LessonTile({
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.estMinutes,
    required this.xpReward,
    required this.accent,
    required this.onTap,
    this.grammarFocus,
    this.isPremium = false,
    this.isLocked = false,
    this.isDone = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String difficulty;
  final int estMinutes;
  final int xpReward;
  final Color accent;
  final VoidCallback onTap;
  final String? grammarFocus;
  final bool isPremium;
  final bool isLocked;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.55 : 1,
      child: GlassPanel(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Row(
            children: [
              _LeadingMark(isDone: isDone, accent: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.military_tech,
                              size: 15, color: accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DifficultyBadge(difficulty: difficulty),
                        MetaChip(
                          icon: Icons.schedule_rounded,
                          label: '$estMinutes min',
                        ),
                        MetaChip(
                          icon: Icons.bolt_rounded,
                          label: '+$xpReward XP',
                          color: AppColors.xp,
                        ),
                      ],
                    ),
                    if ((grammarFocus ?? '').isNotEmpty) ...[
                      const SizedBox(height: 7),
                      // A full-width row so a long focus line truncates cleanly
                      // instead of overflowing the card.
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              size: 13, color: Colors.white54),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Focus: ${grammarFocus!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLocked
                    ? Icons.lock_rounded
                    : (isDone ? Icons.replay_rounded : Icons.chevron_right_rounded),
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular leading mark: a tick when completed, else an accent waveform.
class _LeadingMark extends StatelessWidget {
  const _LeadingMark({required this.isDone, required this.accent});
  final bool isDone;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.success : accent;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDone ? 0.18 : 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Icon(
        isDone ? Icons.check_rounded : Icons.graphic_eq_rounded,
        size: 20,
        color: color,
      ),
    );
  }
}
