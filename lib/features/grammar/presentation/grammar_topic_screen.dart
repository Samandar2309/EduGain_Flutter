import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// One grammar topic: the rule explained in a highlighted card, exercises as
/// clean cards that grade in place (green/red border + explanation), then a
/// score panel with a ring.
class GrammarTopicScreen extends ConsumerWidget {
  const GrammarTopicScreen({required this.topic, super.key});

  final GrammarTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(grammarTopicDetailProvider(topic.id));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(topic.title),
        backgroundColor: AppColors.canvas,
      ),
      body: detail.when(
        loading: () => const AppLoader(),
        error: (_, _) =>
            Center(child: Text(AppLocalizations.of(context).loadFailed)),
        data: (d) => _ExerciseForm(topicId: topic.id, detail: d),
      ),
    );
  }
}

class _ExerciseForm extends ConsumerStatefulWidget {
  const _ExerciseForm({required this.topicId, required this.detail});

  final String topicId;
  final GrammarTopicDetail detail;

  @override
  ConsumerState<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends ConsumerState<_ExerciseForm> {
  final _selected = <String, String>{}; // mcq answers
  final _controllers = <String, TextEditingController>{}; // text answers
  Map<String, ExerciseResult> _resultsById = {};
  bool _checked = false;
  bool _submitting = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    for (final ex in widget.detail.exercises) {
      if (!ex.isMcq) _controllers[ex.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _check() async {
    final answers = <({String exerciseId, Object answer})>[];
    for (final ex in widget.detail.exercises) {
      final raw = ex.isMcq ? _selected[ex.id] : _controllers[ex.id]?.text.trim();
      if (raw != null && raw.isNotEmpty) {
        answers.add((exerciseId: ex.id, answer: raw));
      }
    }
    if (answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).atLeastOneAnswer)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(grammarRepositoryProvider)
          .check(widget.topicId, answers);
      setState(() {
        _checked = true;
        _score = result.score;
        _resultsById = {for (final r in result.results) r.exerciseId: r};
      });
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exercises = widget.detail.exercises;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      children: [
        if (widget.detail.topic.explanationMd.isNotEmpty) ...[
          _RuleCard(text: widget.detail.topic.explanationMd),
          const SizedBox(height: AppSpace.lg),
        ],
        ...exercises.map(
          (ex) => _ExerciseCard(
            exercise: ex,
            selected: _selected[ex.id],
            controller: _controllers[ex.id],
            result: _resultsById[ex.id],
            locked: _checked,
            onSelect: (v) => setState(() => _selected[ex.id] = v),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (_checked)
          _ScorePanel(score: _score, total: exercises.length)
        else
          FilledButton(
            onPressed: _submitting ? null : _check,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(l.check),
          ),
      ],
    );
  }
}

/// The rule, framed as a highlighted "lesson note" with the module accent.
class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.grammar.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grammar.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconChip(
            icon: Icons.menu_book_rounded,
            color: AppColors.grammar,
            size: 38,
            iconSize: 19,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ratio = total == 0 ? 0.0 : score / total;
    final color = ratio >= 0.75
        ? AppColors.success
        : ratio >= 0.5
            ? AppColors.warning
            : AppColors.danger;
    return AppCard(
      child: Row(
        children: [
          ProgressRing(
            progress: ratio,
            size: 64,
            stroke: 8,
            color: color,
            trackColor: AppColors.canvasAlt,
            center: Icon(
              ratio >= 0.5 ? Icons.emoji_events_rounded : Icons.refresh_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              l.grammarScore(score, total),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.selected,
    required this.controller,
    required this.result,
    required this.locked,
    required this.onSelect,
  });

  final GrammarExercise exercise;
  final String? selected;
  final TextEditingController? controller;
  final ExerciseResult? result;
  final bool locked;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = result?.correct;
    final borderColor = correct == null
        ? AppColors.line
        : (correct ? AppColors.success : AppColors.danger);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        border: Border.all(color: borderColor, width: correct == null ? 1 : 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.prompt,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                ),
                if (correct != null)
                  Icon(
                    correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: correct ? AppColors.success : AppColors.danger,
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (exercise.isMcq)
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: exercise.options.map((opt) {
                  final isSelected = selected == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: locked ? null : (_) => onSelect(opt),
                    selectedColor: AppColors.grammar.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.grammar : AppColors.ink,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.grammar : AppColors.line,
                    ),
                  );
                }).toList(),
              )
            else
              TextField(
                controller: controller,
                enabled: !locked,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).yourAnswer,
                ),
              ),
            if (result != null && result!.explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  result!.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
