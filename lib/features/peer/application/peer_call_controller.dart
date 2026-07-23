import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/api/token_storage.dart';
import '../../../core/providers.dart';
import '../data/peer_api.dart';
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
  const PeerLaunchMatch();

  @override
  bool operator ==(Object other) => other is PeerLaunchMatch;

  @override
  int get hashCode => 1;
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
    this.muted = false,
    this.partnerOnline = false,
    this.endReason,
  });

  final PeerPhase phase;
  final String roomCode;
  final String role; // 'host' | 'guest'
  final PeerTopic? topic;
  final String partnerName;
  final bool muted;
  final bool partnerOnline;
  final String? endReason; // 'partner_left' | 'you_ended' | 'failed'

  PeerCallState copyWith({
    PeerPhase? phase,
    String? roomCode,
    String? role,
    PeerTopic? topic,
    String? partnerName,
    bool? muted,
    bool? partnerOnline,
    String? endReason,
  }) => PeerCallState(
    phase: phase ?? this.phase,
    roomCode: roomCode ?? this.roomCode,
    role: role ?? this.role,
    topic: topic ?? this.topic,
    partnerName: partnerName ?? this.partnerName,
    muted: muted ?? this.muted,
    partnerOnline: partnerOnline ?? this.partnerOnline,
    endReason: endReason ?? this.endReason,
  );
}

/// Drives one peer call end to end: matchmaking/room → signaling → WebRTC →
/// teardown. Convention (baked into the server's `hello`): the GUEST creates
/// the offer, the host answers.
class PeerCallController extends StateNotifier<PeerCallState> {
  PeerCallController(this._api, this._tokens, this._displayName)
      : super(const PeerCallState());

  final PeerApi _api;
  final TokenStorage _tokens;
  final String _displayName;

  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  PeerSignaling? _signaling;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _offerStarted = false;
  bool _disposed = false;

  static const _iceConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> start(PeerLaunch launch) async {
    try {
      await remoteRenderer.initialize();
      var room = '';
      var mode = '';
      switch (launch) {
        case PeerLaunchMatch():
          mode = 'match';
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
        room: room,
        mode: mode,
      );
      _signaling = signaling;
      _sub = signaling.messages.listen(
        _onMessage,
        onError: (Object _) => _end('failed'),
        onDone: () {
          if (state.phase != PeerPhase.ended) _end('failed');
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

    final pc = await createPeerConnection(_iceConfig);
    _pc = pc;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    for (final track in _localStream!.getAudioTracks()) {
      await pc.addTrack(track, _localStream!);
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
      );
      unawaited(controller.start(launch));
      return controller;
    });

/// Hub data: history + online count (refetched every time the hub opens).
final peerHubProvider = FutureProvider.autoDispose(
  (ref) => PeerApi(ref.read(apiClientProvider)).history(),
);
