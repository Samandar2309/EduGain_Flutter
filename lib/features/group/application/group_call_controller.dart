import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/api/token_storage.dart';
import '../../../core/providers.dart';
import '../data/group_models.dart';
import '../data/group_signaling.dart';

enum GroupPhase { connecting, live, ended, error }

/// One remote participant: their id, display name, whether their audio is
/// actually flowing, and whether they are talking right now.
///
/// No renderer any more. The mesh version allocated an `RTCVideoRenderer` per
/// member — a texture each — for audio that no screen ever displayed.
class GroupMember {
  GroupMember({required this.id, required this.name, this.avatar = ''});
  final String id;
  String name;

  /// Their Telegram photo, or empty. Empty is normal, not an error: a learner
  /// may simply have no picture, and the coloured initial stands in.
  String avatar;

  /// Present in the SFU room, not merely listed by our signaling socket.
  bool connected = false;

  /// Computed by the SFU, which already has every stream and can tell who is
  /// audible far more cheaply than fifty phones each measuring their own level.
  bool speaking = false;
}

/// One line of room chat.
///
/// Hearts are counted in memory and never stored anywhere: the room itself
/// stops existing three hours after it opened, so a reaction outliving the
/// conversation would have nothing to belong to.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.from,
    required this.name,
    required this.text,
    required this.at,
    required this.mine,
    this.replyTo = '',
  });
  final String id;
  final String from;
  final String name;
  final String text;
  final DateTime at;
  final bool mine;

  /// Id of the message this answers, or empty. Only the id travels — the quoted
  /// line is already on every client.
  final String replyTo;

  /// Emoji -> how many people sent it. Counted in memory and never stored: the
  /// room stops existing three hours after it opened.
  final Map<String, int> reactions = {};

  /// Which ones this device has already sent, so a second tap does nothing.
  final Set<String> mine_ = {};
}

class GroupCallState {
  const GroupCallState({
    this.phase = GroupPhase.connecting,
    this.selfId = '',
    this.hostId = '',
    this.topic,
    this.title = '',
    this.maxParticipants = 5,
    this.visibility = 'public',
    this.members = const [],
    this.muted = false,
    this.selfSpeaking = false,
    this.micBlocked = false,
    this.mutedByHost = false,
    this.messages = const [],
    this.startedAt,
    this.endReason,
    this.errorDetail,
  });

  final GroupPhase phase;
  final String selfId;
  final String hostId;
  final GroupTopic? topic;
  final String title;
  final int maxParticipants;
  final String visibility;
  final List<GroupMember> members;
  final bool muted;
  final bool selfSpeaking;

  /// In the room but unable to publish — almost always a refused microphone.
  /// Kept separate from [muted]: one is a choice, the other is not, and the UI
  /// has to offer a way out rather than a toggle that cannot work.
  final bool micBlocked;

  /// Muted by the host rather than by choice. Worth distinguishing: someone who
  /// finds themselves silent deserves to know it was not their own tap.
  final bool mutedByHost;

  final List<ChatMessage> messages;

  /// When the ROOM opened, not when this socket did — so the call timer reads
  /// the same for everyone and survives a reconnect.
  final DateTime? startedAt;

  final String? endReason;

  /// What actually went wrong, for the details toggle.
  ///
  /// The exception used to be discarded by a bare `catch (_)`, which left a
  /// failure to join the SFU indistinguishable from every other failure — and
  /// the server logs cannot help, because a client that never reaches the SFU
  /// leaves no trace on it. The only witness is the client.
  final String? errorDetail;

  bool get isHost => selfId.isNotEmpty && selfId == hostId;

  GroupCallState copyWith({
    GroupPhase? phase,
    String? selfId,
    String? hostId,
    GroupTopic? topic,
    String? title,
    int? maxParticipants,
    String? visibility,
    List<GroupMember>? members,
    bool? muted,
    bool? selfSpeaking,
    bool? micBlocked,
    bool? mutedByHost,
    List<ChatMessage>? messages,
    DateTime? startedAt,
    String? endReason,
    String? errorDetail,
  }) => GroupCallState(
    phase: phase ?? this.phase,
    selfId: selfId ?? this.selfId,
    hostId: hostId ?? this.hostId,
    topic: topic ?? this.topic,
    title: title ?? this.title,
    maxParticipants: maxParticipants ?? this.maxParticipants,
    visibility: visibility ?? this.visibility,
    members: members ?? this.members,
    muted: muted ?? this.muted,
    selfSpeaking: selfSpeaking ?? this.selfSpeaking,
    micBlocked: micBlocked ?? this.micBlocked,
    mutedByHost: mutedByHost ?? this.mutedByHost,
    messages: messages ?? this.messages,
    startedAt: startedAt ?? this.startedAt,
    endReason: endReason ?? this.endReason,
    errorDetail: errorDetail ?? this.errorDetail,
  );
}

/// Drives a group voice call through the LiveKit SFU.
///
/// This replaced a full mesh, where each phone held one peer connection per
/// other participant and published its audio once for each of them — cost that
/// grew with N² and capped rooms at eight. Here a phone publishes ONE track and
/// subscribes to the active speakers, so its bandwidth and CPU are flat whether
/// the room holds three people or fifty.
///
/// **Two channels, one authority.** Our WebSocket remains the room: it decides
/// who is admitted, who the host is, who was kicked, and it is the ONLY source
/// of the member list. LiveKit carries audio and reports who is connected and
/// who is talking, which only ever enriches a member the socket already told us
/// about. Letting both define membership would mean a participant could exist
/// according to one and not the other, with nothing to arbitrate.
class GroupCallController extends StateNotifier<GroupCallState> {
  GroupCallController(
    this._tokens,
    this._displayName,
    this.code,
    this._lang,
    this._avatar, {
    // Off only in a screenshot test, which pins a state directly and must not
    // open a socket or ask for a microphone. Named rather than a separate
    // constructor so there is exactly one place where the fields are set.
    @visibleForTesting bool autoStart = true,
  }) : super(const GroupCallState()) {
    if (autoStart) _start();
  }

  final TokenStorage _tokens;
  final String _displayName;
  final String _avatar;

  /// Your own picture. Exposed because the server's participant list excludes
  /// you by design — so the one face the screen builds itself was the one face
  /// with nothing to draw.
  String get selfAvatar => _avatar;
  final String code;

  /// App language, sent to the server so the room's topic card comes back in
  /// a language the learner can actually read.
  final String _lang;

  GroupSignaling? _signaling;
  StreamSubscription<Map<String, dynamic>>? _sub;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _roomEvents;
  bool _disposed = false;

  Future<void> _start() async {
    try {
      final token = await _tokens.readAccess();
      if (token == null) {
        _fail('no_token');
        return;
      }
      // The microphone is NOT opened here. Under the mesh it had to be, because
      // the local stream was needed before the first peer connection could be
      // built. LiveKit acquires it on `setMicrophoneEnabled`, after the room is
      // joined — so a learner who is going to be refused the room (full, banned)
      // never sees a permission prompt for a call they cannot enter.
      final sig = GroupSignaling.connect(
        token: token,
        name: _displayName,
        code: code,
        lang: _lang,
        avatar: _avatar,
      );
      _signaling = sig;
      _sub = sig.messages.listen(_onMessage, onError: (e) => _fail('socket', e));
    } catch (e) {
      _fail('socket', e);
    }
  }

  Future<void> _onMessage(Map<String, dynamic> msg) async {
    if (_disposed) return;
    switch (msg['type']) {
      case 'hello':
        state = state.copyWith(
          selfId: msg['self_id'] as String? ?? '',
          hostId: msg['host_id'] as String? ?? '',
          title: msg['title'] as String? ?? '',
          maxParticipants: (msg['max'] as num?)?.toInt() ?? 5,
          visibility: msg['visibility'] as String? ?? 'public',
          // The server sends how long the room has been open, not when it
          // opened, so this anchors that to OUR clock. Subtracting a server
          // timestamp from `DateTime.now()` instead would measure the drift
          // between the two machines, which is how the timer used to open at
          // nine seconds on a phone whose clock ran fast.
          startedAt: (msg['elapsed_s'] as num?) == null
              ? null
              : DateTime.now()
                  .subtract(Duration(seconds: (msg['elapsed_s'] as num).toInt())),
          topic: msg['topic'] is Map
              ? GroupTopic.fromJson(Map<String, dynamic>.from(msg['topic'] as Map))
              : null,
        );
        for (final p in (msg['participants'] as List? ?? const [])) {
          final m = Map<String, dynamic>.from(p as Map);
          _addMember(m['id'] as String, m['name'] as String? ?? 'Guest',
              m['avatar'] as String? ?? '');
        }
        await _joinMedia(msg['livekit']);
      case 'peer_joined':
        _addMember(msg['id'] as String? ?? '', msg['name'] as String? ?? 'Guest',
            msg['avatar'] as String? ?? '');
      case 'peer_left':
        _removeMember(msg['id'] as String? ?? '');
      case 'chat':
        final id = msg['id'] as String? ?? '';
        // Ignore an echo of a message already shown: the sender renders its own
        // line the moment it is typed, so a room that is slow would otherwise
        // show it twice.
        if (id.isNotEmpty && state.messages.any((m) => m.id == id)) return;
        state = state.copyWith(messages: [
          ...state.messages,
          ChatMessage(
            id: id,
            from: msg['from'] as String? ?? '',
            name: msg['name'] as String? ?? 'Guest',
            text: msg['text'] as String? ?? '',
            at: DateTime.fromMillisecondsSinceEpoch(
                ((msg['ts'] as num?)?.toInt() ?? 0) * 1000),
            mine: (msg['from'] as String? ?? '') == state.selfId,
            replyTo: msg['reply_to'] as String? ?? '',
          ),
        ]);
      case 'react':
        final id = msg['id'] as String? ?? '';
        final idx = state.messages.indexWhere((m) => m.id == id);
        if (idx == -1) return;
        final emoji = msg['emoji'] as String? ?? '❤';
        final m = state.messages[idx];
        m.reactions[emoji] = (m.reactions[emoji] ?? 0) + 1;
        if ((msg['from'] as String? ?? '') == state.selfId) m.mine_.add(emoji);
        state = state.copyWith(messages: [...state.messages]);
      case 'force_mute':
        // The host quietened us. Silently obeyed rather than asked about: a
        // prompt would leave the room noisy for as long as it went unanswered,
        // which is the whole thing the host was trying to stop.
        if (!state.muted) {
          state = state.copyWith(muted: true, mutedByHost: true);
          unawaited(
            _room?.localParticipant?.setMicrophoneEnabled(false) ?? Future.value(),
          );
        }
      case 'host_changed':
        state = state.copyWith(hostId: msg['id'] as String? ?? '');
      case 'kicked':
        _end('kicked');
    }
  }

  /// Join the SFU with the credentials the room handed us in `hello`.
  Future<void> _joinMedia(Object? payload) async {
    // Null means the server has no SFU configured. Failing loudly beats a live
    // room in which nobody can ever be heard and nothing says why.
    if (payload is! Map) {
      _fail('sfu_unavailable');
      return;
    }
    final creds = Map<String, dynamic>.from(payload);
    final url = creds['url'] as String? ?? '';
    final token = creds['token'] as String? ?? '';
    if (url.isEmpty || token.isEmpty) {
      _fail('sfu_unavailable');
      return;
    }

    try {
      final room = lk.Room(
        roomOptions: const lk.RoomOptions(
          // Audio only, so nothing here should ever consider a camera.
          adaptiveStream: false,
          // Stops publishing upstream while nobody is subscribed — on a fifty
          // seat room most people are silent listeners most of the time.
          dynacast: true,
          defaultAudioPublishOptions: lk.AudioPublishOptions(
            // DTX makes silence almost free on the wire, which is what a
            // language room mostly is: one person talking, the rest listening.
            dtx: true,
          ),
          defaultAudioCaptureOptions: lk.AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        ),
      );
      _room = room;

      // Subscribe BEFORE connecting: participants already in the room arrive as
      // events during connect, and a listener attached afterwards misses them.
      final events = room.createListener();
      _roomEvents = events;
      events
        ..on<lk.ParticipantConnectedEvent>(
          (e) => _setConnected(e.participant.identity, true),
        )
        ..on<lk.ParticipantDisconnectedEvent>(
          (e) => _setConnected(e.participant.identity, false),
        )
        ..on<lk.ActiveSpeakersChangedEvent>(_onSpeakers)
        // Only ends a call that had started. The listener has to be attached
        // before `connect()` so no participant event is missed, which means it
        // is also live DURING the connect — and a disconnect event seen then
        // would tear the room down while the join was still in flight, ending
        // the call before it ever began.
        ..on<lk.RoomDisconnectedEvent>((e) {
          if (state.phase == GroupPhase.live) _end('disconnected');
        });

      await room.connect(url, token);
      if (_disposed) {
        await room.disconnect();
        return;
      }

      // Anyone already in the room when we arrived.
      for (final p in room.remoteParticipants.values) {
        _setConnected(p.identity, true);
      }
      // Live as soon as the room is joined, BEFORE the microphone. Being in the
      // room and being able to talk are different things, and treating them as
      // one meant a refused permission prompt killed a call the learner could
      // otherwise have listened to.
      state = state.copyWith(phase: GroupPhase.live);

      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        // Stay in the room, muted, and say so. On a phone this is usually a
        // denied permission — recoverable by the learner, and no reason to
        // throw them out of a conversation they can still follow.
        if (_disposed) return;
        state = state.copyWith(muted: true, micBlocked: true, errorDetail: 'mic: $e');
        _report('mic_blocked', e);
      }
    } catch (e) {
      // The exception is KEPT. A bare `catch (_)` here hid the one thing worth
      // knowing: a client that fails before reaching the SFU leaves no trace in
      // any server log, so this object is the only witness to why.
      _fail('mic_or_sfu', e);
    }
  }

  void _onSpeakers(lk.ActiveSpeakersChangedEvent e) {
    if (_disposed) return;
    final talking = e.speakers.map((p) => p.identity).toSet();
    var changed = false;
    for (final m in state.members) {
      final now = talking.contains(m.id);
      if (m.speaking != now) {
        m.speaking = now;
        changed = true;
      }
    }
    final selfNow = talking.contains(state.selfId);
    if (changed || selfNow != state.selfSpeaking) {
      state = state.copyWith(
        members: [...state.members],
        selfSpeaking: selfNow,
      );
    }
  }

  void _setConnected(String id, bool connected) {
    if (_disposed) return;
    final idx = _memberIndex(id);
    if (idx == -1 || state.members[idx].connected == connected) return;
    state.members[idx].connected = connected;
    if (!connected) state.members[idx].speaking = false;
    state = state.copyWith(members: [...state.members]);
  }

  void _addMember(String id, String name, [String avatar = '']) {
    if (id.isEmpty || _memberIndex(id) != -1) return;
    final member = GroupMember(id: id, name: name, avatar: avatar);
    // Somebody the socket announced may already be publishing — the SFU knows
    // before our own event does when a room is filling quickly.
    member.connected =
        _room?.remoteParticipants.values.any((p) => p.identity == id) ?? false;
    state = state.copyWith(members: [...state.members, member]);
  }

  void _removeMember(String id) {
    final idx = _memberIndex(id);
    if (idx == -1) return;
    state = state.copyWith(members: [...state.members]..removeAt(idx));
  }

  int _memberIndex(String id) => state.members.indexWhere((m) => m.id == id);

  void toggleMute() {
    // Nothing to unmute if the browser never granted the microphone; a toggle
    // that silently does nothing is worse than one that does not move.
    if (state.micBlocked) return;
    final muted = !state.muted;
    // Unmuting clears "the host did this": the learner is not blocked, they
    // were asked to be quiet, and speaking again is their call.
    state = state.copyWith(muted: muted, mutedByHost: muted && state.mutedByHost);
    // Unawaited on purpose: the button must respond on the frame it was tapped.
    // The publish toggle is not instant on a slow connection, and a control
    // that waits for the network before it moves reads as a frozen app.
    unawaited(_room?.localParticipant?.setMicrophoneEnabled(!muted) ?? Future.value());
  }

  /// Send a chat line, and show it immediately.
  ///
  /// Rendered locally before the server confirms: on mobile data the round trip
  /// is long enough that waiting for it makes typing feel broken. The echo is
  /// discarded by id when it comes back.
  void sendChat(String text, {String replyTo = ''}) {
    final t = text.trim();
    if (t.isEmpty) return;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${state.selfId}';
    _signaling?.send({
      'type': 'chat',
      'id': id,
      'text': t,
      if (replyTo.isNotEmpty) 'reply_to': replyTo,
    });
    state = state.copyWith(messages: [
      ...state.messages,
      ChatMessage(
        id: id,
        from: state.selfId,
        name: _displayName,
        text: t,
        at: DateTime.now(),
        mine: true,
        replyTo: replyTo,
      ),
    ]);
  }

  /// One emoji per person per message. A second tap of the same one does
  /// nothing rather than counting twice.
  void react(String messageId, String emoji) {
    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1 || state.messages[idx].mine_.contains(emoji)) return;
    _signaling?.send({'type': 'react', 'id': messageId, 'emoji': emoji});
  }

  // ── host controls ────────────────────────────────────────────────────────
  // All four ride the socket that is already open and store nothing new. The
  // server re-checks that the sender is the host on every one of them, so these
  // guards are for the UI's benefit, not for security.

  /// Remove a participant, and bar them for the room's lifetime.
  void kick(String memberId) {
    if (!state.isHost) return;
    _signaling?.send({'type': 'kick', 'target': memberId});
  }

  /// Quieten one participant.
  void muteMember(String memberId) {
    if (!state.isHost) return;
    _signaling?.send({'type': 'mute', 'target': memberId});
  }

  /// Quieten everyone but yourself — for when the room gets noisy.
  void muteAll() {
    if (!state.isHost) return;
    _signaling?.send({'type': 'mute_all'});
  }

  /// Hand the room over. The server confirms by broadcasting `host_changed`,
  /// so the local state is not guessed here — it follows the server.
  void makeHost(String memberId) {
    if (!state.isHost) return;
    _signaling?.send({'type': 'make_host', 'target': memberId});
  }

  void leave() {
    _signaling?.send({'type': 'leave'});
    _end('you_left');
  }

  /// Tell the server what went wrong, over the socket that is still open.
  ///
  /// A client that fails on the way to the media server leaves NO trace
  /// anywhere else: the SFU never saw it, and our own logs show only a socket
  /// that opened and closed. This is the one moment the cause exists at all.
  void _report(String reason, Object? error) {
    final detail = error == null ? reason : '$reason: $error';
    try {
      _signaling?.send({
        'type': 'client_error',
        'reason': reason,
        'detail': detail.length > 400 ? detail.substring(0, 400) : detail,
      });
    } catch (_) {
      // Reporting must never be the thing that breaks the path it reports on.
    }
  }

  void _fail(String reason, [Object? error]) {
    if (_disposed) return;
    _report(reason, error);
    state = state.copyWith(
      phase: GroupPhase.error,
      endReason: reason,
      errorDetail: error == null ? reason : '$reason: $error',
    );
    unawaited(_teardown());
  }

  void _end(String reason) {
    if (_disposed) return;
    state = state.copyWith(phase: GroupPhase.ended, endReason: reason);
    unawaited(_teardown());
  }

  Future<void> _teardown() async {
    await _sub?.cancel();
    _sub = null;
    await _signaling?.close();
    _signaling = null;
    await _roomEvents?.dispose();
    _roomEvents = null;
    final room = _room;
    _room = null;
    if (room != null) {
      // disconnect() stops the mic and closes the transport; dispose() frees the
      // native/JS objects behind it. Skipping the second leaks an audio context
      // per call, which a learner only notices after several rooms.
      await room.disconnect();
      await room.dispose();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_teardown());
    super.dispose();
  }
}

/// One controller per room code (the screen passes the code as the family arg).
final groupCallControllerProvider = StateNotifierProvider.autoDispose
    .family<GroupCallController, GroupCallState, String>((ref, code) {
      final user = ref.read(authControllerProvider).user;
      final name = (user?.fullName ?? '').trim();
      return GroupCallController(
        ref.read(tokenStorageProvider),
        name.isEmpty ? 'Guest' : name,
        code,
        ref.read(languageCodeProvider),
        user?.avatarUrl ?? '',
      );
    });
