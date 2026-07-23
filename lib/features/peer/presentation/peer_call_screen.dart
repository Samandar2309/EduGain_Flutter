import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/tokens.dart';
import '../application/peer_call_controller.dart';
import '../data/peer_models.dart';

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
    final text = Uri.encodeComponent(
      'EduGain’da men bilan jonli ingliz tili suhbatiga qo‘shiling! '
      'Ilovadagi “Jonli suhbat” bo‘limida shu kodni kiriting: $code',
    );
    final uri = Uri.parse('https://t.me/share/url?url=&text=$text');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                      _PartnerBadge(name: state.partnerName),
                      const SizedBox(height: AppSpace.md),
                    ],
                    if (state.topic != null) ...[
                      const SizedBox(height: AppSpace.md),
                      _TopicCard(topic: state.topic!),
                    ],
                    const Spacer(),
                  ],
                  if (state.phase == PeerPhase.ended)
                    _EndedPanel(reason: state.endReason)
                  else
                    _CallControls(
                      searching: state.phase == PeerPhase.searching,
                      muted: state.muted,
                      onMute: controller.toggleMute,
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

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state, required this.elapsed});

  final PeerCallState state;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state.phase) {
      PeerPhase.connecting => ('Ulanmoqda…', AppColors.inkFaint),
      PeerPhase.searching => ('Partner qidirilmoqda…', AppColors.warning),
      PeerPhase.waiting => ('Do‘stingiz kutilmoqda', AppColors.warning),
      PeerPhase.rtcConnecting => ('Ovoz ulanmoqda…', AppColors.warning),
      PeerPhase.inCall => ('Jonli suhbat · $elapsed', AppColors.success),
      PeerPhase.ended => ('Suhbat tugadi', AppColors.inkFaint),
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
        const Text(
          'Sizga mos partner qidirilmoqda…',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        const Text(
          'Boshqa o‘quvchi qidiruvni boshlashi bilan\navtomatik ulanasiz',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
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
  const _PartnerBadge({required this.name});

  final String name;

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
          CircleAvatar(
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
                const Text(
                  'Suhbat partneringiz',
                  style: TextStyle(color: AppColors.inkFaint, fontSize: 12),
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
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lineDark),
      ),
      child: Column(
        children: [
          const Text(
            'Xona kodi',
            style: TextStyle(color: AppColors.inkFaint, fontSize: 12.5),
          ),
          const SizedBox(height: AppSpace.sm),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kod nusxalandi')),
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
            label: const Text('Telegram orqali taklif qilish'),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final PeerTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lineDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.theater_comedy_rounded,
                  color: AppColors.speaking, size: 20),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  topic.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          _RoleLine(label: 'Sizning rolingiz', text: topic.yourRole),
          const SizedBox(height: AppSpace.sm),
          _RoleLine(label: 'Partner roli', text: topic.partnerRole),
          if (topic.starters.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.speaking.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '💬 “${topic.starters.first}”',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleLine extends StatelessWidget {
  const _RoleLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.inkFaint, fontSize: 11.5)),
        const SizedBox(height: 2),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
        ),
      ],
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.searching,
    required this.muted,
    required this.onMute,
    required this.onHangUp,
  });

  final bool searching;
  final bool muted;
  final VoidCallback onMute;
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
          label: const Text('Qidiruvni to‘xtatish'),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: muted ? AppColors.warning : AppColors.surfaceDark,
          iconColor: muted ? Colors.white : Colors.white70,
          onTap: onMute,
        ),
        const SizedBox(width: AppSpace.xxl),
        _RoundButton(
          icon: Icons.call_end_rounded,
          color: AppColors.danger,
          iconColor: Colors.white,
          size: 68,
          onTap: onHangUp,
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
  final VoidCallback onTap;
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
    final message = switch (reason) {
      'partner_left' => 'Partner suhbatni tark etdi.',
      'you_ended' => 'Suhbat yakunlandi. Yaxshi mashq! 👏',
      'failed' => 'Ulanishda muammo yuz berdi. Qayta urinib ko‘ring.',
      _ => 'Suhbat tugadi.',
    };
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: AppSpace.lg),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.speaking,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xxxl,
              vertical: 14,
            ),
          ),
          onPressed: () => context.pop(),
          child: const Text('Orqaga'),
        ),
      ],
    );
  }
}
