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

/// CEFR placement test — a short wizard that sets the learner's level so the
/// whole app (AI prompts, content) adapts. One question per screen, options as
/// tappable cards, and a celebratory level reveal at the end.
class PlacementScreen extends ConsumerWidget {
  const PlacementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final test = ref.watch(placementTestProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l.placementTestTitle),
        backgroundColor: AppColors.canvas,
      ),
      body: test.when(
        loading: () => const AppLoader(),
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.resultReady,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                  boxShadow: AppShadow.glow(AppColors.brand),
                ),
                child: Center(
                  child: Text(
                    result.resultCefr ?? '—',
                    style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                l.yourEnglishLevel,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l.startAction),
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
    final q = widget.questions[_index];
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      children: [
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
                    value: (_index + 1) / widget.questions.length,
                    minHeight: 8,
                    backgroundColor: AppColors.canvasAlt,
                    color: AppColors.placement,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                '${_index + 1} / ${widget.questions.length}',
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
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              Text(
                q.prompt,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpace.xxl),
              if (q.isMcq)
                ...q.options.map(
                  (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _OptionCard(
                      text: opt,
                      selected: _mcq[q.id] == opt,
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
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isAnswered && !_submitting) ? _next : null,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(_isLast ? l.finishAction : l.nextAction),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One answer option: a card that visibly commits to the choice — accent
/// border + radio dot, with an eased transition instead of a hard swap.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.placement;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? accent : AppColors.line,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected ? AppShadow.soft : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.lg,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: Border.all(
                      color: selected ? accent : AppColors.inkFaint,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
