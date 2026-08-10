import 'package:flutter_test/flutter_test.dart';

/// Telling a learner *why* the call ended.
///
/// A WebSocket that closes looks identical whether the network dropped or the
/// server deliberately hung up. Without reading the close code, someone who has
/// simply used up today's live-conversation minutes is told the call "failed" —
/// so they try again, and are told exactly the same thing.
///
/// The mapping itself is the contract with `peer.py`; the controller that
/// applies it needs a live socket, so what is pinned here is the agreement.
void main() {
  // Mirrors `_quotaExhausted` in peer_call_controller.dart and the
  // `ws.close(code=4402, ...)` in the backend's peer router.
  const quotaExhausted = 4402;
  const unauthorized = 4401;

  String reasonFor(int? closeCode) => switch (closeCode) {
        quotaExhausted => 'peer_quota',
        _ => 'failed',
      };

  test('the quota close code becomes its own end reason', () {
    expect(reasonFor(quotaExhausted), 'peer_quota');
  });

  test('an unexplained drop is still a failure', () {
    // No code at all: the connection died on its own.
    expect(reasonFor(null), 'failed');
    // A normal close, and any code we do not have a specific answer for.
    expect(reasonFor(1000), 'failed');
    expect(reasonFor(1006), 'failed');
  });

  test('auth rejection is not mistaken for a spent quota', () {
    // 4401 and 4402 differ by one digit and mean very different things: one is
    // "sign in again", the other is "buy more time".
    expect(reasonFor(unauthorized), isNot('peer_quota'));
  });

  test('the code stays inside the application-defined range', () {
    // 4000-4999 is the only range WebSocket reserves for applications; outside
    // it, clients and proxies are free to reinterpret the value.
    expect(quotaExhausted, inInclusiveRange(4000, 4999));
  });
}
