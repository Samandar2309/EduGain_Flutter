import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/ui/error_handling.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';

/// CEFR placement test — a short wizard that sets the learner's level so the
/// whole app (AI prompts, content) adapts.
class PlacementScreen extends ConsumerWidget {
  const PlacementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final test = ref.watch(placementTestProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.placementTestTitle)),
      body: test.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l.loadFailed)),
        data: (questions) => questions.isEmpty
            ? Center(child: Text(l.noQuestions))
            : _Wizard(questions: questions),
      ),
    );
  }
}

class _Wizard extends ConsumerStatefulWidget {
  const _Wizard({required this.questions});

  final List<PlacementQuestion> questions;

  @override
  ConsumerState<_Wizard> createState() => _WizardState();
}

class _WizardState extends ConsumerState<_Wizard> {
  int _index = 0;
  bool _submitting = false;
  final _mcq = <String, String>{};
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final q in widget.questions) {
      if (!q.isMcq) _controllers[q.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isAnswered {
    final q = widget.questions[_index];
    return q.isMcq
        ? _mcq.containsKey(q.id)
        : (_controllers[q.id]?.text.trim().isNotEmpty ?? false);
  }

  bool get _isLast => _index + 1 >= widget.questions.length;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _finish() async {
    final answers = <({String questionId, Object answer})>[];
    for (final q in widget.questions) {
      final raw = q.isMcq ? _mcq[q.id] : _controllers[q.id]?.text.trim();
      if (raw != null && raw.isNotEmpty) {
        answers.add((questionId: q.id, answer: raw));
      }
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(placementRepositoryProvider)
          .submit(answers);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      await _showResult(result);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showResult(PlacementResult result) {
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.resultReady),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.resultCefr ?? '—',
              style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(l.yourEnglishLevel),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.startAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_index];
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_index + 1) / widget.questions.length,
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${_index + 1} / ${widget.questions.length}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Text(
                q.prompt,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              if (q.isMcq)
                ...q.options.map(
                  (opt) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: _mcq[q.id] == opt
                        ? theme.colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      title: Text(opt),
                      onTap: () => setState(() => _mcq[q.id] = opt),
                    ),
                  ),
                )
              else
                TextField(
                  controller: _controllers[q.id],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: l.yourAnswer),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: (_isAnswered && !_submitting) ? _next : null,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(_isLast ? l.finishAction : l.nextAction),
          ),
        ),
      ],
    );
  }
}
