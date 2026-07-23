import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../vocabulary/application/pronounce_service.dart';
import '../../vocabulary/application/vocab_sfx.dart';
import '../../vocabulary/domain/game.dart' show GameMode, GameResult, xpForRun;
import '../../vocabulary/presentation/widgets/game_widgets.dart';
import '../application/providers.dart';
import '../domain/grammar_game.dart';
import '../domain/models.dart';

/// Grammar practice — two Duolingo-style games in one adaptive session:
/// fill-the-blank (tap the right form) and sentence-builder (arrange the words).
/// Every answer shows the "why"; a missed item comes back later in the run.
class GrammarPracticeScreen extends ConsumerWidget {
  const GrammarPracticeScreen({required this.topic, super.key});

  final GrammarTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lesson = ref.watch(grammarGameProvider(topic.id));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: lesson.when(
          loading: () => const AppLoader(),
          error: (_, _) => Center(child: Text(l.loadFailed)),
          data: (data) {
            final playable = data.playable;
            if (playable.length < 2) return const _EmptyGrammar();
            return _GrammarGame(topicId: topic.id, exercises: playable);
          },
        ),
      ),
    );
  }
}

class _GrammarGame extends ConsumerStatefulWidget {
  const _GrammarGame({required this.topicId, required this.exercises});

  final String topicId;
  final List<GrammarGameExercise> exercises;

  @override
  ConsumerState<_GrammarGame> createState() => _GrammarGameState();
}

class _GrammarGameState extends ConsumerState<_GrammarGame> {
  final _rng = Random();
  late final List<GrammarGameExercise> _queue;
  late final int _totalUnique;
  int _remaining = 0;

  // current-question state
  int? _picked; // fill-blank option
  final _placed = <int>[]; // reorder: bank indices in tapped order
  late List<String> _bank; // reorder: scrambled words for the current item
  bool _checked = false;
  bool _wasCorrect = false;

  // scoring
  int _combo = 0;
  int _bestCombo = 0;
  final _firstAttempt = <String, bool>{};
  final _attempts = <String, int>{};
  bool _finished = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _queue = [...widget.exercises]..shuffle(_rng);
    _totalUnique = _queue.length;
    _remaining = _totalUnique;
    _prepare();
  }

  GrammarGameExercise get _ex => _queue.first;

  void _prepare() {
    _picked = null;
    _placed.clear();
    _checked = false;
    if (_ex.kind == GrammarKind.reorder) {
      _bank = [..._ex.correctWords];
      for (var i = 0; i < 6 && _listEq(_bank, _ex.correctWords); i++) {
        _bank.shuffle(_rng);
      }
    } else {
      _bank = const [];
    }
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── answering ──
  void _pickOption(int i) {
    if (_checked) return;
    setState(() => _picked = i);
    _grade(i == _ex.correctIndex);
  }

  void _checkReorder() {
    if (_checked || _placed.length != _ex.correctWords.length) return;
    final built = _placed.map((i) => _bank[i]).toList();
    _grade(_listEq(built, _ex.correctWords));
  }

  void _grade(bool correct) {
    HapticFeedback.lightImpact();
    final sfx = ref.read(vocabSfxProvider);
    final id = _ex.id;
    _attempts[id] = (_attempts[id] ?? 0) + 1;
    _firstAttempt.putIfAbsent(id, () => correct);
    setState(() {
      _checked = true;
      _wasCorrect = correct;
      if (correct) {
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _combo = 0;
      }
    });
    if (correct) {
      (_combo > 0 && _combo % 5 == 0) ? sfx.streak() : sfx.correct();
    } else {
      sfx.wrong();
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(pronouncerProvider).speak(_ex.spoken);
    });
  }

  void _next() {
    final ex = _queue.removeAt(0);
    // Adaptive requeue: a missed item comes back later — unless it's already
    // been attempted twice, then we move on so the session can't loop.
    if (!_wasCorrect && (_attempts[ex.id] ?? 0) < 2) {
      final insertAt = min(_queue.length, 2 + _rng.nextInt(2));
      _queue.insert(insertAt, ex);
    } else {
      _remaining--;
    }
    if (_queue.isEmpty || _remaining <= 0) {
      _finish();
      return;
    }
    setState(_prepare);
  }

  void _finish() {
    setState(() => _finished = true);
    _submit();
  }

  Future<void> _submit() async {
    if (_submitted || _firstAttempt.isEmpty) return;
    _submitted = true;
    final results = _firstAttempt.entries
        .map((e) => (exerciseId: e.key, correct: e.value))
        .toList();
    try {
      await ref.read(grammarRepositoryProvider).recordPractice(widget.topicId, results);
    } on Object {
      // results still show; progress just isn't saved
    }
  }

  void _again() {
    setState(() {
      _queue
        ..clear()
        ..addAll([...widget.exercises]..shuffle(_rng));
      _remaining = _totalUnique;
      _combo = 0;
      _bestCombo = 0;
      _firstAttempt.clear();
      _attempts.clear();
      _finished = false;
      _submitted = false;
      _prepare();
    });
  }

  GameResult get _result {
    final answered = _firstAttempt.length;
    final firstTryCorrect = _firstAttempt.values.where((v) => v).length;
    return GameResult(
      mode: GameMode.solo,
      total: answered,
      correct: firstTryCorrect,
      bestCombo: _bestCombo,
      xpEarned: xpForRun(correct: firstTryCorrect, bestCombo: _bestCombo),
      itemResults: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return GameResultsView(
        result: _result,
        onAgain: _again,
        onDone: () => context.pop(),
        bridgeNote: "Bu qoidani endi Speaking mashg'ulotida qo'llab ko'ring 🎯",
      );
    }
    final progress = _totalUnique == 0
        ? 0.0
        : (_totalUnique - _remaining) / _totalUnique;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.inkFaint),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation(AppColors.grammar),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              ComboBadge(combo: _combo),
            ],
          ),
        ),
        Expanded(
          child: _ex.kind == GrammarKind.fillBlank ? _fillBlank() : _reorder(),
        ),
        _bottomBar(),
      ],
    );
  }

  // ── fill-blank ──
  Widget _fillBlank() {
    final shown = _ex.prompt.replaceAll(RegExp(r'_{2,}'), '  ____  ');
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.md),
          const _Instruction("TO'G'RI SHAKLNI TANLANG"),
          const SizedBox(height: AppSpace.xl),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadow.card,
                ),
                child: Text(
                  shown,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, height: 1.4, fontWeight: FontWeight.w700,
                    color: AppColors.ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          ...List.generate(_ex.options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: OptionButton(
                label: _ex.options[i],
                state: _optState(i),
                onTap: _checked ? null : () => _pickOption(i),
              ),
            );
          }),
        ],
      ),
    );
  }

  OptionState _optState(int i) {
    if (!_checked) return OptionState.idle;
    if (i == _ex.correctIndex) return OptionState.correct;
    if (i == _picked) return OptionState.wrong;
    return OptionState.dimmed;
  }

  // ── reorder (sentence builder) ──
  Widget _reorder() {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.md),
          const _Instruction("GAPNI TUZING"),
          const SizedBox(height: AppSpace.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadow.soft,
            ),
            child: Text(
              _ex.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          // answer slots
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _checked
                      ? (_wasCorrect ? AppColors.success : AppColors.danger)
                      : AppColors.line,
                  width: 2,
                ),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var pos = 0; pos < _placed.length; pos++)
                  _Chip(
                    label: _bank[_placed[pos]],
                    tone: _checked
                        ? (_wasCorrect ? _ChipTone.correct : _ChipTone.wrong)
                        : _ChipTone.filled,
                    onTap: _checked ? null : () => setState(() => _placed.removeAt(pos)),
                  ),
              ],
            ),
          ),
          const Spacer(),
          if (_checked && !_wasCorrect)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Text(
                "To'g'ri javob: ${_ex.correctWords.join(' ')}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
          // word bank
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_bank.length, (i) {
              final used = _placed.contains(i);
              return _Chip(
                label: _bank[i],
                tone: used ? _ChipTone.ghost : _ChipTone.bank,
                onTap: (used || _checked) ? null : () => setState(() => _placed.add(i)),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── bottom bar: check button / feedback + "why" / continue ──
  Widget _bottomBar() {
    if (!_checked) {
      // reorder needs a Check button; fill-blank grades on tap.
      if (_ex.kind == GrammarKind.reorder) {
        final ready = _placed.length == _ex.correctWords.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.grammar,
                disabledBackgroundColor: AppColors.line,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: ready ? _checkReorder : null,
              child: const Text('Tekshirish', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        );
      }
      return const SizedBox(height: AppSpace.lg);
    }
    // feedback + explanation + continue
    final ok = _wasCorrect;
    final color = ok ? AppColors.success : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg, AppSpace.lg, AppSpace.lg,
        AppSpace.lg + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color, size: 22),
              const SizedBox(width: AppSpace.sm),
              Text(
                ok ? 'To‘g‘ri!' : 'Xato',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          if (_ex.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _ex.explanation,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5, height: 1.4),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: _next,
              child: const Text('Davom etish', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.inkFaint, fontSize: 12, fontWeight: FontWeight.w700,
      letterSpacing: 1.2),
  );
}

enum _ChipTone { bank, filled, ghost, correct, wrong }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone, required this.onTap});
  final String label;
  final _ChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      _ChipTone.bank => (AppColors.surface, AppColors.line, AppColors.ink),
      _ChipTone.filled => (
        AppColors.grammar.withValues(alpha: 0.12), AppColors.grammar, AppColors.grammar),
      _ChipTone.ghost => (AppColors.canvasAlt, AppColors.line, AppColors.canvasAlt),
      _ChipTone.correct => (
        AppColors.success.withValues(alpha: 0.14), AppColors.success, AppColors.brandDeep),
      _ChipTone.wrong => (
        AppColors.danger.withValues(alpha: 0.12), AppColors.danger, AppColors.danger),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tone == _ChipTone.ghost ? Colors.transparent : fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyGrammar extends StatelessWidget {
  const _EmptyGrammar();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvas,
    appBar: AppBar(backgroundColor: AppColors.canvas),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpace.xxl),
        child: Text(
          "Bu mavzuda mashq uchun yetarli topshiriq yo'q.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inkSoft),
        ),
      ),
    ),
  );
}
