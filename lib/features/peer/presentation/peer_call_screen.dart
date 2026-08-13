import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/share.dart';
import '../../../core/ui/back_or_home.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/user_photo.dart';
import '../../questions/application/providers.dart';
import '../../questions/presentation/question_home.dart';
import '../../questions/presentation/questions_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../application/peer_call_controller.dart';

/// The live 1:1 call. Three journeys share this screen:
/// - match: searching animation → partner found → call
/// - create: waiting room (code + Telegram invite) → call
/// - join: straight into the handshake → call
class PeerCallScreen extends ConsumerStatefulWidget {
  const PeerCallScreen({required this.launch, super.key});

  final PeerLaunch launch;

  @override
  ConsumerState<PeerCallScreen> createState() => _PeerCallScreenState();
}

class _PeerCallScreenState extends ConsumerState<PeerCallScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onPhase(PeerPhase? previous, PeerPhase next) {
    if (next == PeerPhase.inCall && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
    if (next == PeerPhase.ended) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _shareInvite(String code) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(apiClientProvider);
    final text = l.peerInviteShareText(code);
    final outcome = await shareInvite(
      text,
      prepare: () => prepareInvite(api, text: text),
    );
    if (!mounted || outcome != ShareOutcome.copied) return;
    messenger.showSnackBar(SnackBar(content: Text(l.inviteCopied)));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = peerCallControllerProvider(widget.launch);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider, (prev, next) => _onPhase(prev?.phase, next.phase));

    return Scaffold(
      backgroundColor: AppColors.inkDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Keeps remote audio flowing on web (a renderer must be mounted).
            SizedBox(
              width: 1,
              height: 1,
              child: RTCVideoView(controller.remoteRenderer),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusHeader(state: state, elapsed: _fmt(_elapsed)),
                  const SizedBox(height: AppSpace.xl),
                  if (state.phase == PeerPhase.searching)
                    const Expanded(child: _SearchingView())
                  else ...[
                    if (state.phase == PeerPhase.waiting &&
                        widget.launch is PeerLaunchCreate)
                      _WaitingCard(
                        code: state.roomCode,
                        onShare: () => _shareInvite(state.roomCode),
                      ),
                    if (state.partnerName.isNotEmpty &&
                        (state.phase == PeerPhase.rtcConnecting ||
                            state.phase == PeerPhase.inCall)) ...[
                      _PartnerBadge(
                        name: state.partnerName,
                        avatar: state.partnerAvatar,
                      ),
                      const SizedBox(height: AppSpace.md),
                      // Silence with a reason.
                      //
                      // Without this the learner hears nothing, has no way to
                      // know why, and concludes the app is broken — which is
                      // precisely the report that came in about iPhone and
                      // Android calls. The other side is audible to them; only
                      // this direction is dead, and saying so costs one line.
                      if (state.partnerMicOff) ...[
                        _MicWarning(
                          text: AppLocalizations.of(context).peerPartnerMicOff,
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],
                    ],
                    // Everything between the partner and the controls scrolls.
                    // The parts panel is four tiles tall and the role-play card
                    // is not short; pinned in a Column they would push the
                    // hang-up button off a small phone.
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppSpace.sm),
                            // On the screen rather than behind the ? button.
                            // Someone whose conversation has just stalled will
                            // not go looking through a menu for a way out of
                            // the silence — the way out has to be in front of
                            // them before they need it.
                            const _QuestionPanel(),
                            const SizedBox(height: AppSpace.md),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (state.phase == PeerPhase.ended)
                    _EndedPanel(reason: state.endReason)
                  else
                    _CallControls(
                      searching: state.phase == PeerPhase.searching,
                      muted: state.muted,
                      micDenied: state.micDenied,
                      // Nothing to unmute when there is no microphone. A
                      // control that looks live and does nothing is worse than
                      // one that is plainly disabled.
                      onMute: state.micDenied ? null : controller.toggleMute,
                      onHangUp: controller.hangUp,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An amber strip, not a red one: nothing has failed, and the call is worth
/// staying in — one direction of it simply carries no audio.
class _MicWarning extends StatelessWidget {
  const _MicWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.sm + 2,
    ),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mic_off_rounded, size: 17, color: AppColors.warning),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state, required this.elapsed});

  final PeerCallState state;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (label, color) = switch (state.phase) {
      PeerPhase.connecting => (l.peerStatusConnecting, AppColors.inkFaint),
      PeerPhase.searching => (l.peerStatusSearching, AppColors.warning),
      PeerPhase.waiting => (l.peerStatusWaitingFriend, AppColors.warning),
      PeerPhase.rtcConnecting => (l.peerStatusConnectingVoice, AppColors.warning),
      PeerPhase.inCall => (l.peerStatusLiveChat(elapsed), AppColors.success),
      PeerPhase.ended => (l.peerStatusEnded, AppColors.inkFaint),
    };
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (state.phase == PeerPhase.connecting ||
            state.phase == PeerPhase.rtcConnecting)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

/// Pulsing rings while the queue looks for a partner — calm, alive, premium.
class _SearchingView extends StatefulWidget {
  const _SearchingView();

  @override
  State<_SearchingView> createState() => _SearchingViewState();
}

class _SearchingViewState extends State<_SearchingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final offset in [0.0, 0.5]) ...[
                    _ring(((_pulse.value + offset) % 1.0)),
                  ],
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.accent(AppColors.speaking),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 44),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpace.xxl),
        Text(
          AppLocalizations.of(context).peerSearchingTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          AppLocalizations.of(context).peerSearchingSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _ring(double t) {
    return Container(
      width: 108 + t * 110,
      height: 108 + t * 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.speaking.withValues(alpha: (1 - t) * 0.45),
          width: 2,
        ),
      ),
    );
  }
}

class _PartnerBadge extends StatelessWidget {
  const _PartnerBadge({required this.name, this.avatar = ''});

  final String name;

  /// Their picture, or empty. Empty is ordinary — the initial stands in.
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lineDark),
      ),
      child: Row(
        children: [
          // The photo sits on the letter rather than replacing it, so a slow
          // or expired URL degrades to a coloured initial instead of a hole.
          UserPhoto(
            url: avatar,
            size: 44,
            fallback: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.speaking.withValues(alpha: 0.2),
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).peerYourPartner,
                  style: const TextStyle(color: AppColors.inkFaint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.code, required this.onShare});

  final String code;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lineDark),
      ),
      child: Column(
        children: [
          Text(
            l.peerRoomCode,
            style: const TextStyle(color: AppColors.inkFaint, fontSize: 12.5),
          ),
          const SizedBox(height: AppSpace.sm),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.groupCodeCopied)),
              );
            },
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2AABEE), // Telegram blue
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xxl,
                vertical: 14,
              ),
            ),
            onPressed: onShare,
            icon: const Icon(Icons.send_rounded),
            label: Text(l.peerInviteTelegram),
          ),
        ],
      ),
    );
  }
}



class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.searching,
    required this.muted,
    required this.micDenied,
    required this.onMute,
    required this.onHangUp,
  });

  final bool searching;
  final bool muted;
  final bool micDenied;
  final VoidCallback? onMute;
  final VoidCallback onHangUp;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return Center(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xxl, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: onHangUp,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: Text(AppLocalizations.of(context).peerStopSearching),
        ),
      );
    }
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only when there is something to say. With a working microphone —
        // which is the ordinary case — the controls look exactly as they did
        // before any of this, because that is the version that worked.
        // The old copy here said "press again" while the button beside it was
        // disabled — an instruction the interface could not carry out. Now it
        // says the thing that actually works: leave and start again, with the
        // microphone answered at the door.
        //
        // Reaching this state at all should be rare: every entry point now
        // opens the microphone before a search begins. It survives for the one
        // case the gate cannot cover — a microphone that dies mid-call.
        if (micDenied) ...[
          Text(
            l.peerNoMicRejoin,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: muted ? AppColors.warning : AppColors.surfaceDark,
          iconColor: muted ? Colors.white : Colors.white70,
          onTap: onMute,
        ),
        const SizedBox(width: AppSpace.lg),
        _RoundButton(
          icon: Icons.call_end_rounded,
          color: AppColors.danger,
          iconColor: Colors.white,
          size: 68,
          onTap: onHangUp,
        ),
      ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  /// Null disables the button — used for the mic when there is no microphone
  /// to toggle.
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.45),
        ),
      ),
    );
  }
}

class _EndedPanel extends StatelessWidget {
  const _EndedPanel({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Running out of daily minutes is not a failure, and must not read like
    // one: "the call failed" invites a retry that will fail identically, while
    // the real answer is a plan.
    final outOfMinutes = reason == 'peer_quota';
    final message = switch (reason) {
      'partner_left' => l.peerEndedPartnerLeft,
      'you_ended' => l.peerEndedYouEnded,
      'peer_quota' => l.peerQuotaTitle,
      'failed' => l.peerEndedFailed,
      _ => l.peerEndedDefault,
    };
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
        if (outOfMinutes) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            l.peerQuotaBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        if (outOfMinutes)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.speaking,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xxxl,
                vertical: 14,
              ),
            ),
            onPressed: () {
              popOrHome(context);
              context.push('/subscriptions');
            },
            child: Text(l.premiumButton),
          )
        else
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.speaking,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xxxl,
                vertical: 14,
              ),
            ),
            onPressed: () => popOrHome(context),
            child: Text(l.backAction),
          ),
        if (outOfMinutes)
          TextButton(
            onPressed: () => popOrHome(context),
            child: Text(
              l.backAction,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
      ],
    );
  }
}

/// The question parts, on the call screen itself.
///
/// The bank is fetched once per session and kept, so this costs a request the
/// first time a learner opens a call and nothing afterwards. While it is in
/// flight, and if it fails, this draws nothing at all rather than a spinner or
/// an error: the call is the thing on this screen, and a failed side-panel must
/// not become something to read about mid-conversation.
class _QuestionPanel extends ConsumerWidget {
  const _QuestionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(questionBankProvider);
    return bank.maybeWhen(
      data: (parts) => parts.isEmpty
          ? const SizedBox.shrink()
          : QuestionHome(
              parts: parts,
              embedded: true,
              onDark: true,
              savedCount: ref.watch(bookmarksProvider).length,
              // Browsing is still the sheet's job — it can go full height and
              // scroll, which a panel wedged above the call controls cannot.
              onSaved: () => showQuestionsSheet(context),
              onPart: (i) => showQuestionsSheet(context, partIndex: i),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}