import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models.dart';

/// "How to answer this" — a weak reply, a better one, and what changed.
///
/// The two-answer shape is the whole design. One model answer is what learners
/// memorise, examiners are trained to spot memorised answers and mark them
/// down, so shipping one would sell a habit that costs the buyer marks. A pair
/// cannot be memorised — which of the two? — but the difference between them
/// transfers to any question.
///
/// The weak version comes first and is written to be recognisable rather than
/// absurd: someone has to meet their own habit before they will drop it.
class WorkedAnswerCard extends StatefulWidget {
  const WorkedAnswerCard({required this.worked, super.key});

  final WorkedAnswer worked;

  @override
  State<WorkedAnswerCard> createState() => _WorkedAnswerCardState();
}

class _WorkedAnswerCardState extends State<WorkedAnswerCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = widget.worked;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed by default: this is a study aid, and someone mid-call
          // scrolling for a question should not have to scroll past an essay.
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                children: [
                  const Icon(Icons.school,
                      size: 19, color: AppColors.brand),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      l.workedTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDeep,
                      ),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                0,
                AppSpace.md,
                AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _Answer(
                    label: l.workedWeak,
                    text: w.weak,
                    tint: AppColors.canvas,
                    labelColor: AppColors.inkFaint,
                    borderColor: AppColors.line,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  _Answer(
                    label: l.workedStrong,
                    text: w.strong,
                    tint: AppColors.brandTint,
                    labelColor: AppColors.brandDeep,
                    borderColor: AppColors.brand.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    l.workedMoves,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final move in w.moves)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check,
                              size: 15, color: AppColors.success),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              move,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
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

class _Answer extends StatelessWidget {
  const _Answer({
    required this.label,
    required this.text,
    required this.tint,
    required this.labelColor,
    required this.borderColor,
  });

  final String label;
  final String text;
  final Color tint;
  final Color labelColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the card when the learner's tier cannot open it.
///
/// Says what is behind it rather than just that something is locked: "Premium"
/// alone tells nobody whether it is worth paying for.
class WorkedAnswerLocked extends StatelessWidget {
  const WorkedAnswerLocked({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 18, color: AppColors.xp),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  l.workedLocked,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.workedLockedWhy,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/subscriptions'),
              child: Text(l.workedOpen),
            ),
          ),
        ],
      ),
    );
  }
}
