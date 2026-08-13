import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/error_handling.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../application/group_providers.dart';
import '../data/group_models.dart';
import '../../peer/presentation/mic_gate.dart';
import 'group_call_screen.dart';

Future<void> showCreateRoomSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => const _CreateRoomSheet(),
  );
}

class _CreateRoomSheet extends ConsumerStatefulWidget {
  const _CreateRoomSheet();
  @override
  ConsumerState<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends ConsumerState<_CreateRoomSheet> {
  String _topicId = 'free';
  bool _public = true;
  bool _busy = false;

  /// The cap the server reports, never a constant here.
  ///
  /// This used to mirror the server's `MAX_PARTICIPANTS`, and the copies drifted
  /// the moment media moved to the SFU: the sheet kept offering rooms "for up
  /// to 8" while the server was already admitting 50. A number that lives in
  /// two places has to be changed in two places, and nothing fails when it is
  /// not. Soon it stops being one number at all — room size follows the
  /// subscription tier.
  int get _cap => ref.read(groupTopicsProvider).valueOrNull?.maxParticipants ?? 8;

  Future<void> _create() async {
    // The microphone, on this tap, before the room exists.
    //
    // LiveKit opens it after the room is joined, which is a callback rather
    // than a gesture — and a gesture is what a permission prompt needs. Asked
    // here, the host arrives able to talk; asked there, they arrive muted and
    // the room they just opened has nobody speaking in it.
    if (!await ensureMicrophoneReady(context, ref)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final name =
          (ref.read(authControllerProvider).user?.fullName ?? '').trim();
      final room = await ref.read(groupApiProvider).createRoom(
        topicId: _topicId,
        isPublic: _public,
        maxParticipants: _cap,
        name: name.isEmpty ? 'Host' : name,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(groupLobbyProvider);
      context.push('/speaking/group/call/${room.code}',
          extra: groupEnteredByTap);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        if (e is ApiException) {
          showApiError(context, e);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).groupCreateFailed)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final topics = ref.watch(groupTopicsProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg,
            AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill))),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(l.groupNewRoom,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: AppSpace.lg),

            _Label(l.groupTopicLabel),
            const SizedBox(height: AppSpace.sm),
            topics.when(
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox(height: 40),
              data: (cfg) => Wrap(
                spacing: 8, runSpacing: 8,
                children: [for (final t in cfg.topics) _topicChip(t)],
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            _Label(l.groupVisibilityLabel),
            const SizedBox(height: AppSpace.sm),
            Row(children: [
              _seg(l.groupPublicOption, Icons.public, _public,
                  () => setState(() => _public = true)),
              const SizedBox(width: AppSpace.sm),
              _seg(l.groupPrivateOption, Icons.lock, !_public,
                  () => setState(() => _public = false)),
            ]),
            const SizedBox(height: 6),
            Text(_public ? l.groupPublicHint : l.groupPrivateHint,
                style: const TextStyle(color: AppColors.inkFaint, fontSize: 12)),
            const SizedBox(height: AppSpace.lg),

            // No participant picker. Rooms always open at the ceiling; a lower
            // number could only ever turn someone away, and the person creating
            // the room has no way of knowing how many will come.
            //
            // Rendered from the loaded config, not `_cap`: while the request is
            // in flight there is no number to show, and a placeholder that is
            // silently wrong is worse than a blank line for one frame.
            topics.when(
              loading: () => const SizedBox(height: 16),
              error: (_, _) => const SizedBox(height: 16),
              data: (cfg) => Text(
                l.groupRoomHoldsUpTo(cfg.maxParticipants),
                style: const TextStyle(color: AppColors.inkFaint, fontSize: 12),
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.speaking,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                onPressed: _busy ? null : _create,
                child: _busy
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : Text(l.groupCreateAndStart,
                        style: const TextStyle(fontSize: 15.5,
                            fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicChip(GroupTopic t) {
    final sel = t.id == _topicId;
    return GestureDetector(
      onTap: () => setState(() => _topicId = t.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.speaking : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: sel ? AppColors.speaking : AppColors.line),
        ),
        child: Text(t.title,
            style: TextStyle(
              color: sel ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool sel, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.speaking.withValues(alpha: 0.12)
                  : AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: sel ? AppColors.speaking : AppColors.line,
                  width: sel ? 1.6 : 1),
            ),
            child: Column(children: [
              Icon(icon, size: 20,
                  color: sel ? AppColors.speaking : AppColors.inkSoft),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? AppColors.speaking : AppColors.inkSoft)),
            ]),
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800,
          color: AppColors.ink));
}
