import 'dart:async';

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
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  /// Set once the learner has chosen to sit the test again, so the gate does
  /// not reappear behind them mid-wizard.
  bool _retaking = false;

  /// The finished result, held here rather than inside the wizard.
  ///
  /// It used to be a dialog opened by the wizard, and it vanished the instant
  /// it appeared. Submitting refreshes the level, which rebuilds this screen,
  /// which swaps the wizard out for the "you already have a level" view — and
  /// the dialog went with the widget that opened it. The learner sat the test
  /// and was thrown back to the home screen having never seen the answer.
  ///
  /// Held one level up, the result outlives every rebuild underneath it: once
  /// there is a result, that is the whole screen until the learner leaves.
  PlacementResult? _finished;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = ref.watch(placementResultProvider);
    final finished = _finished;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l.placementTestTitle),
        backgroundColor: AppColors.canvas,
        // Nothing to go back to once the test is graded, and a stray back tap
        // here is the same lost result all over again.
        automaticallyImplyLeading: finished == null,
      ),
      body: finished != null
          ? _ResultView(result: finished)
          : _retaking
          ? _Test(onFinished: _onFinished)
          : result.when(
              loading: () => const AppLoader(),
              // A lookup that fails must not become a locked door. Not knowing
              // the old level is a reason to offer the test, not to withhold
              // it — the learner came here to be measured either way.
              error: (_, _) => _Test(onFinished: _onFinished),
              data: (r) => r.hasLevel
                  ? _LastResult(
                      result: r,
                      onRetake: () => setState(() => _retaking = true),
                    )
                  : _Test(onFinished: _onFinished),
            ),
    );
  }

  void _onFinished(PlacementResult result) =>
      setState(() => _finished = result);
}

class _Test extends ConsumerWidget {
  const _Test({required this.onFinished});

  final ValueChanged<PlacementResult> onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final test = ref.watch(placementTestProvider);
    return test.when(
      loading: () => const AppLoader(),
      error: (_, _) => Center(child: Text(l.loadFailed)),
      data: (questions) => questions.isEmpty
          ? Center(child: Text(l.noQuestions))
          : _Wizard(questions: questions, onFinished: onFinished),
    );
  }
}

/// The level, once it has been measured — a screen, not a dialog, and it stays
/// until the learner dismisses it themselves.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final PlacementResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const Spacer(),
            Text(
              l.resultReady,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpace.xxl),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadow.glow(AppColors.brand),
              ),
              child: Center(
                child: Text(
                  result.resultCefr ?? '—',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              l.yourEnglishLevel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            // What the number actually buys them. A level with no consequence
            // attached is a score; this is the reason they were asked.
            Text(
              l.placementResultBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
                child: Text(l.continueAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the learner sees when they already have a level: the answer they came
/// for, and only then the offer to measure again.
///
/// Sitting the test is not the cheap option it looks like — the new result
/// overwrites the level every lesson afterwards is pitched at, and a rushed
/// retake can lower a level the learner actually earned. So the consequence is
/// stated on the button's own screen rather than discovered afterwards.
class _LastResult extends StatelessWidget {
  const _LastResult({required this.result, required this.onRetake});

  final PlacementResult result;
  final VoidCallback onRetake;

  String _taken(AppLocalizations l) {
    final at = result.completedAt;
    if (at == null) return '';
    final now = DateTime.now();
    final then = at.toLocal();
    // Whole calendar days, not elapsed hours: "yesterday" should mean the day
    // before, however late at night the test was taken.
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(then.year, then.month, then.day))
        .inDays;
    if (days <= 0) return l.placementTakenToday;
    if (days == 1) return l.placementTakenYesterday;
    return l.placementTakenDaysAgo(days);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final taken = _taken(l);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const Spacer(),
            Text(
              l.placementLastResultTitle,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // The same badge they were shown when they finished. Coming back to
            // a different-looking result would read as a different result.
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadow.glow(AppColors.brand),
              ),
              child: Center(
                child: Text(
                  result.resultCefr ?? '—',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              l.yourEnglishLevel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (taken.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                taken,
                style: const TextStyle(
                  color: AppColors.inkFaint,
                  fontSize: 13,
                ),
              ),
            ],
            const Spacer(),
            Text(
              l.placementRetakeQuestion,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l.placementRetakeReplaces,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetake,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
                child: Text(l.placementRetakeAction),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                ),
                child: Text(l.placementKeepAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wizard extends ConsumerStatefulWidget {
  const _Wizard({required this.questions, required this.onFinished});

  final List<PlacementQuestion> questions;

  /// Handed upwards rather than shown here: this widget is disposed the moment
  /// the level lands, so anything it puts on screen goes with it.
  final ValueChanged<PlacementResult> onFinished;

  @override
  ConsumerState<_Wizard> createState() => _WizardState();
}

class _WizardState extends ConsumerState<_Wizard> {
  int _index = 0;
  bool _submitting = false;
  final _mcq = <String, String>{};
  final _controllers = <String, TextEditingController>{};

  /// Pending auto-advance. Held so a manual tap can cancel it — otherwise
  /// tapping an option and then Next inside the pause skips a question.
  Timer? _advance;

  /// Long enough to see which option took the tick, short enough that the test
  /// still feels like it is moving. Advancing instantly reads as a glitch: the
  /// answer vanishes before the eye confirms it landed on the right one.
  static const _advanceDelay = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    for (final q in widget.questions) {
      if (!q.isMcq) _controllers[q.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _advance?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _choose(PlacementQuestion q, String option) {
    _advance?.cancel();
    setState(() => _mcq[q.id] = option);
    // Not on the last question. Advancing is recoverable — Back is right
    // there — but submitting sets the level that every lesson afterwards
    // trusts, and nothing irreversible should happen on a tap the learner
    // has not confirmed.
    if (_isLast) return;
    final at = _index;
    _advance = Timer(_advanceDelay, () {
      if (mounted && _index == at && !_submitting) _next();
    });
  }

  void _back() {
    _advance?.cancel();
    if (_index > 0) setState(() => _index--);
  }

  bool get _isAnswered {
    final q = widget.questions[_index];
    return q.isMcq
        ? _mcq.containsKey(q.id)
        : (_controllers[q.id]?.text.trim().isNotEmpty ?? false);
  }

  bool get _isLast => _index + 1 >= widget.questions.length;

  void _next() {
    _advance?.cancel();
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
      // The gate reads this; leaving it cached would show the old level back
      // to someone who just changed it.
      ref.invalidate(placementResultProvider);
      // Deliberately not guarded by `mounted`: this rebuilds the parent, and
      // the parent is what disposes this widget. Waiting to be alive first is
      // how the result got lost in the first place.
      widget.onFinished(result);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                      onTap: () => _choose(q, opt),
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
            child: Row(
              children: [
                // Back earns its place only now that a tap advances on its
                // own: without it a mis-tap would be unrecoverable, and one
                // stray tap deciding a band is exactly what the bank is
                // shaped to prevent.
                if (_index > 0) ...[
                  OutlinedButton(
                    onPressed: _submitting ? null : _back,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xl,
                      ),
                    ),
                    child: Text(l.backAction),
                  ),
                  const SizedBox(width: AppSpace.md),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: (_isAnswered && !_submitting) ? _next : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                    ),
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
