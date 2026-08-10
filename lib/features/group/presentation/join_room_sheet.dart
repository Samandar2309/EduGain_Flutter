import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/group_providers.dart';
import '../data/group_models.dart';

/// A pre-join preview: fetch the room by code, show its topic / host / how full
/// it is, and only THEN connect (turning on the mic). Used both by tapping a
/// lobby row and by "join by code" for private rooms.
Future<void> showJoinRoomSheet(
    BuildContext context, WidgetRef ref, String code) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _JoinRoomSheet(code: code.toUpperCase()),
  );
}

class _JoinRoomSheet extends ConsumerStatefulWidget {
  const _JoinRoomSheet({required this.code});
  final String code;
  @override
  ConsumerState<_JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends ConsumerState<_JoinRoomSheet> {
  GroupRoom? _room;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final room = await ref.read(groupApiProvider).preview(widget.code);
      if (mounted) setState(() { _room = room; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).groupRoomNotFound;
          _loading = false;
        });
      }
    }
  }

  void _join() {
    Navigator.of(context).pop();
    context.push('/speaking/group/call/${widget.code}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg,
            AppSpace.lg + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill)))),
            const SizedBox(height: AppSpace.lg),
            if (_loading)
              const Padding(padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 15)))
            else ...[
              Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent(AppColors.speaking),
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: const Icon(Icons.groups, color: Colors.white)),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_room!.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text('${_room!.hostName} · ${_room!.count}/${_room!.max}',
                        style: const TextStyle(color: AppColors.inkSoft,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ])),
                Icon(_room!.isPublic ? Icons.public : Icons.lock,
                    size: 18, color: AppColors.inkFaint),
              ]),
              if (_room!.topic.prompt.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text(_room!.topic.prompt,
                      style: const TextStyle(color: AppColors.inkSoft,
                          fontSize: 13.5, height: 1.35))),
              ],
              const SizedBox(height: AppSpace.lg),
              SizedBox(height: 52, child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.speaking,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md))),
                onPressed: _room!.isFull ? null : _join,
                child: Text(_room!.isFull ? l.groupFull : l.groupJoin,
                    style: const TextStyle(fontSize: 15.5,
                        fontWeight: FontWeight.w800, color: Colors.white)))),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small dialog to type a room code (for private / shared rooms).
Future<void> showJoinByCodeDialog(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l.groupJoinByCode),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        maxLength: 6,
        decoration: InputDecoration(
          hintText: l.groupCodeHint,
          counterText: '',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.speaking),
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(l.groupJoin),
        ),
      ],
    ),
  );
  if (code != null && code.length >= 4 && context.mounted) {
    await showJoinRoomSheet(context, ref, code);
  }
}
