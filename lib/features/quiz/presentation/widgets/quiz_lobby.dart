import 'package:flutter/material.dart';

import '../../../../core/ui/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models.dart';

/// Before the match: nobody has started one, or one is waiting for people.
///
/// The whole screen is about a single fact — how many are here, and how many
/// more are needed — because that is the only question anybody in a lobby has.
/// Everything else waits.
class QuizLobby extends StatelessWidget {
  const QuizLobby({
    required this.state,
    required this.busy,
    required this.onStart,
    required this.onReady,
    super.key,
  });

  final QuizState state;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final idle = state.phase == QuizPhase.idle;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(
            // The hero says what this is; the button says what to do. Putting
            // "Start a quiz" in both made the screen read as a stutter.
            title: idle ? l10n.quizHubTitle : l10n.quizLobbyTitle,
            subtitle: idle
                ? l10n.quizStartHint
                : (state.needed > 0
                      ? l10n.quizWaitingFor(state.needed)
                      : l10n.quizStartingNow),
            waiting: !idle,
          ),
          if (!idle && state.hostName.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.quizHostedBy(state.hostName),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (state.players.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xl),
            _Seats(players: state.players),
          ],
          const SizedBox(height: AppSpace.xxl),
          _Action(
            label: idle
                ? l10n.quizStart
                : (state.youReady ? l10n.quizYouAreReady : l10n.quizImReady),
            // Somebody already in the lobby has nothing left to press. The
            // button stays visible so the screen does not reshuffle under
            // them, but it stops being a control.
            onTap: busy || (!idle && state.youReady)
                ? null
                : (idle ? onStart : onReady),
            busy: busy,
            done: !idle && state.youReady,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.subtitle,
    required this.waiting,
  });

  final String title;
  final String subtitle;
  final bool waiting;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.xl,
      vertical: AppSpace.xxl,
    ),
    decoration: BoxDecoration(
      gradient: AppGradients.brand,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: AppShadow.glow(AppColors.brand),
    ),
    child: Column(
      children: [
        Icon(
          waiting ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
          color: Colors.white,
          size: 34,
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    ),
  );
}

/// Who is here. Real names of real people — the count is presence, pruned,
/// never a number invented to make the room look busier than it is.
class _Seats extends StatelessWidget {
  const _Seats({required this.players});

  final List<QuizSeat> players;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quizInLobby.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.md,
            children: [
              for (final player in players) _Seat(player: player),
            ],
          ),
        ],
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.player});

  final QuizSeat player;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62,
    child: Column(
      children: [
        Container
        (
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: player.isYou
                ? AppColors.brand.withValues(alpha: 0.16)
                : AppColors.canvasAlt,
            shape: BoxShape.circle,
            border: player.isYou
                ? Border.all(color: AppColors.brand, width: 2)
                : null,
          ),
          child: Text(
            player.initial,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: player.isYou ? AppColors.brandDeep : AppColors.inkSoft,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: player.isYou ? FontWeight.w800 : FontWeight.w600,
            color: player.isYou ? AppColors.brandDeep : AppColors.inkSoft,
          ),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    required this.busy,
    required this.done,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.brandTint : AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: done ? null : AppShadow.glow(AppColors.brand),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (done) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.brandDeep,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: done ? AppColors.brandDeep : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
