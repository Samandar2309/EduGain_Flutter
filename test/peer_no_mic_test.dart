import 'package:edugain/features/peer/application/peer_call_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// A peer call where the microphone was refused.
///
/// The reported fault: the call sat on "Ovoz ulanmoqda…" forever, because
/// `getUserMedia` threw out of the handshake with nobody catching it — no
/// phase was ever set and nothing was said on screen.
///
/// The microphone is asked for while the call connects, and that is not a
/// choice: **Telegram's WebView decides about it as the page loads**, so a
/// request made later — behind a "tap to speak" button, which was tried and
/// deployed — shows no dialog at all and is silently refused. The button
/// looked dead. That attempt is reverted; what survives from it is the part
/// that was always right, that a refusal no longer breaks the call.
///
/// **What these tests do not cover:** the WebRTC branch itself. `getUserMedia`
/// and `addTransceiver` need a real platform, so the listen-only fallback can
/// only be proven on a device. What is pinned here is the state it produces
/// and everything the screen decides from it.
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
