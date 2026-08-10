import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// A Part 2 card, laid out the way the real one is.
///
/// Deliberately plain and a little formal. Everything else in the app is
/// written to put a nervous learner at ease; this is the one thing that will
/// not be phrased kindly on the day, so softening it here would teach the
/// wrong reflex.
///
/// The closing line sits apart from the bullets because it is where most of
/// the marks are and the first thing people skip — merged into the list it
/// reads as a fourth optional point.
class CueCardScreen extends ConsumerWidget {
  const CueCardScreen({required this.topic, super.key});

  final QuestionTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final card = topic.cueCard!;
    final saved = ref.watch(bookmarksProvider).contains(card.prompt);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(topic.title),
        actions: [
          IconButton(
            tooltip: l.questionsSaved,
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(bookmarksProvider.notifier).toggle(card.prompt);
            },
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_outline,
              color: saved ? AppColors.brand : AppColors.inkFaint,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          Row(
            children: [
              _Timing(
                icon: Icons.timer,
                label: l.cueCardPrep(card.prepSeconds ~/ 60),
              ),
              const SizedBox(width: AppSpace.sm),
              _Timing(
                icon: Icons.record_voice_over,
                label: l.cueCardTalk(card.talkSeconds ~/ 60),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.prompt,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  l.cueCardYouShouldSay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                for (final bullet in card.bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 9, right: 10),
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    card.closing,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            l.cueCardHint,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _Timing extends StatelessWidget {
  const _Timing({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
