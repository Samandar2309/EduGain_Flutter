import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../../core/api/token_storage.dart';
import '../../../core/media/microphone_service.dart';
import '../../../core/media/remote_audio_stub.dart'
    if (dart.library.js_interop) '../../../core/media/remote_audio_web.dart';
import '../../../core/live_data.dart';
import '../../../core/providers.dart';
import '../data/peer_api.dart';
import '../data/ice_repository.dart';
import '../data/peer_models.dart';
import '../data/peer_signaling.dart';

/// How the call was launched: find a random partner, open a friend room, or
/// join a friend's room by its 6-char code.
sealed class PeerLaunch {
  const PeerLaunch();

  static const match = PeerLaunchMatch();
  static const create = PeerLaunchCreate();
}

class PeerLaunchMatch extends PeerLaunch {
  const PeerLaunchMatch({this.pref = 'any'});

  /// Who to be matched with: `any`, `female` or `male`.
  ///
  /// Part of equality on purpose. This class is the provider family's key, so
  /// two searches with different filters have to be two different controllers
  /// — otherwise picking a filter, backing out and picking another would
  /// silently reuse the first search.
  final String pref;

  @override
  bool operator ==(Object other) =>
      other is PeerLaunchMatch && other.pref == pref;

  @override
  int get hashCode => pref.hashCode;
}

class PeerLaunchCreate extends PeerLaunch {
  const PeerLaunchCreate();

  @override
  bool operator ==(Object other) => other is PeerLaunchCreate;

  @override
  int get hashCode => 2;
}

class PeerLaunchJoin extends PeerLaunch {
  const PeerLaunchJoin(this.code);

  final String code;

  @override
  bool operator ==(Object other) => other is PeerLaunchJoin && other.code == code;

  @override
  int get hashCode => Object.hash(3, code);
}

enum PeerPhase {
  /// Opening the room / signaling socket.
  connecting,

  /// In the matchmaking queue, waiting to be paired.
  searching,

  /// In the room, waiting for the (invited) partner to arrive.
  waiting,

  /// Both online — WebRTC handshake in progress.
  rtcConnecting,

  /// Live audio flowing.
  inCall,

  /// Over (see [PeerCallState.endReason]).
  ended,
}

class PeerCallState {
  const PeerCallState({
    this.phase = PeerPhase.connecting,
    this.roomCode = '',
    this.role = '',
    this.topic,
    this.partnerName = '',
    this.partnerAvatar = '',
    this.muted = false,
    this.partnerOnline = false,
    this.micDenied = false,
    this.partnerMicOff = false,
    this.endReason,
  });

  final PeerPhase phase;
  final String roomCode;
  final String role; // 'host' | 'guest'
  final PeerTopic? topic;
  final String partnerName;

  /// The partner's picture, or empty. Empty is ordinary rather than an error:
  /// plenty of learners have none, and the coloured initial stands in.
  final String partnerAvatar;
  final bool muted;
  final bool partnerOnline;

  /// The microphone could not be opened, so this side is listening only.
  ///
  /// Not an error state: the call still connects and the partner is still
  /// audible. It is worth showing because otherwise somebody talks into a
  /// dead mic for two minutes and concludes the app is broken.
  final bool micDenied;

  /// The PARTNER cannot transmit. Told to us over the signalling relay.
  ///
  /// Worth its own flag because the alternative is the failure that was being
  /// reported: one side hears nothing, neither side is told why, and both
  /// conclude the call is broken. Silence with a reason is a different
  /// experience from silence.
  final bool partnerMicOff;

  final String? endReason;
  // 'partner_left' | 'you_ended' | 'failed' | 'peer_quota'

  PeerCallState copyWith({
    PeerPhase? phase,
    String? roomCode,
    String? role,
    PeerTopic? topic,
    String? partnerName,
    String? partnerAvatar,
    bool? muted,
    bool? partnerOnline,
    bool? micDenied,
    bool? partnerMicOff,
    String? endReason,
  }) => PeerCallState(
    phase: phase ?? this.phase,
    roomCode: roomCode ?? this.roomCode,
    role: role ?? this.role,
    topic: topic ?? this.topic,
    partnerName: partnerName ?? this.partnerName,
    partnerAvatar: partnerAvatar ?? this.partnerAvatar,
    muted: muted ?? this.muted,
    partnerOnline: partnerOnline ?? this.partnerOnline,
    micDenied: micDenied ?? this.micDenied,
    partnerMicOff: partnerMicOff ?? this.partnerMicOff,
    endReason: endReason ?? this.endReason,
  );
}

/// Drives one peer call end to end: matchmaking/room → signaling → WebRTC →
/// teardown. Convention (baked into the server's `hello`): the GUEST creates
/// the offer, the host answers.
/// WebSocket close code the server sends when today's live-conversation
/// minutes are gone. Mirrors `peer.py`; 4000-4999 is the range reserved for
/// application-defined codes.
const int _quotaExhausted = 4402;

class PeerCallController extends StateNotifier<PeerCallState> {
  PeerCallController(
    this._api,
    this._tokens,
    this._displayName,
    this._lang,
    this._avatar,
    this._iceRepo,
    this._mic,
  ) : super(const PeerCallState());

  final PeerApi _api;
  final IceRepository _iceRepo;

  /// Holds the microphone this call publishes. Opened before the call — from
  /// the learner's tap — and given back when the call ends.
  final MicrophoneService _mic;
  final TokenStorage _tokens;
  final String _displayName;
  /// App language, sent to the server so the role-play card comes back in a
  /// language the learner can actually read. Fixed for the call's lifetime —
  /// the controller is torn down with the screen.
  final String _lang;

  /// Our own picture, handed to the partner at the handshake. The server
  /// accepts only our own avatar routes — it is rendered as an image on
  /// somebody else's phone.
  final String _avatar;

  /// ICE servers for this call, resolved once and reused.
  ///
  /// A group call opens one peer connection per participant; asking the server
  /// for a fresh credential each time would be needless round-trips on the
  /// latency-sensitive path, and they would all be equivalent anyway.
  Map<String, dynamic>? _iceCache;

  Future<Map<String, dynamic>> _ice() async =>
      _iceCache ??= await _iceRepo.config();

  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  PeerSignaling? _signaling;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _offerStarted = false;
  bool _disposed = false;

  /// Remote ICE candidates that arrived too early to apply.
  ///
  /// Two windows make this necessary, and both are ordinary rather than
  /// exotic. The HOST has no peer connection at all until the offer lands, and
  /// the guest trickles candidates the moment it has a local description — so
  /// the first candidates routinely beat the offer down the same relay. And on
  /// BOTH sides `addCandidate` before a remote description is set is an error.
  ///
  /// They used to be dropped in silence (`_pc?.addCandidate` — null-safe, no
  /// buffer, no log). Losing the relay candidates that way is a call that
  /// negotiates fine and then never connects, which is exactly the failure
  /// nobody could explain.
  final List<RTCIceCandidate> _pendingRemoteIce = [];

  /// Whether a remote description has been applied, so buffered candidates may
  /// be flushed. Tracked here rather than read from `signalingState` because
  /// the flush has to happen exactly once, at a moment we choose.
  bool _remoteDescriptionSet = false;

  /// Serialises the signalling handler.
  ///
  /// `Stream.listen` does NOT await an async `onData`, so two messages could be
  /// in flight at once: an `ice` could run `addCandidate` while the `offer`
  /// handler was still suspended inside `setRemoteDescription`, and the throw
  /// that produced surfaced nowhere — `onError` only sees stream errors, not
  /// handler errors. Chaining every message onto one future makes the ordering
  /// the protocol already assumes actually true.
  Future<void> _queue = Future<void>.value();

  /// Fails a call that stops making progress instead of letting it hang.
  ///
  /// Nothing here used to time out. If the handshake stalled — a lost
  /// `peer_joined`, a dropped candidate, a relay that never answered — no state
  /// ever changed, `onConnectionState` never fired (ICE cannot fail before it
  /// starts), and the screen sat on "connecting" until the learner gave up.
  Timer? _watchdog;
  static const _connectTimeout = Duration(seconds: 12);
  static const _rtcTimeout = Duration(seconds: 25);


  Future<void> start(PeerLaunch launch) async {
    try {
      await remoteRenderer.initialize();
      var room = '';
      var mode = '';
      var matchPref = 'any';
      switch (launch) {
        case PeerLaunchMatch(pref: final chosen):
          mode = 'match';
          matchPref = chosen;
        case PeerLaunchCreate():
          final created = await _api.createRoom();
          room = created.code;
          state = state.copyWith(roomCode: room, topic: created.topic);
        case PeerLaunchJoin(:final code):
          room = code.trim().toUpperCase();
          state = state.copyWith(roomCode: room);
      }
      final token = await _tokens.readAccess();
      if (token == null) {
        _end('failed');
        return;
      }
      final signaling = PeerSignaling.connect(
        token: token,
        name: _displayName,
        avatar: _avatar,
        // Safe to take from the client: it only ever narrows the sender's own
        // results. The GENDER it is matched against is not — that is read
        // server-side from the account, or the filter would be defeated by
        // anyone who simply typed a different word.
        pref: matchPref,
        room: room,
        mode: mode,
        lang: _lang,
      );
      _signaling = signaling;
      _armWatchdog(_connectTimeout);
      _sub = signaling.messages.listen(
        // Chained, never called directly: see [_queue]. Every message runs to
        // completion before the next one starts.
        (msg) => _queue = _queue.then((_) => _onMessage(msg)).catchError((
          Object e,
        ) {
          // A malformed frame must not kill the pipeline for every frame after
          // it. Swallowed here so the chain survives; a genuinely fatal problem
          // still ends the call through the watchdog or the socket.
          if (kDebugMode) debugPrint('peer: message handler failed: $e');
        }),
        onError: (Object _) => _end('failed'),
        onDone: () {
          if (state.phase == PeerPhase.ended) return;
          // The server closes with a code when the reason is knowable; only a
          // genuinely unexplained drop is a "failure".
          _end(switch (signaling.closeCode) {
            _quotaExhausted => 'peer_quota',
            _ => 'failed',
          });
        },
      );
    } catch (_) {
      _end('failed');
    }
  }

  Future<void> _onMessage(Map<String, dynamic> msg) async {
    if (_disposed) return;
    switch (msg['type']) {
      case 'searching':
        state = state.copyWith(phase: PeerPhase.searching);
      case 'hello':
        state = state.copyWith(
          roomCode: msg['room'] as String? ?? state.roomCode,
          role: msg['role'] as String? ?? '',
          topic: msg['topic'] is Map
              ? PeerTopic.fromJson(Map<String, dynamic>.from(msg['topic'] as Map))
              : state.topic,
          partnerName: (msg['partner_name'] as String?)?.trim().isNotEmpty == true
              ? (msg['partner_name'] as String).trim()
              : state.partnerName,
          partnerAvatar:
              (msg['partner_avatar'] as String?)?.trim().isNotEmpty == true
              ? (msg['partner_avatar'] as String).trim()
              : state.partnerAvatar,
          partnerOnline: msg['peer_online'] == true,
          phase: msg['peer_online'] == true
              ? PeerPhase.rtcConnecting
              : PeerPhase.waiting,
        );
        if (state.partnerOnline) _armWatchdog(_rtcTimeout);
        if (state.role == 'guest' && state.partnerOnline) await _beginOffer();
      case 'peer_joined':
        state = state.copyWith(
          partnerOnline: true,
          partnerName: (msg['name'] as String?)?.trim().isNotEmpty == true
              ? (msg['name'] as String).trim()
              : state.partnerName,
          partnerAvatar: (msg['avatar'] as String?)?.trim().isNotEmpty == true
              ? (msg['avatar'] as String).trim()
              : state.partnerAvatar,
          phase: state.phase == PeerPhase.inCall
              ? PeerPhase.inCall
              : PeerPhase.rtcConnecting,
        );
        _armWatchdog(_rtcTimeout);
        if (state.role == 'guest') await _beginOffer();
      case 'offer':
        final pc = await _ensurePeerConnection();
        await pc.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String?, 'offer'),
        );
        await _onRemoteDescription();
        final answer = await pc.createAnswer({});
        await pc.setLocalDescription(answer);
        _signaling?.send({'type': 'answer', 'sdp': answer.sdp});
        _announceMicState();
      case 'answer':
        final pc = _pc;
        if (pc != null) {
          await pc.setRemoteDescription(
            RTCSessionDescription(msg['sdp'] as String?, 'answer'),
          );
          await _onRemoteDescription();
        }
      case 'ice':
        final c = msg['candidate'];
        if (c is! Map) break;
        final candidate = RTCIceCandidate(
          c['candidate'] as String?,
          c['sdpMid'] as String?,
          c['sdpMLineIndex'] as int?,
        );
        final pc = _pc;
        // Held rather than dropped. See [_pendingRemoteIce] — the host has no
        // peer connection until the offer arrives, and neither side may apply
        // a candidate before its remote description is in.
        if (pc == null || !_remoteDescriptionSet) {
          _pendingRemoteIce.add(candidate);
          break;
        }
        await _addCandidate(pc, candidate);
      // The partner is in the room but cannot transmit. Rare now that a search
      // will not start without a working microphone, but still reachable if
      // theirs dies mid-handshake — and without this the learner hears silence
      // and blames the app, which is exactly what was being reported.
      case 'mic_off':
        state = state.copyWith(partnerMicOff: true);
      case 'peer_left' || 'hangup':
        _end('partner_left');
    }
  }

  /// Apply everything that was waiting on a remote description.
  Future<void> _onRemoteDescription() async {
    _remoteDescriptionSet = true;
    final pc = _pc;
    if (pc == null) return;
    final pending = List<RTCIceCandidate>.from(_pendingRemoteIce);
    _pendingRemoteIce.clear();
    for (final candidate in pending) {
      await _addCandidate(pc, candidate);
    }
  }

  /// One bad candidate must never abort the rest — the others may still be the
  /// pair that connects.
  Future<void> _addCandidate(RTCPeerConnection pc, RTCIceCandidate c) async {
    try {
      await pc.addCandidate(c);
    } catch (e) {
      if (kDebugMode) debugPrint('peer: candidate rejected: $e');
    }
  }

  /// Tell the other side we cannot transmit, so their screen can say so.
  ///
  /// Rides the server's existing generic relay — any message carrying a `type`
  /// is forwarded to the peer — so this needs no server change at all.
  void _announceMicState() {
    if (state.micDenied) _signaling?.send({'type': 'mic_off'});
  }

  /// Fail loudly after [d] unless the call has moved on.
  void _armWatchdog(Duration d) {
    _watchdog?.cancel();
    if (_disposed) return;
    _watchdog = Timer(d, () {
      if (_disposed) return;
      // Searching is not stalling: the queue is genuinely unbounded, and a
      // learner waiting for somebody to come online must not be cut off.
      if (state.phase == PeerPhase.inCall ||
          state.phase == PeerPhase.ended ||
          state.phase == PeerPhase.searching ||
          state.phase == PeerPhase.waiting) {
        return;
      }
      _end('failed');
    });
  }

  Future<void> _beginOffer() async {
    if (_offerStarted) return;
    _offerStarted = true;
    final pc = await _ensurePeerConnection();
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    _signaling?.send({'type': 'offer', 'sdp': offer.sdp});
    _announceMicState();
  }

  Future<RTCPeerConnection> _ensurePeerConnection() async {
    final existing = _pc;
    if (existing != null) return existing;

    final pc = await createPeerConnection(await _ice());
    _pc = pc;

    // READ, never opened.
    //
    // The microphone was opened by the tap that started this call — the filter
    // sheet, the friend-room button, the join-by-code dialog, all of which go
    // through `ensureMicrophoneReady`. This method runs from a WebSocket frame
    // instead, arriving anywhere from a second to several minutes later, and a
    // browser will not show a permission dialog once the gesture that would
    // have justified it has expired. Asking here is what used to happen; on
    // iOS it was refused in silence and the call connected to a dead
    // microphone.
    //
    // So: whatever `MicrophoneService` is holding, or nothing.
    final stream = _mic.liveStream;
    _localStream = stream;
    if (stream != null) {
      for (final track in stream.getAudioTracks()) {
        await pc.addTrack(track, stream);
      }
    } else {
      // Only reachable when the microphone died between the tap and the
      // handshake — unplugged, revoked in settings, or claimed by an incoming
      // phone call. Rare, and not a reason to drop the call: this side can
      // still listen.
      //
      // The transceiver is not optional — with neither a track nor a
      // transceiver the offer carries no audio line, so nothing would arrive
      // in either direction and the call would connect to silence.
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      state = state.copyWith(micDenied: true, muted: true);
    }

    pc.onIceCandidate = (candidate) {
      _signaling?.send({
        'type': 'ice',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };
    pc.onConnectionState = (rtcState) {
      if (_disposed) return;
      switch (rtcState) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _watchdog?.cancel();
          state = state.copyWith(phase: PeerPhase.inCall);
          // Safari will not start an unmuted element that was handed a stream
          // outside a gesture. Harmless everywhere else — an element that is
          // already playing ignores a second `play()`.
          unlockRemoteAudio();
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _end('failed');
        default:
          break;
      }
    };
    return pc;
  }

  void toggleMute() {
    final stream = _localStream;
    if (stream == null) return;
    final muted = !state.muted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
    state = state.copyWith(muted: muted);
  }

  /// Ends the call — or, while still searching, cancels the search.
  void hangUp() {
    if (state.phase == PeerPhase.searching) {
      _signaling?.send({'type': 'cancel'});
      _end('you_ended');
      return;
    }
    _signaling?.send({'type': 'hangup'});
    _end('you_ended');
  }

  void _end(String reason) {
    if (_disposed || state.phase == PeerPhase.ended) return;
    state = state.copyWith(phase: PeerPhase.ended, endReason: reason);
    unawaited(_cleanup());
  }

  Future<void> _cleanup() async {
    _watchdog?.cancel();
    _watchdog = null;
    _pendingRemoteIce.clear();
    await _sub?.cancel();
    _sub = null;
    await _signaling?.close();
    _signaling = null;
    // Only a borrowed reference here; the service owns the stream and is the
    // one that stops it. Releasing on call end rather than holding it for the
    // app's lifetime is deliberate — a microphone that never goes out keeps
    // the recording indicator lit and reads as spyware.
    _localStream = null;
    await _mic.release();
    await _pc?.close();
    _pc = null;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cleanup().then((_) => remoteRenderer.dispose()));
    super.dispose();
  }
}

/// One controller per call screen instance (autoDispose tears the call down
/// when the screen is popped).
final peerCallControllerProvider = StateNotifierProvider.autoDispose
    .family<PeerCallController, PeerCallState, PeerLaunch>((ref, launch) {
      final name =
          (ref.read(authControllerProvider).user?.fullName ?? '').trim();
      final controller = PeerCallController(
        PeerApi(ref.read(apiClientProvider)),
        ref.read(tokenStorageProvider),
        name.isEmpty ? 'Learner' : name,
        ref.read(languageCodeProvider),
        ref.read(authControllerProvider).user?.avatarUrl ?? '',
        IceRepository(ref.read(apiClientProvider)),
        ref.read(microphoneServiceProvider),
      );
      unawaited(controller.start(launch));
      return controller;
    });

/// Hub data: history + how many learners are online.
///
/// The count is the whole reason this refreshes on a timer rather than only
/// when the hub opens. It is what a learner reads to decide whether waiting
/// for a partner is worth it, and it changes because other people arrive and
/// leave — nothing on this device marks that moment. Shown once at open, it
/// was a number from whenever the screen happened to load, and the only way to
/// correct it was closing the app and coming back.
///
/// Twelve seconds because the server re-stamps presence every fifteen
/// (`presence.py`); asking faster cannot surface anyone newer.
final peerHubProvider = FutureProvider.autoDispose((ref) {
  refreshEvery(ref, const Duration(seconds: 12));
  return PeerApi(ref.read(apiClientProvider)).history();
});
