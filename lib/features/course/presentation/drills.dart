import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/models.dart';

/// The seven exercise types, as widgets.
///
/// One `switch` on the server's own name for the drill, so a type added on the
/// server is a case added here and nothing else changes. The server never sends
/// the answer, so nothing in this file knows one — an answer is collected and
/// handed upwards, and the verdict comes back from the server.
abstract final class LessonPalette {
  // Mapped onto the app's own tokens rather than kept as a private dark
  // set. Three screens in this section each carried an identical copy of
  // that palette while the lesson and test-out screens next door already
  // used AppColors — so the course was the only place in the app that
  // went dark, and it was not even consistent with itself.
  static const canvas = AppColors.canvas;
  static const surface = AppColors.surface;
  static const raised = AppColors.canvasAlt;
  static const line = AppColors.line;
  static const ink = AppColors.ink;
  static const soft = AppColors.inkSoft;
  static const faint = AppColors.inkFaint;
  static const right = AppColors.success;
  static const wrong = AppColors.danger;
  static const gold = AppColors.xp;
  static const pick = AppColors.speaking;
}

/// The line that says what is being asked.
///
/// The whole reason it exists: four words in a box do not say whether you are
/// choosing a meaning, choosing a word, or matching pairs, and a learner who
/// cannot tell puts the phone down.
String instructionFor(String type, AppLocalizations l) => switch (type) {
  'vocab_recognise' => l.drillPickMeaning,
  'vocab_recall' => l.drillPickWord,
  'vocab_match' => l.drillMatchPairs,
  'grammar_mcq' => l.drillPickAnswer,
  'grammar_reorder' => l.drillOrderWords,
  'grammar_fill_blank' => l.drillTypeMissing,
  'grammar_transform' => l.drillRewrite,
  _ => l.drillPickAnswer,
};

class DrillView extends StatelessWidget {
  const DrillView({
    super.key,
    required this.drill,
    required this.locked,
    required this.onChanged,
  });

  final Drill drill;

  /// True once the answer has been checked — the exercise stops accepting taps
  /// so a learner cannot "fix" an answer while reading why it was wrong.
  final bool locked;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) => switch (drill.type) {
    'vocab_match' => _Match(drill: drill, locked: locked, onChanged: onChanged),
    'grammar_reorder' =>
      _Reorder(drill: drill, locked: locked, onChanged: onChanged),
    'grammar_fill_blank' || 'grammar_transform' =>
      _Typed(drill: drill, locked: locked, onChanged: onChanged),
    _ => _Choice(drill: drill, locked: locked, onChanged: onChanged),
  };
}

/// The prompt, given the room a question deserves.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.text, this.big = false});

  final String text;
  final bool big;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      color: LessonPalette.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: LessonPalette.line),
    ),
    child: Text(
      text,
      textAlign: big ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: LessonPalette.ink,
        fontSize: big ? 28 : 19,
        height: 1.35,
        fontWeight: big ? FontWeight.w900 : FontWeight.w700,
      ),
    ),
  );
}

/// Pick one of four — the shape most of the bank uses.
class _Choice extends StatefulWidget {
  const _Choice({
    required this.drill,
    required this.locked,
    required this.onChanged,
  });

  final Drill drill;
  final bool locked;
  final ValueChanged<Object?> onChanged;

  @override
  State<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends State<_Choice> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final vocab = widget.drill.type.startsWith('vocab');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A single word gets the big treatment; a sentence with a gap in it
        // does not, or it wraps onto four lines and stops being readable.
        _Prompt(text: widget.drill.prompt, big: vocab),
        const SizedBox(height: AppSpace.lg),
        for (final option in widget.drill.options) ...[
          _Option(
            text: option,
            picked: _picked == option,
            locked: widget.locked,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _picked = option);
              widget.onChanged(option);
            },
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.text,
    required this.picked,
    required this.locked,
    required this.onTap,
  });

  final String text;
  final bool picked;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: picked
        ? LessonPalette.pick.withValues(alpha: 0.16)
        : LessonPalette.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: locked ? null : onTap,
      child: Container(
        // 60 high, not 44: this is the control the whole screen exists for and
        // it is pressed eight times a lesson, often on a moving bus.
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: picked ? LessonPalette.pick : LessonPalette.line,
            width: picked ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: picked ? LessonPalette.ink : LessonPalette.soft,
            fontSize: 16,
            fontWeight: picked ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// Build the sentence from word tiles.
class _Reorder extends StatefulWidget {
  const _Reorder({
    required this.drill,
    required this.locked,
    required this.onChanged,
  });

  final Drill drill;
  final bool locked;
  final ValueChanged<Object?> onChanged;

  @override
  State<_Reorder> createState() => _ReorderState();
}

class _ReorderState extends State<_Reorder> {
  late final List<String> _pool = [...widget.drill.tiles];
  final _built = <String>[];

  void _emit() => widget.onChanged(_built.isEmpty ? null : List.of(_built));

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.drill.prompt.isNotEmpty) ...[
        _Prompt(text: widget.drill.prompt),
        const SizedBox(height: AppSpace.lg),
      ],
      // The answer line, always visible even when empty. A blank area that
      // appears only after the first tap gives no clue where the words go.
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: LessonPalette.canvas,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: LessonPalette.line, style: BorderStyle.solid, width: 1.5),
        ),
        child: Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final word in _built)
              _Tile(
                text: word,
                filled: true,
                onTap: widget.locked
                    ? null
                    : () {
                        setState(() {
                          _built.remove(word);
                          _pool.add(word);
                        });
                        _emit();
                      },
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.lg),
      Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final word in _pool)
            _Tile(
              text: word,
              filled: false,
              onTap: widget.locked
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _pool.remove(word);
                        _built.add(word);
                      });
                      _emit();
                    },
            ),
        ],
      ),
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.text, required this.filled, this.onTap});

  final String text;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? LessonPalette.pick.withValues(alpha: 0.2) : LessonPalette.raised,
    borderRadius: BorderRadius.circular(AppRadius.md),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: filled ? LessonPalette.pick : LessonPalette.line),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: LessonPalette.ink,
              fontSize: 15.5,
              fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

/// Match five words to five meanings.
class _Match extends StatefulWidget {
  const _Match({
    required this.drill,
    required this.locked,
    required this.onChanged,
  });

  final Drill drill;
  final bool locked;
  final ValueChanged<Object?> onChanged;

  @override
  State<_Match> createState() => _MatchState();
}

class _MatchState extends State<_Match> {
  final _pairs = <String, String>{};
  String? _holding;

  void _tapLeft(String id) {
    if (widget.locked) return;
    HapticFeedback.selectionClick();
    setState(() => _holding = _holding == id ? null : id);
  }

  void _tapRight(String id) {
    if (widget.locked) return;
    final left = _holding;
    if (left == null) return;
    setState(() {
      _pairs.removeWhere((_, v) => v == id);
      _pairs[left] = id;
      _holding = null;
    });
    widget.onChanged(_pairs.isEmpty ? null : Map.of(_pairs));
  }

  @override
  Widget build(BuildContext context) {
    final takenRight = _pairs.values.toSet();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: [
            for (final item in widget.drill.left) ...[
              _MatchCell(
                text: item.text,
                // Three states, and they have to be distinguishable at a
                // glance or matching becomes guesswork: waiting, held, paired.
                state: _pairs.containsKey(item.id)
                    ? _CellState.paired
                    : _holding == item.id
                        ? _CellState.held
                        : _CellState.idle,
                onTap: () => _tapLeft(item.id),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          ]),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(children: [
            for (final item in widget.drill.right) ...[
              _MatchCell(
                text: item.text,
                state: takenRight.contains(item.id)
                    ? _CellState.paired
                    : _CellState.idle,
                onTap: () => _tapRight(item.id),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          ]),
        ),
      ],
    );
  }
}

enum _CellState { idle, held, paired }

class _MatchCell extends StatelessWidget {
  const _MatchCell({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _CellState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (border, fill) = switch (state) {
      _CellState.held => (LessonPalette.pick, LessonPalette.pick.withValues(alpha: 0.2)),
      _CellState.paired => (LessonPalette.right, LessonPalette.right.withValues(alpha: 0.14)),
      _CellState.idle => (LessonPalette.line, LessonPalette.surface),
    };
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: state == _CellState.idle
                  ? LessonPalette.soft
                  : LessonPalette.ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Type the missing word, or rewrite the sentence.
class _Typed extends StatefulWidget {
  const _Typed({
    required this.drill,
    required this.locked,
    required this.onChanged,
  });

  final Drill drill;
  final bool locked;
  final ValueChanged<Object?> onChanged;

  @override
  State<_Typed> createState() => _TypedState();
}

class _TypedState extends State<_Typed> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Prompt(text: widget.drill.prompt),
      const SizedBox(height: AppSpace.lg),
      TextField(
        controller: _controller,
        enabled: !widget.locked,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (v) => widget.onChanged(v.trim().isEmpty ? null : v.trim()),
        // Every colour named. On the web the IME sits in a real DOM input that
        // inherits the page's styling, and unnamed colours there mean a learner
        // typing into what looks like an empty box.
        style: const TextStyle(
            color: LessonPalette.ink, fontSize: 18, fontWeight: FontWeight.w700),
        cursorColor: LessonPalette.pick,
        decoration: InputDecoration(
          filled: true,
          fillColor: LessonPalette.surface,
          hintStyle: const TextStyle(color: LessonPalette.faint),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.lg),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: LessonPalette.line, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: LessonPalette.pick, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: LessonPalette.line, width: 1.5),
          ),
        ),
      ),
    ],
  );
}
