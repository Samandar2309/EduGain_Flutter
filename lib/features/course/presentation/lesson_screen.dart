import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/providers.dart';
import '../domain/models.dart';
import 'drills.dart';

/// One lesson, one question at a time.
///
/// Learners told us they could not work out what to do. Everything on this
/// screen answers that, and only that:
///
/// * one exercise fills the screen — nothing else is competing for the tap;
/// * a plain instruction sits above it, in their language, saying what is being
///   asked. "Choose the meaning" is not obvious from four words in a box;
/// * the answer is checked the moment they commit, not at the end. Being told
///   at the end that item three was wrong teaches nothing — the moment to learn
///   why is while they are still thinking about it;
/// * a bar at the top says how much is left, so the lesson has a visible end;
/// * anything missed comes back before the lesson finishes.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _Phase { answering, right, wrong, finished }

class _LessonScreenState extends ConsumerState<LessonScreen> {
  /// The queue actually being worked through. Starts as the lesson and grows
  /// when something is missed — a mistake you never see again is a mistake you
  /// keep.
  final _queue = <Drill>[];
  final _answers = <String, dynamic>{};
  final _seen = <String>{};

  /// Every answer given, repeats included.
  ///
  /// The progress bar counts these rather than distinct items: a requeued
  /// question is still work, and a bar that freezes at 80% for the last two
  /// questions reads as the lesson being stuck.
  int _answered = 0;

  int _index = 0;
  _Phase _phase = _Phase.answering;
  Object? _pending;
  Object? _correctAnswer;
  bool _checking = false;
  /// Whether the question just missed is coming back later in this lesson.
  /// Said out loud, because a question reappearing unannounced reads as the
  /// app having lost its place.
  bool _willReturn = false;
  LessonResult? _result;
  bool _submitting = false;

  Drill? get _drill => _index < _queue.length ? _queue[_index] : null;

  Future<void> _check() async {
    final drill = _drill;
    if (drill == null || _pending == null || _checking) return;
    setState(() => _checking = true);

    bool correct;
    Object? answer;
    try {
      final data = await ref
          .read(apiClientProvider)
          .post('/learn/item/${drill.itemId}/check', body: {'answer': _pending});
      correct = data['correct'] as bool? ?? false;
      answer = data['answer'];
    } on Object {
      // The network went away mid-lesson. Accepting the answer and moving on
      // is the kindest failure: the final submit is what counts, and stopping
      // somebody halfway through a lesson they were doing well at is worse
      // than telling them "right" once when they were not.
      correct = true;
      answer = null;
    }

    // The first answer is the one that counts. Re-answering a requeued item
    // must not overwrite a miss with a pass — the mistake happened.
    _answers.putIfAbsent(drill.itemId, () => _pending);
    // Requeued once and only once. A learner who misses the same question
    // twice is stuck, and putting it back a third time turns a lesson into a
    // loop they cannot leave.
    final returning = !correct && !_seen.contains(drill.itemId);
    if (returning) _queue.add(drill);
    _seen.add(drill.itemId);
    _answered++;

    if (!mounted) return;
    setState(() {
      _checking = false;
      _correctAnswer = answer;
      _willReturn = returning;
      _phase = correct ? _Phase.right : _Phase.wrong;
    });
    // A short buzz on a wrong answer only. Buzzing on every answer makes the
    // buzz meaningless, and a phone that vibrates constantly gets silenced.
    if (!correct) HapticFeedback.mediumImpact();
  }

  Future<void> _next() async {
    if (_index + 1 < _queue.length) {
      setState(() {
        _index++;
        _phase = _Phase.answering;
        _pending = null;
        _correctAnswer = null;
        _willReturn = false;
      });
      return;
    }
    await _finish();
  }

  /// Leave, keeping whatever was answered.
  ///
  /// The answers already given are real work and the best signal there is
  /// about what this learner finds hard. Throwing them away because somebody's
  /// bus arrived is wasteful; counting them as a finished lesson would be a
  /// lie. Sent as partial, they are recorded and the lesson stays unfinished.
  Future<void> _leave() async {
    final router = GoRouter.of(context);
    if (_answers.isNotEmpty) {
      try {
        await ref
            .read(courseRepositoryProvider)
            .submitLesson(widget.lessonId, _answers, partial: true);
        ref.invalidate(unitDetailProvider);
      } on Object {
        // Leaving must never be the thing that fails. The answers are worth
        // saving; they are not worth trapping somebody in a screen for.
      }
    }
    if (router.canPop()) router.pop();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(courseRepositoryProvider)
          .submitLesson(widget.lessonId, _answers);
      // Everything that shows progress has to be refetched, not just the path.
      //
      // Invalidating only the path was a real bug: a learner finished a lesson,
      // went back to the unit, and the next lesson was still locked — because
      // the unit screen was serving the answer it had cached before the work
      // was done. The family is invalidated whole rather than by id: the id is
      // not worth threading through three layers to save one refetch of a
      // screen that is about to be looked at anyway.
      ref.invalidate(coursePathProvider);
      ref.invalidate(unitDetailProvider);
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.finished;
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
    final drills = ref.watch(lessonDrillsProvider(widget.lessonId));

    return Scaffold(
      backgroundColor: LessonPalette.canvas,
      body: SafeArea(
        child: drills.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Retry(
            l: l,
            onRetry: () =>
                ref.invalidate(lessonDrillsProvider(widget.lessonId)),
          ),
          data: (items) {
            if (_queue.isEmpty && items.isNotEmpty) _queue.addAll(items);
            if (_queue.isEmpty) {
              return _Retry(
                l: l,
                onRetry: () =>
                    ref.invalidate(lessonDrillsProvider(widget.lessonId)),
              );
            }
            if (_phase == _Phase.finished && _result != null) {
              return _Done(result: _result!, l: l);
            }
            return _body(l);
          },
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l) {
    final drill = _drill!;
    final answered = _phase == _Phase.right || _phase == _Phase.wrong;

    return Column(
      children: [
        _TopBar(
          progress: _answered / _queue.length,
          onQuit: () => _confirmQuit(l),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  // The line that fixes "I don't know what to do".
                  Expanded(
                    child: Text(
                      instructionFor(drill.type, l),
                      style: const TextStyle(
                        color: LessonPalette.soft,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Named, so a question from three units ago reads as
                  // revision rather than as the app losing its place.
                  if (drill.isReview)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: LessonPalette.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        l.courseReview,
                        style: const TextStyle(
                            color: LessonPalette.gold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                ]),
                const SizedBox(height: AppSpace.lg),
                DrillView(
                  key: ValueKey('${drill.itemId}-$_index'),
                  drill: drill,
                  locked: answered,
                  onChanged: (value) => setState(() => _pending = value),
                ),
              ],
            ),
          ),
        ),
        _Foot(
          phase: _phase,
          checking: _checking,
          submitting: _submitting,
          canCheck: _pending != null,
          correctAnswer: _correctAnswer,
          willReturn: _willReturn,
          explanation: drill.example,
          l: l,
          onCheck: _check,
          onNext: _next,
        ),
      ],
    );
  }

  void _confirmQuit(AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LessonPalette.surface,
        title: Text(l.courseQuitTitle,
            style: const TextStyle(color: LessonPalette.ink, fontSize: 17)),
        content: Text(l.courseQuitBodyKept,
            style: const TextStyle(color: LessonPalette.soft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.courseQuitStay),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _leave();
            },
            child: Text(l.courseQuitLeave,
                style: const TextStyle(color: LessonPalette.wrong)),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.progress, required this.onQuit});

  final double progress;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.lg, 0),
    child: Row(children: [
      IconButton(
        onPressed: onQuit,
        icon: const Icon(Icons.close_rounded, color: LessonPalette.faint),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: LessonPalette.surface,
              valueColor:
                  const AlwaysStoppedAnimation(LessonPalette.right),
            ),
          ),
        ),
      ),
    ]),
  );
}

/// The bar across the bottom: check, then the verdict, then continue.
class _Foot extends StatelessWidget {
  const _Foot({
    required this.phase,
    required this.checking,
    required this.submitting,
    required this.canCheck,
    required this.correctAnswer,
    required this.willReturn,
    required this.explanation,
    required this.l,
    required this.onCheck,
    required this.onNext,
  });

  final _Phase phase;
  final bool checking;
  final bool submitting;
  final bool canCheck;
  final Object? correctAnswer;
  final bool willReturn;
  final String explanation;
  final AppLocalizations l;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final right = phase == _Phase.right;
    final wrong = phase == _Phase.wrong;
    final verdict = right || wrong;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
      decoration: BoxDecoration(
        color: right
            ? LessonPalette.right.withValues(alpha: 0.12)
            : wrong
                ? LessonPalette.wrong.withValues(alpha: 0.12)
                : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: right
                ? LessonPalette.right
                : wrong
                    ? LessonPalette.wrong
                    : LessonPalette.line,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (verdict) ...[
              Row(children: [
                Icon(
                  right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: right ? LessonPalette.right : LessonPalette.wrong,
                  size: 22,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    right ? l.courseCorrect : l.courseNotQuite,
                    style: TextStyle(
                      color: right ? LessonPalette.right : LessonPalette.wrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ]),
              // The right answer, and why — the part that turns a mistake into
              // something learned rather than something to feel bad about.
              if (wrong && correctAnswer != null) ...[
                const SizedBox(height: 4),
                Text(
                  l.courseTheAnswerWas(_asText(correctAnswer!)),
                  style: const TextStyle(
                      color: LessonPalette.ink, fontSize: 13.5),
                ),
              ],
              if (wrong && willReturn) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.replay_rounded,
                      size: 14, color: LessonPalette.soft),
                  const SizedBox(width: 5),
                  Text(l.courseWillReturn,
                      style: const TextStyle(
                          color: LessonPalette.soft, fontSize: 12)),
                ]),
              ],
              if (explanation.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  explanation,
                  style: const TextStyle(
                      color: LessonPalette.soft,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: AppSpace.md),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: verdict
                    ? (right ? LessonPalette.right : LessonPalette.wrong)
                    : LessonPalette.right,
                disabledBackgroundColor: LessonPalette.line,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: checking || submitting
                  ? null
                  : verdict
                      ? onNext
                      : (canCheck ? onCheck : null),
              child: checking || submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      verdict ? l.courseContinue : l.courseCheck,
                      style: TextStyle(
                        color: verdict && wrong
                            ? Colors.white
                            : const Color(0xFF06281C),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _asText(Object value) =>
      value is List ? value.join(' ') : '$value';
}

/// The end of the lesson.
class _Done extends StatelessWidget {
  const _Done({required this.result, required this.l});

  final LessonResult result;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpace.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          result.unitCompleted
              ? Icons.workspace_premium_rounded
              : Icons.celebration_rounded,
          size: 64,
          color: result.unitCompleted
              ? LessonPalette.gold
              : LessonPalette.right,
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          result.unitCompleted ? l.courseUnitDone : l.courseLessonDone,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LessonPalette.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Row(children: [
          Expanded(
            child: _Stat(
              value: '${result.correct}/${result.total}',
              label: l.courseCorrectCount,
              colour: LessonPalette.right,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _Stat(
              value: '+${result.xp}',
              label: 'XP',
              colour: LessonPalette.gold,
            ),
          ),
        ]),
        const SizedBox(height: AppSpace.xxl),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LessonPalette.right,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          onPressed: () => context.pop(),
          child: Text(
            l.courseBackToPath,
            style: const TextStyle(
              color: Color(0xFF06281C),
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.colour});

  final String value;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
    decoration: BoxDecoration(
      color: LessonPalette.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: colour.withValues(alpha: 0.4)),
    ),
    child: Column(children: [
      Text(value,
          style: TextStyle(
              color: colour, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: LessonPalette.soft, fontSize: 11.5)),
    ]),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.l, required this.onRetry});

  final AppLocalizations l;
  final VoidCallback onRetry;

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
        FilledButton(onPressed: onRetry, child: Text(l.retry)),
      ]),
    ),
  );
}
