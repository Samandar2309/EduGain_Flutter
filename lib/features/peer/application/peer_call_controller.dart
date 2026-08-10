import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/api/token_storage.dart';
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
  ) : super(const PeerCallState());

  final PeerApi _api;
  final IceRepository _iceRepo;
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
      _sub = signaling.messages.listen(
        _onMessage,
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
        if (state.role == 'guest') await _beginOffer();
      case 'offer':
        final pc = await _ensurePeerConnection();
        await pc.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String?, 'offer'),
        );
        final answer = await pc.createAnswer({});
        await pc.setLocalDescription(answer);
        _signaling?.send({'type': 'answer', 'sdp': answer.sdp});
      case 'answer':
        await _pc?.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String?, 'answer'),
        );
      case 'ice':
        final c = msg['candidate'];
        if (c is Map) {
          await _pc?.addCandidate(
            RTCIceCandidate(
              c['candidate'] as String?,
              c['sdpMid'] as String?,
              c['sdpMLineIndex'] as int?,
            ),
          );
        }
      case 'peer_left' || 'hangup':
        _end('partner_left');
    }
  }

  Future<void> _beginOffer() async {
    if (_offerStarted) return;
    _offerStarted = true;
    final pc = await _ensurePeerConnection();
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    _signaling?.send({'type': 'offer', 'sdp': offer.sdp});
  }

  Future<RTCPeerConnection> _ensurePeerConnection() async {
    final existing = _pc;
    if (existing != null) return existing;

    final pc = await createPeerConnection(await _ice());
    _pc = pc;

    // Asked for here, while the call is connecting, because in the Telegram
    // Mini App that is the only moment it can be asked for at all.
    //
    // This was moved behind a "tap to speak" button so nobody met a prompt
    // they had not chosen to open. It does not work: Telegram's WebView
    // decides about the microphone as the page loads, so a request made later
    // shows no dialog and is simply refused. The button appeared dead, which
    // is what was reported — the platform, not the code.
    //
    // What is kept from that attempt is the part that was always right: the
    // call survives a refusal. It used to throw straight out of here with
    // nobody catching it, and the screen sat on "connecting audio" forever.
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
    } catch (_) {
      _localStream = null;
    }

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getAudioTracks()) {
        await pc.addTrack(track, stream);
      }
    } else {
      // No microphone, but still worth being in: this side can listen. The
      // transceiver is not optional — with neither a track nor a transceiver
      // the offer carries no audio line, so nothing would arrive in either
      // direction and the call would connect to silence.
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
          state = state.copyWith(phase: PeerPhase.inCall);
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
    await _sub?.cancel();
    _sub = null;
    await _signaling?.close();
    _signaling = null;
    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
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
      );
      unawaited(controller.start(launch));
      return controller;
    });

/// Hub data: history + online count (refetched every time the hub opens).
final peerHubProvider = FutureProvider.autoDispose(
  (ref) => PeerApi(ref.read(apiClientProvider)).history(),
);
