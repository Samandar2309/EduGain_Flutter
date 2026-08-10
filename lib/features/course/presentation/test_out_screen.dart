import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'drills.dart';

/// Jumping ahead.
///
/// Nobody should be made to sit through material they already know. A learner
/// who is past the early units answers a sample of what those units teach, and
/// if they get most of it right, the units open.
///
/// Two rules, and both are said out loud on screen rather than discovered
/// afterwards:
///
/// * **it pays no XP.** The leaderboard is a record of work done, and a jump is
///   not work done. Anyone who wants the points can still go and do the
///   lessons — those pay normally;
/// * **there is no feedback until the end.** This is a check, not a lesson.
///   Showing the right answer after each question would turn the test into the
///   teaching it exists to let somebody skip.
class TestOutScreen extends ConsumerStatefulWidget {
  const TestOutScreen({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<TestOutScreen> createState() => _TestOutScreenState();
}

class _TestOutScreenState extends ConsumerState<TestOutScreen> {
  final _answers = <String, dynamic>{};
  int _index = 0;
  Object? _pending;
  bool _submitting = false;
  TestOutResult? _result;

  Future<void> _next(List<Drill> drills) async {
    if (_pending != null) _answers[drills[_index].itemId] = _pending;
    if (_index + 1 < drills.length) {
      setState(() {
        _index++;
        _pending = null;
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(courseRepositoryProvider)
          .submitTestOut(widget.unitId, _answers);
      ref.invalidate(coursePathProvider);
      ref.invalidate(unitDetailProvider);
      if (!mounted) return;
      setState(() {
        _result = result;
        _submitting = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _submitting = false);
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.questionsError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final drills = ref.watch(testOutDrillsProvider(widget.unitId));

    return Scaffold(
      backgroundColor: LessonPalette.canvas,
      body: SafeArea(
        child: drills.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Failed(l: l),
          data: (items) {
            if (items.isEmpty) return _Failed(l: l);
            final result = _result;
            if (result != null) return _Outcome(result: result, l: l);
            return _body(l, items);
          },
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l, List<Drill> drills) {
    final drill = drills[_index];
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.lg, 0),
          child: Row(children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close_rounded, color: LessonPalette.faint),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: (_index + 1) / drills.length,
                  minHeight: 10,
                  backgroundColor: LessonPalette.surface,
                  valueColor:
                      const AlwaysStoppedAnimation(LessonPalette.gold),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text('${_index + 1}/${drills.length}',
                style: const TextStyle(
                    color: LessonPalette.faint, fontSize: 12.5)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  instructionFor(drill.type, l),
                  style: const TextStyle(
                      color: LessonPalette.soft,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.lg),
                DrillView(
                  key: ValueKey('${drill.itemId}-$_index'),
                  drill: drill,
                  locked: false,
                  onChanged: (v) => setState(() => _pending = v),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
          child: SafeArea(
            top: false,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LessonPalette.gold,
                disabledBackgroundColor: LessonPalette.line,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              // Skippable on purpose: a test you cannot leave a question blank
              // in is a test you abandon rather than fail.
              onPressed: _submitting ? null : () => _next(drills),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _index + 1 == drills.length
                          ? l.courseTestFinish
                          : l.courseContinue,
                      style: const TextStyle(
                          color: Color(0xFF2A1B00),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.result, required this.l});

  final TestOutResult result;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpace.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          result.passed ? Icons.lock_open_rounded : Icons.school_rounded,
          size: 64,
          color: result.passed ? LessonPalette.gold : LessonPalette.soft,
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          result.passed
              ? l.courseTestPassed(result.unlocked)
              : l.courseTestFailed,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: LessonPalette.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          '${result.correct} / ${result.total}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: LessonPalette.soft, fontSize: 15),
        ),
        if (result.passed) ...[
          const SizedBox(height: AppSpace.md),
          // Said here rather than left to be discovered. A learner who finds
          // out later that a jump earned nothing feels caught out by a rule
          // nobody told them.
          Text(
            l.courseTestNoXp,
            textAlign: TextAlign.center,
            style: const TextStyle(color: LessonPalette.faint, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: AppSpace.xxl),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LessonPalette.right,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
          ),
          onPressed: () => context.pop(),
          child: Text(
            l.courseBackToPath,
            style: const TextStyle(
                color: Color(0xFF06281C),
                fontSize: 15.5,
                fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded,
            color: LessonPalette.faint, size: 40),
        const SizedBox(height: AppSpace.md),
        Text(l.questionsError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: LessonPalette.soft)),
        const SizedBox(height: AppSpace.lg),
        FilledButton(
            onPressed: () => context.pop(), child: Text(l.courseBackToPath)),
      ]),
    ),
  );
}
