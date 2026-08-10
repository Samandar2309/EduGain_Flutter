import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// The questions themselves — one per card, deliberately roomy.
///
/// This is the only screen here that gets read *while talking*, glanced at
/// between sentences rather than studied. So: large type, one question per
/// card, plenty of air. Packing them tighter would fit more on screen and make
/// every one of them harder to find again mid-conversation.
class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({required this.topic, super.key});

  final QuestionTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(topic.title)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        itemCount: topic.questions.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
        itemBuilder: (context, i) {
          if (i == 0) {
            final follows = topic.followsTitle;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (follows != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l.questionsFollows(follows),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                  Text(
                    follows == null ? l.questionsUseHint : l.questionsPart3Hint,
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
          final question = topic.questions[i - 1];
          return _QuestionCard(
            question: question,
            isSaved: saved.contains(question),
            onSave: () {
              HapticFeedback.selectionClick();
              ref.read(bookmarksProvider.notifier).toggle(question);
            },
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.isSaved,
    required this.onSave,
  });

  final String question;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Semantics(
            button: true,
            selected: isSaved,
            child: IconButton(
              onPressed: onSave,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_outline,
                color: isSaved ? AppColors.brand : AppColors.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything the learner bookmarked, across every topic.
class SavedQuestionsScreen extends ConsumerWidget {
  const SavedQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(bookmarksProvider).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l.questionsSaved)),
      body: saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Text(
                  l.questionsNoneSaved,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.xxl,
              ),
              itemCount: saved.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (context, i) => _QuestionCard(
                question: saved[i],
                isSaved: true,
                onSave: () {
                  HapticFeedback.selectionClick();
                  ref.read(bookmarksProvider.notifier).toggle(saved[i]);
                },
              ),
            ),
    );
  }
}
