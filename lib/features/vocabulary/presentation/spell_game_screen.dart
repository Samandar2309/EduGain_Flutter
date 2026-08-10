import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../application/providers.dart';
import '../domain/game.dart';
import '../domain/spell_game.dart';
import 'widgets/game_widgets.dart';

/// "Harflardan yig'" — build the English word from scrambled letter tiles,
/// given only its Uzbek meaning. Productive recall, tap-only. Shares the
/// session shape (progress, combo, XP, results, SRS submit) with the other
/// vocab games.
class SpellGameScreen extends ConsumerStatefulWidget {
  const SpellGameScreen({required this.launch, super.key});

  final VocabGameLaunch launch;

  @override
  ConsumerState<SpellGameScreen> createState() => _SpellGameScreenState();
}

class _SpellGameScreenState extends ConsumerState<SpellGameScreen> {
  final _rng = Random();
  late final List<SpellChallenge> _deck;

  int _index = 0;
  final _placed = <int>[]; // bank-letter indices, in the order tapped
  bool _checked = false;
  bool _wasCorrect = false;

  int _correct = 0;
  int _combo = 0;
  int _bestCombo = 0;
  final _results = <({String itemId, bool correct})>[];
  bool _finished = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _deck = buildSpellDeck(widget.launch.items, random: _rng);
  }

  SpellChallenge get _c => _deck[_index];
  String get _answer => _placed.map((i) => _c.letters[i]).join();

  void _tapBank(int i) {
    if (_checked || _placed.contains(i)) return;
    setState(() => _placed.add(i));
    if (_placed.length == _c.word.length) _check();
  }

  void _tapSlot(int pos) {
    if (_checked || pos >= _placed.length) return;
    setState(() => _placed.removeAt(pos));
  }

  void _clear() {
    if (_checked) return;
    setState(_placed.clear);
  }

  void _check() {
    final correct = _answer == _c.word;
    HapticFeedback.lightImpact();
    setState(() {
      _checked = true;
      _wasCorrect = correct;
      _results.add((itemId: _c.itemId, correct: correct));
      if (correct) {
        _correct++;
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _combo = 0;
      }
    });
    // Silent, on purpose.
    //
    // The game used to chime on every answer and then read the word aloud a
    // third of a second later. Somebody playing on a bus, or beside a sleeping
    // child, had no way to stop it — and the pronunciation arrived while they
    // were already reading the next question, which is the moment it teaches
    // least. Hearing a word is worth a deliberate tap, and that is what the
    // word list is for.
    //
    // Haptics stay: they answer "did that register?" without making a sound.
    Future.delayed(Duration(milliseconds: correct ? 700 : 1300), () {
      if (!mounted) return;
      if (_index + 1 >= _deck.length) {
        _finish();
      } else {
        setState(() {
          _index++;
          _placed.clear();
          _checked = false;
        });
      }
    });
  }

  void _finish() {
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
      // results still show; SRS just isn't saved
    }
  }

  void _again() {
    setState(() {
      _index = 0;
      _placed.clear();
      _checked = false;
      _correct = 0;
      _combo = 0;
      _bestCombo = 0;
      _results.clear();
      _finished = false;
      _submitted = false;
    });
  }

  GameResult get _result => GameResult(
    mode: GameMode.solo,
    total: _deck.length,
    correct: _correct,
    bestCombo: _bestCombo,
    xpEarned: xpForRun(correct: _correct, bestCombo: _bestCombo),
    itemResults: _results,
  );

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) return const _EmptySpell();
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
                    value: _index / _deck.length,
                    minHeight: 10,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation(AppColors.vocabulary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              ComboBadge(combo: _combo),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpace.md),
                const Text(
                  "SO'ZNI HARFLARDAN YIG'ING",
                  style: TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                // meaning prompt
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadow.card,
                  ),
                  child: Text(
                    _c.meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                const Spacer(),
                _answerRow(),
                if (_checked && !_wasCorrect) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(
                    "To'g'ri javob: ${_c.word}",
                    style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
                const Spacer(),
                _bank(),
                const SizedBox(height: AppSpace.md),
                if (!_checked)
                  TextButton.icon(
                    onPressed: _placed.isEmpty ? null : _clear,
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Tozalash'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.inkFaint),
                  )
                else
                  const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _answerRow() {
    final len = _c.word.length;
    final filledColor = _checked
        ? (_wasCorrect ? AppColors.success : AppColors.danger)
        : AppColors.vocabulary;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(len, (pos) {
        final filled = pos < _placed.length;
        final letter = filled ? _c.letters[_placed[pos]] : '';
        return GestureDetector(
          onTap: filled ? () => _tapSlot(pos) : null,
          child: Container(
            width: 34,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? filledColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border(
                bottom: BorderSide(
                  color: filled ? filledColor : AppColors.line,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: filled ? filledColor : AppColors.ink,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _bank() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_c.letters.length, (i) {
        final used = _placed.contains(i);
        return SizedBox(
          width: 42,
          height: 50,
          child: used
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.canvasAlt,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                )
              : Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: _checked ? null : () => _tapBank(i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.line, width: 1.4),
                      ),
                      child: Text(
                        _c.letters[i].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                  ),
                ),
        );
      }),
    );
  }
}

class _EmptySpell extends StatelessWidget {
  const _EmptySpell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(backgroundColor: AppColors.canvas),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpace.xxl),
          child: Text(
            "Bu to'plamda harflardan yig'ish uchun mos so'z yo'q.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}
