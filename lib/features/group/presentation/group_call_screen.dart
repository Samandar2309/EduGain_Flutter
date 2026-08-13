import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/share.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/user_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../application/group_call_controller.dart';

/// Proof that a room was entered from a tap which opened the microphone.
///
/// Passed as the route's `extra`, because a URL cannot carry one. That is the
/// whole test: a page opened from a notification has no user gesture to spend
/// on a permission prompt, so LiveKit's `setMicrophoneEnabled` is refused —
/// silently, on WebKit — and the learner sits in a room able to hear everyone
/// and speak to nobody. The router turns such an arrival into the lobby, where
/// the join button is a real tap.
const groupEnteredByTap = true;

/// Share the room code so friends can join (Telegram share + copy).
Future<void> showInviteSheet(BuildContext context, WidgetRef ref, String code) {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  Future<void> share() async {
    final text = l.groupInviteShareText(code);
    final outcome = await shareInvite(
      text,
      prepare: () => prepareInvite(ref.read(apiClientProvider), text: text),
    );
    if (outcome == ShareOutcome.copied) {
      messenger.showSnackBar(SnackBar(content: Text(l.inviteCopied)));
    }
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.groupInviteFriends,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: AppSpace.md),
            // The code itself copies. A big number on a screen is the thing a
            // thumb reaches for; making it inert and putting the action in a
            // button underneath asks people to look twice.
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                messenger.showSnackBar(
                    SnackBar(content: Text(l.groupCodeCopied)));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(children: [
                  Text(code,
                      style: const TextStyle(fontSize: 30, letterSpacing: 6,
                          fontWeight: FontWeight.w900, color: AppColors.speaking)),
                  const SizedBox(height: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.copy, size: 12, color: AppColors.inkFaint),
                    const SizedBox(width: 4),
                    Text(l.groupCopyCode,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.inkFaint)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.speaking,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(l.groupShareTelegram,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              onPressed: () {
                // Close first: inside Telegram the native chat picker draws
                // over the app, and a sheet left underneath it is confusing.
                Navigator.pop(ctx);
                share();
              },
            ),
            const SizedBox(height: AppSpace.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              icon: const Icon(Icons.copy, color: AppColors.speaking),
              label: Text(l.groupCopyCode,
                  style: const TextStyle(color: AppColors.speaking, fontWeight: FontWeight.w700)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.groupCodeCopied)));
              },
            ),
          ],
        ),
      ),
    ),
  );
}


/// The room's own palette — deliberately local and deliberately dark.
abstract final class _Room {
  static const bg = Color(0xFF0B0818);
  static const voidDeep = Color(0xFF070512);
  static const surface = Color(0xFF15102B);
  static const raised = Color(0xFF1D1740);
  static const line = Color(0xFF272052);
  static const ink = Color(0xFFF4F1FF);
  static const soft = Color(0xFFA79EC9);
  static const faint = Color(0xFF6E6590);
  static const brand = Color(0xFF7C5CFF);
  static const brand2 = Color(0xFF9F7BFF);
  static const live = Color(0xFF34D399);
  static const leave = Color(0xFFF43F5E);
  static const gold = Color(0xFFFBBF24);
}

/// A stable colour per participant, from the id and not the list position —
/// which changes whenever somebody leaves.
Color _hueFor(String id) {
  const palette = [
    Color(0xFF6D5BD0), Color(0xFFC2708F), Color(0xFF4F7BC4), Color(0xFF3F9A80),
    Color(0xFFC98F4F), Color(0xFF8E5BD0), Color(0xFF4F9AC4), Color(0xFFD06B8E),
  ];
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7FFFFFFF;
  }
  return palette[h % palette.length];
}

String _initial(String name) {
  final t = name.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

/// How long the room has been open, as `HH:MM:SS`.
///
/// Elapsed only — never a countdown. A room has no end: putting a shrinking
/// number on screen would tell people to hurry, and hurrying is the opposite of
/// what somebody practising a language needs.
String _clock(Duration d) =>
    '${d.inHours.toString().padLeft(2, '0')}:'
    '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
    '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

/// The live group voice room.
///
/// Open microphone: anybody may speak at any time — no queue, no hand to raise,
/// no permission to ask for. Chat sits alongside the voice for the words a
/// learner cannot yet say out loud.
class GroupCallScreen extends ConsumerStatefulWidget {
  const GroupCallScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends ConsumerState<GroupCallScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// The message being answered, if any.
  ChatMessage? _replyTo;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = groupCallControllerProvider(widget.code);
    final state = ref.watch(ctrl);
    final notifier = ref.read(ctrl.notifier);

    ref.listen(ctrl, (prev, next) {
      if (next.mutedByHost && !(prev?.mutedByHost ?? false)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.groupMutedByHost)));
      }
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        // Follow the conversation. Scheduled after the frame so the new line
        // has been laid out and the extent to scroll to actually exists.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(_scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut);
          }
        });
      }
      if (next.phase == GroupPhase.ended || next.phase == GroupPhase.error) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          // Every failure says something. This used to list the reason codes it
          // knew and fall through to null for anything else — so when the move
          // to the SFU renamed them, the screen popped back in silence.
          final msg = switch (next.endReason) {
            'kicked' => l.groupKickedMsg,
            'you_left' => null,
            _ => l.groupConnectErrorMsg,
          };
          if (msg != null) {
            final detail = next.errorDetail;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 6),
              action: detail == null
                  ? null
                  : SnackBarAction(
                      label: l.details,
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(l.details),
                          content: SelectableText(detail),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l.close),
                            ),
                          ],
                        ),
                      ),
                    ),
            ));
          }
        }
      }
    });

    if (state.phase == GroupPhase.connecting) {
      return const Scaffold(
        backgroundColor: _Room.bg,
        body: Center(child: CircularProgressIndicator(color: _Room.brand)),
      );
    }

    final total = state.members.length + 1;

    return Scaffold(
      backgroundColor: _Room.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: l.groupChatTitle,
              onInvite: () => showInviteSheet(context, ref, widget.code),
            ),
            // The room above, fixed. Only the chat scrolls.
            //
            // Everything used to sit in ONE list, so each new message made the
            // page taller and pushed the seats off the top — the opposite of a
            // messenger, where the room stays put and the conversation moves
            // through it.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.md, AppSpace.sm, AppSpace.md, 0),
              child: Column(
                children: [
                  _RoomCard(
                    // The topic on top, the code underneath.
                    //
                    // They were the other way round, and the code was winning
                    // an argument it should not have been in: "BUART9" is an
                    // address, not a name. What a room IS — the thing someone
                    // decides to stay in or leave — is what it is about. The
                    // code still has to be here, because it is what you read
                    // out to a friend, but it belongs in the small line.
                    title: state.topic?.title.isNotEmpty == true
                        ? state.topic!.title
                        : (state.title.isEmpty ? widget.code : state.title),
                    // Blank when the line above already IS the code, so it is
                    // never printed twice.
                    subtitle: state.topic?.title.isNotEmpty == true ||
                            state.title.isNotEmpty
                        ? widget.code
                        : '',
                    level: '',
                    count: total,
                    max: state.maxParticipants,
                    startedAt: state.startedAt,
                    onLeave: notifier.leave,
                  ),
                  const SizedBox(height: AppSpace.md),
                  _SeatGrid(
                    state: state,
                    youLabel: l.groupYou,
                    selfAvatar: notifier.selfAvatar,
                    othersLabel: l.groupOthers,
                    onTapMember: state.isHost
                        ? (m) => _showHostSheet(context, l, notifier, m)
                        : null,
                    onInvite: () => showInviteSheet(context, ref, widget.code),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
            Expanded(
              child: _ChatList(
                controller: _scroll,
                messages: state.messages,
                onReact: notifier.react,
                onReply: (m) => setState(() => _replyTo = m),
                emptyLabel: l.groupChatEmpty,
                avatarFor: (id) => id == state.selfId
                    ? notifier.selfAvatar
                    : state.members
                              .where((m) => m.id == id)
                              .firstOrNull
                              ?.avatar ??
                          '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_replyTo != null)
                  _ReplyStrip(
                    m: _replyTo!,
                    onCancel: () => setState(() => _replyTo = null),
                  ),
                _Composer(
                  controller: _input,
                  hint: l.groupWriteMessage,
                  onSend: () {
                    notifier.sendChat(_input.text,
                        replyTo: _replyTo?.id ?? '');
                    _input.clear();
                    setState(() => _replyTo = null);
                  },
                ),
              ]),
            ),
            _MicBar(
              muted: state.muted,
              micBlocked: state.micBlocked,
              isHost: state.isHost,
              onToggle: notifier.toggleMute,
              onMuteEveryone: notifier.muteAll,
            ),
          ],
        ),
      ),
    );
  }

  void _showHostSheet(BuildContext context, AppLocalizations l,
      GroupCallController notifier, GroupMember m) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Room.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _Room.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(children: [
                _Avatar(id: m.id, name: m.name, avatar: m.avatar, size: 42),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _Room.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: AppSpace.md),
              _HostAction(
                icon: Icons.mic_off,
                label: l.groupMuteMember,
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.muteMember(m.id);
                },
              ),
              _HostAction(
                icon: Icons.star,
                label: l.groupMakeHost,
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.makeHost(m.id);
                },
              ),
              // Last, and the only one in red: removing somebody cannot be
              // undone for the room's lifetime, so it must not sit under a
              // thumb that was reaching for "mute".
              _HostAction(
                icon: Icons.block,
                label: l.groupRemove,
                danger: true,
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.kick(m.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onInvite});
  final String title;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AppSpace.md, bottom: AppSpace.xs),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _Room.ink),
            // `maybePop` alone did nothing when a notification opened this
            // room directly: the arrow was on screen and dead, and the only
            // way out was to close the Mini App. Home is where it would have
            // led anyway.
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Text(title,
              style: const TextStyle(
                  color: _Room.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const SizedBox(width: 6),
          const Icon(Icons.info_outline, size: 17, color: _Room.faint),
          const Spacer(),
          // Also here, not only on an empty seat: a full room still wants to
          // grow, and by then there is no empty seat left to tap.
          TextButton.icon(
            onPressed: onInvite,
            icon: const Icon(Icons.person_add, size: 16, color: _Room.brand2),
            label: Text(AppLocalizations.of(context).groupInvite,
                style: const TextStyle(
                    color: _Room.brand2,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _RoomCard extends StatefulWidget {
  const _RoomCard({
    required this.title,
    required this.subtitle,
    required this.level,
    required this.count,
    required this.max,
    required this.startedAt,
    required this.onLeave,
  });
  final String title;
  final String subtitle;
  final String level;
  final int count;
  final int max;
  final DateTime? startedAt;
  final VoidCallback onLeave;

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // One second is the coarsest tick a clock can have and still look like a
    // clock; anything finer would repaint for nothing.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final started = widget.startedAt;
    final elapsed =
        started == null ? Duration.zero : DateTime.now().difference(started);
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm + 2),
      decoration: BoxDecoration(
        color: _Room.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _Room.line),
      ),
      // One row, not two. Stacked, this card ate a fifth of the screen before
      // a single face appeared — on a phone the room itself is the content and
      // its label is not.
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_Room.brand, _Room.brand2]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _Room.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2)),
              const SizedBox(height: 1),
              Row(children: [
                if (widget.subtitle.isNotEmpty)
                  Flexible(
                    child: Text(widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Letter-spaced and tabular: this line is a code now,
                        // and a code is read one character at a time — out
                        // loud, to a friend, over a bad connection.
                        style: const TextStyle(
                          color: _Room.soft,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ),
                const SizedBox(width: 6),
                const Icon(Icons.people, size: 11, color: _Room.faint),
                const SizedBox(width: 3),
                Text('${widget.count}/${widget.max}',
                    style: const TextStyle(
                        color: _Room.faint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        // The clock keeps its own column so the digits do not shift the row as
        // they tick; tabular figures do the rest.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_clock(elapsed),
                style: const TextStyle(
                  color: _Room.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
            Text(l.groupCallTime,
                style: const TextStyle(color: _Room.faint, fontSize: 9)),
          ],
        ),
        const SizedBox(width: AppSpace.sm),
        // A door with an arrow leaving it, not a hung-up telephone. Ending a
        // call and leaving a room are different acts: the room carries on
        // without you, and the handset says otherwise.
        GestureDetector(
          onTap: widget.onLeave,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _Room.leave.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Room.leave.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.logout, size: 18, color: _Room.leave),
          ),
        ),
      ]),
    );
  }
}





class _ChatLine extends StatelessWidget {
  const _ChatLine({
    required this.m,
    required this.onReact,
    required this.onReply,
    this.avatar = '',
    this.quoted,
  });
  final ChatMessage m;

  /// The writer's picture, or empty for the coloured initial.
  final String avatar;
  final void Function(String id, String emoji) onReact;
  final void Function(ChatMessage m) onReply;

  /// The message this one answers, if it is still on screen.
  final ChatMessage? quoted;

  static const _palette = ['❤', '👏', '😂', '🔥', '👍', '🤔'];

  void _pick(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Room.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(
              spacing: AppSpace.md,
              children: [
                for (final e in _palette)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact(m.id, e);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
            const Divider(color: _Room.line, height: AppSpace.xl),
            _HostAction(
              icon: Icons.reply,
              label: AppLocalizations.of(context).groupReply,
              onTap: () {
                Navigator.pop(ctx);
                onReply(m);
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(m.at).format(context);
    final body = Column(
      crossAxisAlignment:
          m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (quoted != null) _Quote(m: quoted!, onMine: m.mine),
        Text(m.text,
            style: TextStyle(
                color: m.mine ? Colors.white : _Room.ink,
                fontSize: 13.5,
                height: 1.35)),
        if (m.reactions.isNotEmpty) ...[
          const SizedBox(height: 5),
          Wrap(
            spacing: 4,
            children: [
              for (final e in m.reactions.entries)
                // Tappable: joining a reaction somebody else already left is
                // the commonest thing anyone wants to do with one, and making
                // people hunt through a picker for an emoji already on screen
                // is a strange thing to ask.
                GestureDetector(
                  onTap: () => onReact(m.id, e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: m.mine
                          ? Colors.white.withValues(alpha: 0.18)
                          : _Room.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      // Your own reaction is outlined, so a room can see at a
                      // glance which ones it has already joined.
                      border: m.mine_.contains(e.key)
                          ? Border.all(color: _Room.brand2, width: 1)
                          : null,
                    ),
                    child: Text(
                      '${e.key} ${e.value}',
                      style: TextStyle(
                          color: m.mine ? Colors.white : _Room.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    // Three ways in, deliberately. The long press alone was the whole feature
    // for a while and nobody found it — a gesture with nothing on screen to
    // suggest it may as well not exist. So: one tap on the heart for the
    // reaction people actually want, one tap on an existing chip to join it,
    // and the long press for everything else. The heart is small and dim
    // enough that a chat still reads as words rather than as a row of buttons.
    return GestureDetector(
      onLongPress: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.md),
        child: m.mine
            ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _QuickLike(liked: m.mine_.contains('❤'),
                    onTap: () => onReact(m.id, '❤')),
                const SizedBox(width: 2),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(13, 8, 13, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF6D4BE8), _Room.brand]),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(m.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            Text(time,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10.5)),
                          ]),
                          const SizedBox(height: 3),
                          body,
                        ]),
                  ),
                ),
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Avatar(id: m.from, name: m.name, avatar: avatar, size: 34),
                const SizedBox(width: AppSpace.sm),
                Flexible(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(m.name,
                              style: TextStyle(
                                  color: _hueFor(m.from),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                          Text(time,
                              style: const TextStyle(
                                  color: _Room.faint, fontSize: 10.5)),
                        ]),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          decoration: const BoxDecoration(
                            color: _Room.raised,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: body,
                        ),
                      ]),
                ),
                const SizedBox(width: 2),
                // Nudged down so it sits against the bubble rather than the
                // name line above it.
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _QuickLike(liked: m.mine_.contains('❤'),
                      onTap: () => onReact(m.id, '❤')),
                ),
              ]),
      ),
    );
  }
}

/// One tap to like a message; the heart fills once you have.
class _QuickLike extends StatelessWidget {
  const _QuickLike({required this.liked, required this.onTap});
  final bool liked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Padding rather than a bigger icon: the touch target has to clear 40
        // logical pixels for a thumb, while the mark itself stays quiet.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 15,
            color: liked ? _Room.leave : _Room.faint,
          ),
        ),
      );
}

/// The quoted line above a reply.
class _Quote extends StatelessWidget {
  const _Quote({required this.m, required this.onMine});
  final ChatMessage m;
  final bool onMine;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.only(left: 7),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: onMine ? Colors.white70 : _Room.brand2,
              width: 2,
            ),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.name,
              style: TextStyle(
                  color: onMine ? Colors.white : _Room.brand2,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800)),
          Text(m.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: onMine ? Colors.white70 : _Room.soft, fontSize: 11)),
        ]),
      );
}

/// The bar above the composer while you are answering something.
class _ReplyStrip extends StatelessWidget {
  const _ReplyStrip({required this.m, required this.onCancel});
  final ChatMessage m;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: _Room.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _Room.line),
        ),
        child: Row(children: [
          Container(width: 2, height: 26, color: _Room.brand2),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.name,
                      style: const TextStyle(
                          color: _Room.brand2,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                  Text(m.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: _Room.soft, fontSize: 11.5)),
                ]),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: _Room.faint),
            onPressed: onCancel,
          ),
        ]),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hint,
    required this.onSend,
  });
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 2, 4, 2),
        decoration: BoxDecoration(
          color: _Room.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: _Room.line),
        ),
        child: Row(children: [
          Expanded(
            // The text was invisible while being typed and appeared only once
            // sent. Flutter web puts a real DOM input under the canvas to drive
            // the IME, and inside a WebView that element inherits the platform's
            // own light styling — so light-on-light text vanished mid-sentence.
            //
            // Fixed by forcing this subtree to a DARK brightness, which is what
            // the editable actually reads when it decides its own colours, and
            // by naming every colour that can be named rather than inheriting
            // any of them.
            child: Theme(
              data: Theme.of(context).copyWith(
                brightness: Brightness.dark,
                textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: _Room.brand2,
                  selectionColor: Color(0x557C5CFF),
                  selectionHandleColor: _Room.brand2,
                ),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                cursorColor: _Room.brand2,
                keyboardAppearance: Brightness.dark,
                style: const TextStyle(
                  color: _Room.ink,
                  fontSize: 14,
                  // Named explicitly: an inherited decoration from a parent
                  // theme is exactly the kind of thing that goes wrong only on
                  // one platform.
                  decoration: TextDecoration.none,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: hint,
                  hintStyle: const TextStyle(color: _Room.faint, fontSize: 14),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSend,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_Room.brand, _Room.brand2]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 15, color: Colors.white),
            ),
          ),
        ]),
      );
}






class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.id,
    required this.name,
    required this.size,
    this.avatar = '',
    this.live = false,
    this.muted = false,
  });
  final String id;
  final String name;
  final double size;

  /// Telegram photo URL, or empty.
  final String avatar;
  final bool live;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final hue = _hueFor(id);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [hue, Color.lerp(hue, Colors.white, 0.32)!],
            ),
            boxShadow: live
                ? [
                    const BoxShadow(
                        color: _Room.live, blurRadius: 0, spreadRadius: 2),
                    BoxShadow(
                        color: _Room.live.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          // The initial is the BASE layer and the photo sits on top. A URL that
          // is slow, expired or blocked therefore degrades to a coloured letter
          // rather than to a hole — Telegram's photo links do expire.
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Text(_initial(name),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.36,
                          fontWeight: FontWeight.w800)),
                ),
                if (UserPhoto.resolve(avatar) != null)
                  Image.network(
                    UserPhoto.resolve(avatar)!,
                    fit: BoxFit.cover,
                    // No progress spinner: at this size it would be a smear,
                    // and the initial underneath is already a good answer.
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
        if (size >= 44)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted ? _Room.leave : _Room.live,
                border: Border.all(color: _Room.bg, width: 2),
              ),
              child: Icon(muted ? Icons.mic_off : Icons.mic,
                  size: 9, color: const Color(0xFF07160F)),
            ),
          ),
      ]),
    );
  }
}

/// The one control that matters: a big round microphone with a live waveform
/// either side of it, exactly as in the design.
///
/// It TOGGLES rather than being held down. Press-and-hold looks tidy on a
/// mockup, but on a phone it means a learner cannot put the device down, scroll
/// the chat, or gesture while they talk — and a slip of the thumb cuts them off
/// mid-sentence.
class _MicBar extends StatelessWidget {
  const _MicBar({
    required this.muted,
    required this.micBlocked,
    required this.isHost,
    required this.onToggle,
    required this.onMuteEveryone,
  });
  final bool muted;
  final bool micBlocked;
  final bool isHost;
  final VoidCallback onToggle;
  final VoidCallback onMuteEveryone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final open = !muted && !micBlocked;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 2, AppSpace.md, AppSpace.sm),
      decoration: const BoxDecoration(
        color: _Room.voidDeep,
        border: Border(top: BorderSide(color: _Room.line)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (isHost)
          TextButton.icon(
            onPressed: onMuteEveryone,
            icon: const Icon(Icons.notifications_off,
                size: 15, color: _Room.faint),
            label: Text(l.groupMuteEveryone,
                style: const TextStyle(
                    color: _Room.faint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        Row(children: [
          Expanded(child: _Wave(active: open, flip: false)),
          GestureDetector(
            onTap: micBlocked ? null : onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: open
                    ? const LinearGradient(colors: [_Room.brand, _Room.brand2])
                    : null,
                color: open
                    ? null
                    : micBlocked
                        ? _Room.raised
                        : _Room.leave.withValues(alpha: 0.15),
                border: open
                    ? null
                    : Border.all(
                        color: micBlocked
                            ? _Room.line
                            : _Room.leave.withValues(alpha: 0.4),
                        width: 1.5),
                boxShadow: open
                    ? [
                        BoxShadow(
                          color: _Room.brand.withValues(alpha: 0.5),
                          blurRadius: 26,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                open ? Icons.mic : Icons.mic_off,
                size: 22,
                color: micBlocked
                    ? _Room.faint
                    : open
                        ? Colors.white
                        : _Room.leave,
              ),
            ),
          ),
          Expanded(child: _Wave(active: open, flip: true)),
        ]),
        const SizedBox(height: 3),
        // Words under the button, because a bare microphone glyph reads as both
        // "you are live" and "tap to go live" — and being wrong about which
        // costs the learner their privacy.
        Text(
          micBlocked
              ? l.groupMicBlocked
              : open
                  ? l.groupMuteMic
                  : l.groupSpeakNow,
          style: TextStyle(
            color: micBlocked
                ? _Room.faint
                : open
                    ? _Room.ink
                    : _Room.leave,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

/// The bars either side of the microphone.
///
/// Still and dim when the microphone is closed: a waveform that keeps dancing
/// while nothing is being transmitted is a lie about the state of the room.
class _Wave extends StatefulWidget {
  const _Wave({required this.active, required this.flip});
  final bool active;
  final bool flip;

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _Wave old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox(
          height: 26,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisAlignment: widget.flip
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: List.generate(9, (i) {
                final k = widget.flip ? i : 8 - i;
                final phase = (_c.value + k * 0.12) % 1.0;
                final t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                // Taller towards the button, so the pair reads as one shape
                // rather than two stripes.
                final reach = 1 - (k / 10);
                final h = widget.active ? 4 + 18 * t * reach : 3 + 4 * reach;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 2.5,
                    height: h,
                    decoration: BoxDecoration(
                      color: widget.active
                          ? _Room.brand2.withValues(alpha: 0.75)
                          : _Room.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );
}

class _HostAction extends StatelessWidget {
  const _HostAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? _Room.leave : _Room.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: danger ? _Room.leave.withValues(alpha: 0.13) : _Room.raised,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 15, color: c),
          ),
          const SizedBox(width: AppSpace.md),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 14.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// The reaction chip that sits at the foot of a message bubble.
///

/// Everyone in the room, in one horizontal row.
///
/// This was a 2x4 grid of "seats" for a while. In a nearly empty room that drew
/// eight invitations and read as a broken screen rather than a spacious one, and
/// the space it took came straight out of the conversation. A row grows
/// sideways instead: three people or fifty, it is the same height.
class _SeatGrid extends StatelessWidget {
  const _SeatGrid({
    required this.state,
    required this.youLabel,
    required this.selfAvatar,
    required this.othersLabel,
    required this.onTapMember,
    required this.onInvite,
  });
  final GroupCallState state;
  final String youLabel;

  /// Your own picture. It arrives separately from every other face because the
  /// server's participant list leaves you out of it — so this seat, the only one
  /// the screen assembles by itself, was the only one drawn without a photo.
  final String selfAvatar;
  final String othersLabel;
  final void Function(GroupMember)? onTapMember;
  final VoidCallback onInvite;

  /// How many faces before the rest collapse into a count. Past this they stop
  /// being recognisable at 52pt and become texture.
  static const _visible = 7;

  @override
  Widget build(BuildContext context) {
    // Whoever is talking comes first, then the host, then the rest. A row is
    // read left to right, so the left of it should hold what matters now.
    final ordered = [...state.members]..sort((a, b) {
        if (a.speaking != b.speaking) return a.speaking ? -1 : 1;
        final ah = a.id == state.hostId ? 0 : 1;
        final bh = b.id == state.hostId ? 0 : 1;
        return ah != bh ? ah - bh : a.name.compareTo(b.name);
      });
    final shown = ordered.take(_visible).toList();
    final rest = ordered.length - shown.length;

    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _RowFace(
            id: state.selfId,
            name: youLabel,
            // Everybody else's picture came from the participant list; yours
            // was the one the screen assembles itself, and it was assembled
            // without one.
            avatar: selfAvatar,
            muted: state.muted,
            speaking: state.selfSpeaking && !state.muted,
            host: state.isHost,
          ),
          for (final m in shown)
            _RowFace(
              id: m.id,
              name: m.name,
              avatar: m.avatar,
              muted: !m.connected,
              speaking: m.speaking,
              host: m.id == state.hostId,
              onTap: onTapMember == null ? null : () => onTapMember!(m),
            ),
          if (rest > 0)
            _RowChip(
              label: othersLabel,
              child: Text('+$rest',
                  style: const TextStyle(
                      color: _Room.soft,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          _RowChip(
            label: AppLocalizations.of(context).groupInvite,
            onTap: onInvite,
            outlined: true,
            child: const Icon(Icons.person_add, size: 20, color: _Room.brand2),
          ),
        ],
      ),
    );
  }
}

class _RowFace extends StatelessWidget {
  const _RowFace({
    required this.id,
    required this.name,
    required this.muted,
    required this.speaking,
    required this.host,
    this.avatar = '',
    this.onTap,
  });
  final String id;
  final String name;
  final String avatar;
  final bool muted;
  final bool speaking;
  final bool host;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpace.md),
          child: SizedBox(
            width: 56,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _Avatar(
                  id: id,
                  name: name,
                  avatar: avatar,
                  size: 52,
                  live: speaking,
                  muted: muted),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (host)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.star, size: 10, color: _Room.gold),
                    ),
                  Flexible(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: host ? _Room.gold : _Room.soft,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ]),
          ),
        ),
      );
}

class _RowChip extends StatelessWidget {
  const _RowChip({
    required this.label,
    required this.child,
    this.onTap,
    this.outlined = false,
  });
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpace.md),
          child: SizedBox(
            width: 56,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: outlined ? Colors.transparent : _Room.raised,
                  border: outlined
                      ? Border.all(color: _Room.brand2.withValues(alpha: 0.5))
                      : null,
                ),
                child: child,
              ),
              const SizedBox(height: 5),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _Room.faint, fontSize: 10.5)),
            ]),
          ),
        ),
      );
}


/// The one control that matters: a big round microphone with a live waveform
/// either side of it, exactly as in the design.
///

/// The bars either side of the microphone.
///



/// The reaction chip that sits at the foot of a message bubble.
///

/// The room as a grid of seats, not a list of names.
///



/// The conversation, and the only part of the room that scrolls.
///
/// A list rather than a card: the card grew with its contents, so a busy room
/// pushed the seats and the microphone off the screen. Here the room stays where
/// it is and the messages move through a window of their own.
class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.controller,
    required this.messages,
    required this.onReact,
    required this.onReply,
    required this.emptyLabel,
    required this.avatarFor,
  });
  final ScrollController controller;
  final List<ChatMessage> messages;
  final void Function(String id, String emoji) onReact;
  final void Function(ChatMessage m) onReply;
  final String emptyLabel;

  /// A writer's picture, by their id. Resolved here rather than stored on the
  /// message: somebody who changes their photo mid-conversation should not
  /// leave a trail of stale faces up the chat.
  final String Function(String id) avatarFor;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Text(emptyLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Room.faint, fontSize: 12.5)),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
      itemCount: messages.length,
      // Built lazily: a room that has been talking for an hour holds hundreds
      // of lines, and laying all of them out to show the last five is work
      // nobody sees.
      itemBuilder: (context, i) => _ChatLine(
        m: messages[i],
        avatar: avatarFor(messages[i].from),
        onReact: onReact,
        onReply: onReply,
        quoted: messages[i].replyTo.isEmpty
            ? null
            : messages.where((x) => x.id == messages[i].replyTo).firstOrNull,
      ),
    );
  }
}
