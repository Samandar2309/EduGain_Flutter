import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// The question bank's front door: which part, then how many topics are in it.
///
/// Three screens deep — part, topic, questions — because each answers one
/// question and nothing else. The alternative, one long scroll of every
/// question we have, is unusable at the moment it matters: someone mid-
/// conversation looking for something to ask next.
class QuestionPartsScreen extends ConsumerWidget {
  const QuestionPartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bank = ref.watch(questionBankProvider);
    final saved = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l.questionsTitle)),
      body: bank.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Retry(onRetry: () => ref.invalidate(questionBankProvider)),
        data: (parts) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          children: [
            Text(
              l.questionsIntro,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (var i = 0; i < parts.length; i++) ...[
              _PartCard(
                part: parts[i],
                // Our own accent family, not four unrelated saturated blocks:
                // the parts are siblings and should look like it.
                color: _partColors[i % _partColors.length],
                onTap: () => context.push('/questions/part', extra: parts[i]),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            if (saved.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              _SavedCard(
                count: saved.length,
                label: l.questionsSaved,
                onTap: () => context.push('/questions/saved'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const _partColors = [AppColors.speaking, AppColors.grammar, AppColors.vocabulary];

class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.part,
    required this.color,
    required this.onTap,
  });

  final QuestionPart part;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: '${part.title}. ${part.subtitle}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadow.card,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.forum, color: color, size: 22),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      part.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.questionsTopicCount(part.topicCount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.brandTint,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bookmark, color: AppColors.brandDeep),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDeep,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.brandDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.questionsError, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: AppSpace.md),
          FilledButton(onPressed: onRetry, child: Text(l.retry)),
        ],
      ),
    );
  }
}
