import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens.dart';
import '../application/pronounce_service.dart';
import '../application/word_pool.dart';
import '../domain/models.dart';

/// The words to memorise, by theme.
///
/// Two versions of this were wrong before it landed here. The first read the
/// game deck — twenty-four words — so the catalogue could grow by six hundred
/// and this screen would not change. The second returned all 782 in one flat
/// scroll, which is not a vocabulary either; it is a wall.
///
/// Words are authored in themes and learned in themes, so that is how they are
/// shown: pick a theme, see its words. Nearest the learner's own level first.
class WordsToLearnScreen extends ConsumerWidget {
  const WordsToLearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(wordGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Yodlash kerak'),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Message(
          text: 'So‘zlarni yuklab bo‘lmadi. Qayta urinib ko‘ring.',
        ),
        data: (list) {
          if (list.isEmpty) {
            return const _Message(text: 'Hozircha so‘z to‘plami yo‘q.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.xxl,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
            itemBuilder: (_, i) => _ThemeCard(group: list[i]),
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.group});

  final VocabGroup group;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _ThemeWordsScreen(group: group)),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.set.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.items.length} ta so‘z',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (group.set.cefrLevel.isNotEmpty) ...[
              // The level as a quiet chip, not a warning. It tells a learner
              // whether a theme is above them without making it look barred.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  group.set.cefrLevel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDeep,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _ThemeWordsScreen extends ConsumerWidget {
  const _ThemeWordsScreen({required this.group});

  final VocabGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(group.set.title),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        itemCount: group.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
        itemBuilder: (_, i) {
          final item = group.items[i];
          return Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.word,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Tap to hear it — the only sound in the app a learner asks
                    // for rather than has decided for them.
                    Material(
                      color: AppColors.vocabulary.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () =>
                            ref.read(pronouncerProvider).speak(item.word),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.vocabulary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.translationUz.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.translationUz,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.brandDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (item.example.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.example,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
      ),
    ),
  );
}
