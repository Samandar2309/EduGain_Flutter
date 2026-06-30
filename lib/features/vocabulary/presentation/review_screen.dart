import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// Spaced-repetition review of all due words (across sets). Flip each card,
/// self-grade, then results update each word's Leitner box on the server.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final due = ref.watch(reviewDueProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: due.when(
        loading: () => const AppLoader(),
        error: (_, _) => Center(child: Text(l.loadFailed)),
        data: (items) => items.isEmpty
            ? const _AllDone()
            : _ReviewSession(items: items),
      ),
    );
  }
}

class _AllDone extends StatelessWidget {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.brand,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              l.allReviewed,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l.noReviewWords,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.xxl),
            FilledButton(
              onPressed: () => context.go('/vocabulary'),
              child: Text(l.wordSets),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSession extends ConsumerStatefulWidget {
  const _ReviewSession({required this.items});
  final List<VocabItem> items;

  @override
  ConsumerState<_ReviewSession> createState() => _ReviewSessionState();
}

class _ReviewSessionState extends ConsumerState<_ReviewSession> {
  int _index = 0;
  bool _showBack = false;
  bool _submitting = false;
  final _results = <({String itemId, bool correct})>[];

  Future<void> _answer(bool correct) async {
    _results.add((itemId: widget.items[_index].id, correct: correct));
    if (_index + 1 >= widget.items.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _showBack = false;
    });
  }

  Future<void> _finish() async {
    final l = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final res = await ref
          .read(vocabularyRepositoryProvider)
          .submitReview(_results);
      // Refresh the due queue and the user's XP/streak shown on home.
      ref.invalidate(reviewDueProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(l.greatJob),
          content: Text(l.reviewResult(res.correct, res.reviewed)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.close),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / widget.items.length,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.outlineVariant,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Text(
                  '${_index + 1}/${widget.items.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _showBack
                      ? _CardFace(
                          key: const ValueKey('back'),
                          child: _Back(item: item),
                        )
                      : _CardFace(
                          key: const ValueKey('front'),
                          child: _Front(word: item.word),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            if (!_showBack)
              Text(
                l.tapToSeeMeaning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : () => _answer(false),
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(l.couldntRecall),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : () => _answer(true),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(l.recalled),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Center(child: child),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const IconChip(
          icon: Icons.style_rounded,
          color: AppColors.vocabulary,
          size: 44,
          iconSize: 22,
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          word,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.item});
  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.translationUz,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.brandDeep,
          ),
        ),
        if (item.definitionEn.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Text(item.definitionEn, textAlign: TextAlign.center),
        ],
        if (item.example.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              item.example,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
