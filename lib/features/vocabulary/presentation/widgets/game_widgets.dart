import 'package:flutter/material.dart';

import '../../../../core/ui/tokens.dart';
import '../../domain/game.dart';

/// Reusable game UI shared by the solo/bot screen and the online duel screen,
/// so a question looks and behaves identically however it's played.

enum OptionState { idle, correct, wrong, dimmed }

/// The prompt card + the four tap options for one question.
class QuestionView extends StatelessWidget {
  const QuestionView({
    required this.question,
    required this.picked,
    required this.onPick,
    super.key,
  });

  final GameQuestion question;
  final int? picked;
  final void Function(int) onPick;

  String get _instruction => switch (question.kind) {
    QuestionKind.wordToMeaning => 'Tarjimasini tanlang',
    QuestionKind.meaningToWord => "So'zni tanlang",
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.md),
          Text(
            _instruction.toUpperCase(),
            style: const TextStyle(
              color: AppColors.inkFaint,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadow.card,
                ),
                child: Text(
                  question.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          ...List.generate(question.options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: OptionButton(
                label: question.options[i],
                state: _stateFor(i),
                onTap: picked == null ? () => onPick(i) : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  OptionState _stateFor(int i) {
    if (picked == null) return OptionState.idle;
    if (i == question.correctIndex) return OptionState.correct;
    if (i == picked) return OptionState.wrong;
    return OptionState.dimmed;
  }
}

class OptionButton extends StatelessWidget {
  const OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String label;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (state) {
      OptionState.idle => (AppColors.surface, AppColors.line, AppColors.ink, null),
      OptionState.correct => (
        AppColors.success.withValues(alpha: 0.12),
        AppColors.success,
        AppColors.brandDeep,
        Icons.check_circle_rounded,
      ),
      OptionState.wrong => (
        AppColors.danger.withValues(alpha: 0.10),
        AppColors.danger,
        AppColors.danger,
        Icons.cancel_rounded,
      ),
      OptionState.dimmed => (AppColors.canvasAlt, AppColors.line, AppColors.inkFaint, null),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 1.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
              if (icon != null) Icon(icon, color: border, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class ComboBadge extends StatelessWidget {
  const ComboBadge({required this.combo, super.key});
  final int combo;

  @override
  Widget build(BuildContext context) {
    final on = combo >= 2;
    return AnimatedOpacity(
      opacity: on ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.streak.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppColors.streak, size: 16),
            const SizedBox(width: 3),
            Text(
              '$combo',
              style: const TextStyle(
                color: AppColors.streak, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two racing progress bars (you vs opponent) shown above a duel.
class RaceBar extends StatelessWidget {
  const RaceBar({
    required this.youProgress,
    required this.opponentProgress,
    required this.opponentName,
    super.key,
  });

  final double youProgress;
  final double opponentProgress;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      child: Column(
        children: [
          _racer('Siz', youProgress, AppColors.vocabulary, leading: true),
          const SizedBox(height: 6),
          _racer(opponentName, opponentProgress, AppColors.speaking, leading: false),
        ],
      ),
    );
  }

  Widget _racer(String name, double v, Color color, {required bool leading}) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: leading ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: v.clamp(0, 1),
              minHeight: 7,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// The end-of-game panel — solo score or duel head-to-head, XP/combo/accuracy,
/// the Speaking bridge note, and the two actions.
class GameResultsView extends StatelessWidget {
  const GameResultsView({
    required this.result,
    required this.onAgain,
    required this.onDone,
    this.opponentName = 'Gainsy',
    this.bridgeNote = "Bu so'zlar endi Speaking mashg'ulotida tayyor 🎯",
    super.key,
  });

  final GameResult result;
  final VoidCallback onAgain;
  final VoidCallback onDone;
  final String opponentName;
  final String bridgeNote;

  @override
  Widget build(BuildContext context) {
    final duel = result.mode != GameMode.solo;
    final won = result.youWon ?? true;
    final (emoji, headline, color) = duel
        ? (
            won ? '🏆' : '💪',
            won ? 'Siz yutdingiz!' : '$opponentName bu safar oldinda',
            won ? AppColors.success : AppColors.speaking,
          )
        : ('🎉', 'Ajoyib ish!', AppColors.vocabulary);

    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        children: [
          const Spacer(),
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: AppSpace.md),
          Text(headline,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: AppSpace.xl),
          Container(
            padding: const EdgeInsets.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              children: [
                if (duel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scoreCol('Siz', result.correct, AppColors.vocabulary),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: Text('—',
                            style: TextStyle(color: AppColors.inkFaint, fontSize: 22)),
                      ),
                      _scoreCol(
                          opponentName, result.opponentCorrect ?? 0, AppColors.speaking),
                    ],
                  )
                else
                  _scoreCol('To‘g‘ri javob', result.correct, AppColors.vocabulary,
                      suffix: '/${result.total}'),
                const Divider(height: AppSpace.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('+${result.xpEarned}', 'XP', AppColors.xp),
                    _stat('${result.bestCombo}', 'Kombo', AppColors.streak),
                    _stat('${(result.accuracy * 100).round()}%', 'Aniqlik', AppColors.grammar),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.speaking.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded,
                    color: AppColors.speaking, size: 20),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    bridgeNote,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Tugatish'),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: FilledButton(
                  onPressed: onAgain,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vocabulary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Yana o‘ynash'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreCol(String label, int value, Color color, {String? suffix}) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            text: '$value',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color),
            children: [
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.inkFaint),
                ),
            ],
          ),
        ),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkFaint, fontSize: 12.5)),
      ],
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(color: AppColors.inkFaint, fontSize: 11.5)),
      ],
    );
  }
}
