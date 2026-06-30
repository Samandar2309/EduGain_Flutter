import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// Flashcard study for one vocabulary set: flip word ↔ meaning, self-grade,
/// then submit the per-word results (drives spaced repetition + XP).
class VocabStudyScreen extends ConsumerWidget {
  const VocabStudyScreen({required this.set, super.key});

  final VocabSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(vocabSetDetailProvider(set.id));
    return Scaffold(
      appBar: AppBar(title: Text(set.title)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l.loadFailed)),
        data: (d) => d.items.isEmpty
            ? Center(child: Text(l.noWords))
            : _Flashcards(setId: set.id, items: d.items),
      ),
    );
  }
}

class _Flashcards extends ConsumerStatefulWidget {
  const _Flashcards({required this.setId, required this.items});

  final String setId;
  final List<VocabItem> items;

  @override
  ConsumerState<_Flashcards> createState() => _FlashcardsState();
}

class _FlashcardsState extends ConsumerState<_Flashcards> {
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
      final learned = await ref
          .read(vocabularyRepositoryProvider)
          .submitProgress(widget.setId, _results);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.congrats),
          content: Text(l.vocabResult(learned, widget.items.length)),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LinearProgressIndicator(
            value: (_index + 1) / widget.items.length,
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _showBack
                        ? _CardBack(item: item)
                        : Text(
                            item.word,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!_showBack)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.tapCardToFlip,
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (_showBack)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : () => _answer(false),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l.dontKnow),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : () => _answer(true),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l.know),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.item});

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
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        if (item.definitionEn.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(item.definitionEn, textAlign: TextAlign.center),
        ],
        if (item.example.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            item.example,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
