import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

class GrammarTopicScreen extends ConsumerWidget {
  const GrammarTopicScreen({required this.topic, super.key});

  final GrammarTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(grammarTopicDetailProvider(topic.id));
    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final exercises = widget.detail.exercises;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.detail.topic.explanationMd.isNotEmpty)
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.detail.topic.explanationMd),
            ),
          ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        if (_checked)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.grammarScore(_score, exercises.length),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          FilledButton(
            onPressed: _submitting ? null : _check,
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
        ? Colors.transparent
        : (correct ? Colors.green : theme.colorScheme.error);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.prompt,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (correct != null)
                  Icon(
                    correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: correct ? Colors.green : theme.colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (exercise.isMcq)
              Wrap(
                spacing: 8,
                children: exercise.options
                    .map(
                      (opt) => ChoiceChip(
                        label: Text(opt),
                        selected: selected == opt,
                        onSelected: locked ? null : (_) => onSelect(opt),
                      ),
                    )
                    .toList(),
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
              const SizedBox(height: 10),
              Text(
                result!.explanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
