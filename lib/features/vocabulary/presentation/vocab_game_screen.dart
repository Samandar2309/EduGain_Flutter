import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../application/providers.dart';
import '../application/pronounce_service.dart';
import '../application/vocab_sfx.dart';
import '../domain/game.dart';
import 'widgets/game_widgets.dart';

/// The vocabulary game — one tap-only deck, played solo or as a live race
/// against a calibrated bot ("Gainsy"). Self-contained: it owns the deck, the
/// score/combo, the (optional) bot ticker, and the results, then submits the
/// per-word outcome to the SRS/XP backend on finish. (Human-vs-human duels live
/// in `vocab_duel_screen.dart`, which reuses the same widgets.)
class VocabGameScreen extends ConsumerStatefulWidget {
  const VocabGameScreen({required this.launch, super.key});

  final VocabGameLaunch launch;

  @override
  ConsumerState<VocabGameScreen> createState() => _VocabGameScreenState();
}

class _VocabGameScreenState extends ConsumerState<VocabGameScreen> {
  static const _accent = AppColors.vocabulary; // amber
  static const _botAccuracy = 0.72; // beatable, but a real opponent
  final _rng = Random();

  late final List<GameQuestion> _deck;
  int _index = 0;
  int? _picked; // selected option index for the current question
  int _correct = 0;
  int _combo = 0;
  int _bestCombo = 0;
  final _results = <({String itemId, bool correct})>[];
  bool _finished = false;
  bool _submitted = false;

  // ── bot duel ──
  Timer? _botTimer;
  final _botTimes = <double>[]; // cumulative seconds at which the bot answers Q i
  int _botIndex = 0;
  int _botCorrect = 0;
  Stopwatch? _clock;

  bool get _duel => widget.launch.mode == GameMode.duel;

  @override
  void initState() {
    super.initState();
    _deck = buildDeck(widget.launch.items, random: _rng);
    if (_duel && _deck.isNotEmpty) _startBot();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  void _startBot() {
    var t = 0.0;
    for (var i = 0; i < _deck.length; i++) {
      t += 1.4 + _rng.nextDouble() * 2.2; // 1.4–3.6s per answer
      _botTimes.add(t);
    }
    _clock = Stopwatch()..start();
    _botTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final elapsed = _clock!.elapsed.inMilliseconds / 1000.0;
      var advanced = false;
      while (_botIndex < _deck.length && elapsed >= _botTimes[_botIndex]) {
        if (_rng.nextDouble() < _botAccuracy) _botCorrect++;
        _botIndex++;
        advanced = true;
      }
      if (advanced && mounted) setState(() {});
      if (_botIndex >= _deck.length) {
        _botTimer?.cancel();
        if (_index >= _deck.length && !_finished) _finish();
      }
    });
  }

  void _pick(int option) {
    if (_picked != null || _finished) return;
    final q = _deck[_index];
    final correct = option == q.correctIndex;
    HapticFeedback.lightImpact();
    final sfx = ref.read(vocabSfxProvider);
    setState(() {
      _picked = option;
      _results.add((itemId: q.itemId, correct: correct));
      if (correct) {
        _correct++;
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
    // Reinforce the correct pronunciation once the chime has landed.
    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted) ref.read(pronouncerProvider).speak(q.englishWord);
    });
    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      if (_index + 1 >= _deck.length) {
        if (!_duel || _botIndex >= _deck.length) {
          _finish();
        } else {
          setState(() => _index++); // parks on the "waiting for Gainsy" state
        }
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  void _finish() {
    _botTimer?.cancel();
    setState(() => _finished = true);
    _submit();
  }

  Future<void> _submit() async {
    if (_submitted || _results.isEmpty) return;
    _submitted = true;
    final repo = ref.read(vocabularyRepositoryProvider);
    try {
      final setId = widget.launch.setId;
      if (setId != null) {
        await repo.submitProgress(setId, _results);
      } else {
        await repo.submitReview(_results);
      }
    } on Object {
      // A failed submit shouldn't hide the results; progress just isn't saved.
    }
  }

  GameResult get _result => GameResult(
    mode: widget.launch.mode,
    total: _deck.length,
    correct: _correct,
    bestCombo: _bestCombo,
    xpEarned: xpForRun(correct: _correct, bestCombo: _bestCombo),
    itemResults: _results,
    youWon: _duel ? _correct >= _botCorrect : null,
    opponentCorrect: _duel ? _botCorrect : null,
  );

  void _again() {
    setState(() {
      _index = 0;
      _picked = null;
      _correct = 0;
      _combo = 0;
      _bestCombo = 0;
      _results.clear();
      _finished = false;
      _submitted = false;
      _botIndex = 0;
      _botCorrect = 0;
      _botTimes.clear();
    });
    if (_duel) _startBot();
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) return const _EmptyDeck();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: _finished
            ? GameResultsView(result: _result, onAgain: _again, onDone: () => context.pop())
            : _playView(),
      ),
    );
  }

  Widget _playView() {
    final waitingForBot = _index >= _deck.length;
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
                    value: _deck.isEmpty ? 0 : _index / _deck.length,
                    minHeight: 10,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation(_accent),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              ComboBadge(combo: _combo),
            ],
          ),
        ),
        if (_duel)
          RaceBar(
            youProgress: _index / _deck.length,
            opponentProgress: _botIndex / _deck.length,
            opponentName: 'Gainsy',
          ),
        Expanded(
          child: waitingForBot
              ? const _WaitingForBot()
              : QuestionView(question: _deck[_index], picked: _picked, onPick: _pick),
        ),
      ],
    );
  }
}

class _WaitingForBot extends StatelessWidget {
  const _WaitingForBot();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 34, height: 34, child: CircularProgressIndicator()),
          SizedBox(height: AppSpace.lg),
          Text('Gainsy javob beryapti…',
              style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(backgroundColor: AppColors.canvas),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpace.xxl),
          child: Text(
            "Bu to'plamda o'yin uchun yetarli so'z yo'q.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}
