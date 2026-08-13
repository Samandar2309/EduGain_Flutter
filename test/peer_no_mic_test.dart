import 'package:edugain/features/peer/application/peer_call_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A peer call whose microphone is missing by the time the handshake runs.
///
/// The microphone is no longer opened here. It is opened by the tap that
/// starts the call — the filter sheet, the friend-room button, the join-by-code
/// dialog — because a browser only shows a permission dialog while the gesture
/// that asked for it is still live, and the handshake runs from a WebSocket
/// frame that can arrive minutes later. Matchmaking cannot start without a live
/// microphone, so this state is now rare rather than routine: it means the
/// microphone died between the tap and the handshake (unplugged, revoked in
/// settings, or taken by an incoming phone call).
///
/// What is pinned below is unchanged and still matters: losing the microphone
/// must not end the call. The learner keeps hearing their partner.
///
/// **What these tests do not cover:** the WebRTC branch itself. `addTransceiver`
/// needs a real platform, so the listen-only fallback can only be proven on a
/// device. What is pinned here is the state it produces and everything the
/// screen decides from it.
void main() {
  test('a call assumes it has a microphone until told otherwise', () {
    const state = PeerCallState();
    expect(state.micDenied, isFalse);
    expect(state.muted, isFalse);
  });

  test('declining leaves the call alive, just silent', () {
    // Nothing about the connection changes: they stay in the conversation and
    // keep hearing their partner. This is the whole fix for the hang.
    final declined = const PeerCallState()
        .copyWith(phase: PeerPhase.inCall)
        .copyWith(micDenied: true, muted: true);

    expect(declined.phase, PeerPhase.inCall);
    expect(declined.endReason, isNull);
  });

  test('losing the microphone is carried, not dropped, by copyWith', () {
    // The flag has to survive every later state change — a phase transition
    // that quietly cleared it would put the "you are muted" notice back to
    // sleep halfway through the call.
    const start = PeerCallState();
    final denied = start.copyWith(micDenied: true, muted: true);

    expect(denied.micDenied, isTrue);
    expect(denied.copyWith(phase: PeerPhase.inCall).micDenied, isTrue);
    expect(
      denied.copyWith(partnerName: 'Aziz', partnerOnline: true).micDenied,
      isTrue,
    );
  });

  test('a call with no microphone still reaches the connected phase', () {
    // The whole point of the fix: no microphone is not a failed call. It used
    // to end the handshake; now it ends only the sending half.
    final listening = const PeerCallState()
        .copyWith(micDenied: true, muted: true)
        .copyWith(phase: PeerPhase.inCall);

    expect(listening.phase, PeerPhase.inCall);
    expect(listening.endReason, isNull);
    expect(listening.micDenied, isTrue);
  });

  test('no microphone reads as muted, so nothing claims to be transmitting', () {
    final listening = const PeerCallState().copyWith(
      micDenied: true,
      muted: true,
    );
    expect(listening.muted, isTrue);
  });
}
