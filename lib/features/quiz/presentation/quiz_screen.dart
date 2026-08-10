import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/back_or_home.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../vocabulary/presentation/widgets/game_widgets.dart';
import '../application/quiz_controller.dart';
import '../domain/models.dart';
import 'widgets/quiz_board_view.dart';
import 'widgets/quiz_lobby.dart';
import 'widgets/quiz_timer_ring.dart';

/// One shared question, everybody at once.
///
/// There is no lobby and no start button because there is nothing to wait for:
/// the match is derived from the clock, so opening this screen puts you in the
/// question that is live with the seconds that are left on it. Arriving at
/// question six is not a worse experience than arriving at question one — it
/// is a shorter one, and a new match begins within three minutes.
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizControllerProvider);
    final live = state.live;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        // Always present. A notification opens this screen as the whole
        // stack, so without it there is no way back out but closing the app.
        leading: const BackOrHome(),
        title: Text(l10n.quizTitle),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (live != null && live.players.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.lg),
              child: Center(child: _LiveChip(playing: live.players.length)),
            ),
        ],
      ),
      body: SafeArea(
        child: switch ((state.loading, live)) {
          (true, _) => const Center(child: CircularProgressIndicator()),
          (_, null) => _Empty(message: state.error ?? l10n.quizEmpty),
          // A lobby is not a degraded match — it is the screen, until enough
          // people are in it.
          (_, final QuizState s) when !s.isPlaying => QuizLobby(
            state: s,
            busy: state.busy,
            onStart: () => ref.read(quizControllerProvider.notifier).start(),
            onReady: () => ref.read(quizControllerProvider.notifier).ready(),
          ),
          (_, final QuizState s) => s.phase == QuizPhase.result
              ? _ResultBody(state: s, secondsLeft: state.secondsLeft)
              : _PlayBody(state: state, live: s),
        },
      ),
    );
  }
}

// ── playing ─────────────────────────────────────────────────────────────────
class _PlayBody extends ConsumerWidget {
  const _PlayBody({required this.state, required this.live});

  final QuizState$ state;
  final QuizState live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final revealing = live.phase != QuizPhase.answer;
    final correct = live.question.correct;

    return Column(
      children: [
        _Progress(index: live.index, total: live.total),
        const SizedBox(height: AppSpace.lg),
        QuizTimerRing(
          secondsLeft: state.secondsLeft,
          // The ring drains over whichever window is running, so the reveal
          // reads as a short beat rather than a stalled timer.
          total: revealing ? 4 : 15,
        ),
        const SizedBox(height: AppSpace.lg),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Prompt(question: live.question),
                const SizedBox(height: AppSpace.lg),
                for (var i = 0; i < live.question.options.length; i++) ...[
                  OptionButton(
                    label: live.question.options[i],
                    state: _optionState(
                      index: i,
                      chosen: state.chosen,
                      correct: correct,
                      revealing: revealing,
                    ),
                    onTap: revealing || state.answered
                        ? null
                        : () => ref
                              .read(quizControllerProvider.notifier)
                              .choose(i),
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
                if (revealing) _Verdict(state: state, question: live.question),
                const SizedBox(height: AppSpace.md),
                QuizBoardView(
                  board: live.matchBoard,
                  title: l10n.quizMatchBoard,
                ),
                const SizedBox(height: AppSpace.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

OptionState _optionState({
  required int index,
  required int? chosen,
  required int? correct,
  required bool revealing,
}) {
  if (!revealing) {
    if (chosen == null) return OptionState.idle;
    return chosen == index ? OptionState.correct : OptionState.dimmed;
  }
  if (correct == index) return OptionState.correct;
  if (chosen == index) return OptionState.wrong;
  return OptionState.dimmed;
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, colour) = switch (question.kind) {
      'grammar' => (l10n.quizGrammar, AppColors.grammar),
      'meaning_word' => (l10n.quizPickWord, AppColors.vocabulary),
      'gap' => (l10n.quizFillGap, AppColors.vocabulary),
      _ => (l10n.quizPickMeaning, AppColors.vocabulary),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: colour,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.state, required this.question});

  final QuizState$ state;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verdict = state.verdict;
    final (text, colour) = switch ((state.answered, verdict?.correct)) {
      (false, _) => (l10n.quizTimeUp, AppColors.inkFaint),
      (_, true) => (l10n.quizCorrect, AppColors.success),
      _ => (l10n.quizWrong, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colour,
                ),
              ),
              const Spacer(),
              if ((verdict?.points ?? 0) > 0)
                Text(
                  l10n.quizPoints(verdict!.points),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDeep,
                  ),
                ),
            ],
          ),
          if (question.note.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              question.note,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── between matches ─────────────────────────────────────────────────────────
class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.state, required this.secondsLeft});

  final QuizState state;
  final double secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadow.glow(AppColors.brand),
            ),
            child: Column(
              children: [
                Text(
                  l10n.quizMatchOver,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  l10n.quizNextMatch(secondsLeft.ceil()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          // One board. The day-long one that used to sit under this showed
          // the same three faces with bigger numbers, and worse: a newcomer
          // read it, saw a total they could not catch, and was right. Every
          // match starts everybody on zero, which is the only thing that makes
          // joining at question six worth doing.
          QuizBoardView(
            board: state.matchBoard,
            title: l10n.quizMatchBoard,
            podium: true,
            limit: 10,
          ),
        ],
      ),
    );
  }
}

// ── chrome ──────────────────────────────────────────────────────────────────
class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              width: i == index ? 26 : 14,
              decoration: BoxDecoration(
                color: i < index
                    ? AppColors.brand
                    : i == index
                    ? AppColors.brandDark
                    : AppColors.line,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.playing});

  final int playing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Never a fabricated number. This is pruned presence — if it says two, two
    // people are here. An invented crowd is the fastest way to lose the room.
    final alone = playing <= 1;
    final colour = alone ? AppColors.inkFaint : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            alone ? l10n.quizAlone : l10n.quizPlaying(playing),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
