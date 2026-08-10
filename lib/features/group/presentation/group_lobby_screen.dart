import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/group_providers.dart';
import '../data/group_models.dart';
import 'create_room_sheet.dart';
import 'join_room_sheet.dart';

/// The group-speaking lobby: the live PUBLIC rooms anyone can join, refreshed
/// on a light timer so filling/closing rooms stay current, plus a big button
/// to open a new room.
class GroupLobbyScreen extends ConsumerStatefulWidget {
  const GroupLobbyScreen({super.key});

  @override
  ConsumerState<GroupLobbyScreen> createState() => _GroupLobbyScreenState();
}

class _GroupLobbyScreenState extends ConsumerState<GroupLobbyScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) ref.invalidate(groupLobbyProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rooms = ref.watch(groupLobbyProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l.groupChatTitle),
        backgroundColor: AppColors.canvas,
        actions: [
          IconButton(
            icon: const Icon(Icons.dialpad),
            tooltip: l.groupJoinByCode,
            onPressed: () => showJoinByCodeDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.speaking,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l.groupCreateRoom,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        onPressed: () => showCreateRoomSheet(context, ref),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(groupLobbyProvider),
        child: rooms.when(
          loading: () => const AppLoader(),
          error: (_, _) => ListView(children: [Center(child: Text(l.loadFailed))]),
          data: (list) => list.isEmpty
              ? _Empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, 96),
                  itemCount: list.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _RoomCard(room: list[i],
                      onJoin: () => showJoinRoomSheet(context, ref, list[i].code)),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(top: 120),
      children: [
        const Icon(Icons.groups, size: 64, color: AppColors.inkFaint),
        const SizedBox(height: AppSpace.md),
        Center(
          child: Text(l.groupEmptyTitle,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(l.groupEmptySubtitle,
              style: const TextStyle(color: AppColors.inkFaint, fontSize: 13)),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onJoin});
  final GroupRoom room;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final full = room.isFull;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: full ? null : onJoin,
          child: Opacity(
            opacity: full ? 0.55 : 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accent(AppColors.speaking),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadow.glow(AppColors.speaking),
                    ),
                    child: const Icon(Icons.groups,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15.5,
                              color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 13,
                                color: AppColors.speaking),
                            const SizedBox(width: 4),
                            Text('${room.hostName} · ${room.count}/${room.max}',
                                style: const TextStyle(
                                  color: AppColors.inkSoft, fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                            if (room.level.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _Chip(room.level),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  if (full)
                    Text(l.groupFull,
                        style: const TextStyle(color: AppColors.inkFaint,
                            fontSize: 12, fontWeight: FontWeight.w800))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent(AppColors.speaking),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadow.glow(AppColors.speaking),
                      ),
                      child: Text(l.groupJoin,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5,
                              fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.speaking.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(text,
        style: const TextStyle(color: AppColors.speaking, fontSize: 10.5,
            fontWeight: FontWeight.w800)),
  );
}
