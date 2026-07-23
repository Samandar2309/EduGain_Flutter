import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../application/peer_call_controller.dart';
import '../data/peer_models.dart';

/// The live-speaking hub (Sayra-style): one big "find a partner" action, the
/// learner's conversation history below, and friend rooms as a quiet
/// secondary path.
class PeerHubScreen extends ConsumerWidget {
  const PeerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(peerHubProvider);
    final online = hub.valueOrNull?.online ?? 0;
    final calls = hub.valueOrNull?.calls ?? const <PeerCallLog>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Jonli suhbat')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(peerHubProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
          children: [
            _FindPartnerHero(
              online: online,
              onFind: () =>
                  context.push('/peer/call', extra: PeerLaunch.match),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.group_add_rounded,
                    label: 'Do‘st bilan xona',
                    onTap: () =>
                        context.push('/peer/call', extra: PeerLaunch.create),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.pin_rounded,
                    label: 'Kod bilan kirish',
                    onTap: () => _askCode(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
            Row(
              children: [
                const Text(
                  'Suhbatlar tarixi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (calls.isNotEmpty)
                  Text(
                    '${calls.length} ta suhbat',
                    style: const TextStyle(
                        color: AppColors.inkFaint, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            if (hub.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.xxxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (calls.isEmpty)
              const _EmptyHistory()
            else
              ...calls.map((c) => _HistoryTile(call: c)),
          ],
        ),
      ),
    );
  }

  Future<void> _askCode(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Xona kodi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 6),
          decoration: const InputDecoration(counterText: '', hintText: 'ABC123'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Kirish'),
          ),
        ],
      ),
    );
    final cleaned = code?.trim().toUpperCase() ?? '';
    if (cleaned.length == 6 && context.mounted) {
      context.push('/peer/call', extra: PeerLaunchJoin(cleaned));
    }
  }
}

class _FindPartnerHero extends StatelessWidget {
  const _FindPartnerHero({required this.online, required this.onFind});

  final int online;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpace.xxxl, horizontal: AppSpace.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          if (online > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$online kishi onlayn',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onFind,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.accent(AppColors.speaking),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.speaking.withValues(alpha: 0.45),
                      blurRadius: 34,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: Colors.white, size: 48),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          const Text(
            'Partner topish',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Onlayn o‘quvchi bilan tasodifiy ulanib,\ninglizcha jonli suhbat quring',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xxl),
      decoration: BoxDecoration(
        color: AppColors.canvasAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_outlined, color: AppColors.inkFaint, size: 34),
          SizedBox(height: AppSpace.md),
          Text(
            'Hali suhbatlaringiz yo‘q',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Birinchi partneringizni toping — har bir suhbat\nshu yerda saqlanadi.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.inkSoft, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.call});

  final PeerCallLog call;

  String get _duration {
    final m = call.durationSeconds ~/ 60;
    final s = call.durationSeconds % 60;
    return m > 0 ? '$m min $s s' : '$s s';
  }

  String get _when {
    final now = DateTime.now();
    final d = call.startedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Bugun';
    if (diff == 1) return 'Kecha';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        call.partnerName.isNotEmpty ? call.partnerName[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.speaking.withValues(alpha: 0.14),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.speaking,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.partnerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${call.topic} · $_when',
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.speaking.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _duration,
              style: const TextStyle(
                color: AppColors.speaking,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
