import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// Flashcard study for one vocabulary set: a real 3D card flip (word ↔
/// meaning), self-grade, then submit the per-word results (drives spaced
/// repetition + XP). The card is the hero; everything else stays quiet.
class VocabStudyScreen extends ConsumerWidget {
  const VocabStudyScreen({required this.set, super.key});

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
    setState(() => _submitting = true);
    try {
      final learned = await ref
          .read(vocabularyRepositoryProvider)
          .submitProgress(widget.setId, _results);
      if (!mounted) return;
      await _showResult(learned);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showResult(int learned) {
    final l = AppLocalizations.of(context);
    final total = widget.items.length;
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressRing(
                progress: total == 0 ? 0 : learned / total,
                size: 96,
                stroke: 10,
                color: AppColors.brand,
                trackColor: AppColors.canvasAlt,
                center: Text(
                  '$learned/$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                l.congrats,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                l.vocabResult(learned, total),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        // Progress: bar + counter pill.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / widget.items.length,
                    minHeight: 8,
                    backgroundColor: AppColors.canvasAlt,
                    color: AppColors.vocabulary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                '${_index + 1} / ${widget.items.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            // Keyed by index: advancing to the next word swaps the card fresh
            // (face-down) instead of animating a reverse flip that would flash
            // the new word's answer.
            child: _FlipCard(
              key: ValueKey(_index),
              showBack: _showBack,
              onTap: () => setState(() => _showBack = !_showBack),
              front: _CardFront(word: item.word),
              back: _CardBack(item: item),
            ),
          ),
        ),
        // Hint or grading actions.
        SizedBox(
          height: 96,
          child: _showBack
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    0,
                    AppSpace.lg,
                    AppSpace.xl,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : () => _answer(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            minimumSize: const Size(0, 54),
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(l.dontKnow),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : () => _answer(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 54),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l.know),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: AppColors.inkFaint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.tapCardToFlip,
                        style: const TextStyle(
                          color: AppColors.inkFaint,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// A real 3D flip: the card rotates around Y with perspective; the face swaps
/// at 90° so each side is only ever seen the right way round.
class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.showBack,
    required this.onTap,
    required this.front,
    required this.back,
    super.key,
  });

  final bool showBack;
  final VoidCallback onTap;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showBack ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) {
          final angle = t * math.pi;
          final isBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective
              ..rotateY(angle),
            child: isBack
                // Un-mirror the back face so its text reads normally.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: back,
                  )
                : front,
          );
        },
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.accent(AppColors.vocabulary),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.glow(AppColors.vocabulary),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Text(
            word,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.item});

  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadow.card,
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.translationUz,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDark,
                ),
              ),
              if (item.definitionEn.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                Text(
                  item.definitionEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.4),
                ),
              ],
              if (item.example.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    item.example,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
