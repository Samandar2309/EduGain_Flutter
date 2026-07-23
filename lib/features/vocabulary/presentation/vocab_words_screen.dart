import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/pronounce_service.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// The "So'zlarni o'rganish" dictionary — a calm, read-only list of a set's
/// words with their Uzbek translation and an example. No grading, no pressure:
/// this is where the learner meets the words before testing on them.
class VocabWordsScreen extends ConsumerWidget {
  const VocabWordsScreen({required this.set, super.key});

  final VocabSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(vocabSetDetailProvider(set.id));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(set.title),
        backgroundColor: AppColors.canvas,
      ),
      body: detail.when(
        loading: () => const AppLoader(),
        error: (_, _) => Center(child: Text(l.loadFailed)),
        data: (d) => d.items.isEmpty
            ? Center(child: Text(l.noWords))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xxl),
                itemCount: d.items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
                itemBuilder: (context, i) {
                  if (i == 0) return _CountHeader(count: d.items.length);
                  return _WordCard(item: d.items[i - 1]);
                },
              ),
      ),
    );
  }
}

class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.style_rounded, size: 16, color: AppColors.vocabulary),
          const SizedBox(width: 6),
          Text(
            "$count ta so'z",
            style: const TextStyle(
              color: AppColors.inkSoft, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends ConsumerWidget {
  const _WordCard({required this.item});

  final VocabItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.soft,
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.translationUz,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.vocabulary,
                      ),
                    ),
                  ],
                ),
              ),
              // Tap to hear the English pronunciation.
              Material(
                color: AppColors.vocabulary.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => ref.read(pronouncerProvider).speak(item.word),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.volume_up_rounded,
                        color: AppColors.vocabulary, size: 22),
                  ),
                ),
              ),
            ],
          ),
          if (item.example.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                item.example,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.inkSoft,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
