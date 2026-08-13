import 'package:flutter/material.dart';

import '../../../core/ui/back_or_home.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/peer_call_controller.dart';
import 'mic_gate.dart';
import '../data/peer_models.dart';

/// The live-speaking hub (Sayra-style): one big "find a partner" action, the
/// learner's conversation history below, and friend rooms as a quiet
/// secondary path.
class PeerHubScreen extends ConsumerWidget {
  const PeerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final hub = ref.watch(peerHubProvider);
    final online = hub.valueOrNull?.online ?? 0;
    final calls = hub.valueOrNull?.calls ?? const <PeerCallLog>[];

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(),
        title: Text(l.peerLiveChat),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(peerHubProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
          children: [
            _FindPartnerHero(
              online: online,
              // Ask before searching, not after. A learner dropped into a
              // random live call and only then offered a filter has already
              // had the conversation they were trying to choose.
              // One tap, one thing: microphone, then search.
              //
              // A gender filter used to sit between the two, and the numbers
              // killed it. 53% of accounts carry no gender at all, and the
              // matcher treats an unknown gender as satisfying no gendered
              // filter — so choosing one hid every one of those learners, and
              // choosing nothing still hid you from anyone else who chose. In
              // a pool this size that is not a narrower search, it is no
              // search: the queue is empty most of the day.
              //
              // The filter can come back when there are enough people online
              // for it to narrow something rather than empty it.
              //
              // What remains is the rule that matters: the microphone is the
              // FIRST thing this tap does. Nothing may come before it.
              //
              // A browser grants a tap a short window in which it will show a
              // permission dialog, and every await spends some of it. Opening
              // the filter sheet first spent the most expensive kind: a route
              // push, a frame, a human reading three options, a second tap and
              // a dismissal animation. Chrome tolerated that; WebKit's
              // activation model is stricter, and Telegram's iOS WebView is
              // WebKit — there the dialog never appeared and the request was
              // refused in silence.
              //
              // So: microphone, then the filter, then the search. The learner
              // answers one question before being asked to choose anything,
              // which is also the honest order — there is nothing to choose
              // if they cannot speak.
              onFind: () async {
                if (!await ensureMicrophoneReady(context, ref)) return;
                if (!context.mounted) return;
                context.push('/peer/call', extra: const PeerLaunchMatch());
              },
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.group_add_rounded,
                    label: l.peerFriendRoom,
                    // Same rule as the search: the microphone is opened on the
                    // tap. Opening a room and then finding out you cannot speak
                    // in it wastes the friend's time as well as your own.
                    onTap: () async {
                      if (!await ensureMicrophoneReady(context, ref)) return;
                      if (!context.mounted) return;
                      context.push('/peer/call', extra: PeerLaunch.create);
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.pin_rounded,
                    label: l.peerJoinByCode,
                    onTap: () => _askCode(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
            Row(
              children: [
                Text(
                  l.peerHistory,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (calls.isNotEmpty)
                  Text(
                    l.peerConvCount(calls.length),
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

  Future<void> _askCode(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(l.peerRoomCode),
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
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l.peerEnter),
          ),
        ],
      ),
    );
    final cleaned = code?.trim().toUpperCase() ?? '';
    if (cleaned.length != 6 || !context.mounted) return;
    // The code is typed and confirmed; the microphone is the last thing
    // between here and a room where somebody may already be waiting.
    if (!await ensureMicrophoneReady(context, ref)) return;
    if (!context.mounted) return;
    context.push('/peer/call', extra: PeerLaunchJoin(cleaned));
  }
}

class _FindPartnerHero extends StatelessWidget {
  const _FindPartnerHero({required this.online, required this.onFind});

  final int online;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                    l.peerOnlineCount(online),
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
                // A magnifier with a person in it, not a speaking head.
                //
                // The card says "find a partner" and the action is a search —
                // the app looks for somebody who is online right now. A talking
                // figure describes what happens AFTER the match, which is the
                // step nobody is confused about. `person_search` says both: it
                // is a search, and it is a search for a person.
                child: const Icon(Icons.person_search_rounded,
                    color: Colors.white, size: 48),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            l.peerFindPartner,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.peerFindPartnerSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppSpace.lg),
          // An explicit button, not just a tappable circle.
          //
          // The whole card already responded to a tap, and learners told us
          // they could not tell what to do. A big glowing circle is a
          // designer's idea of an invitation; a control that looks like a
          // button and says what pressing it does is everybody else's. It is
          // the same fix the course path needed, for the same reason.
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onFind,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xl, vertical: AppSpace.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 19, color: AppColors.speaking),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      l.peerFindTap,
                      style: const TextStyle(
                        color: AppColors.speaking,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.xxl),
      decoration: BoxDecoration(
        color: AppColors.canvasAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, color: AppColors.inkFaint, size: 34),
          const SizedBox(height: AppSpace.md),
          Text(
            l.peerNoHistoryTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            l.peerNoHistorySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

  String _duration(AppLocalizations l) {
    final m = call.durationSeconds ~/ 60;
    final s = call.durationSeconds % 60;
    return m > 0 ? l.peerDurMinSec(m, s) : l.peerDurSec(s);
  }

  String _when(AppLocalizations l) {
    final now = DateTime.now();
    final d = call.startedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return l.peerToday;
    if (diff == 1) return l.peerYesterday;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  '${call.topic} · ${_when(l)}',
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
              _duration(l),
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
