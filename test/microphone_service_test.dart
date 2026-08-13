import 'package:edugain/core/media/microphone_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The contract the peer call depends on, pinned where it can be checked
/// without a device.
///
/// The load-bearing property is not "the service can open a microphone" — that
/// needs a real platform — but that reading one **never opens one**. The call's
/// handshake reads `liveStream` from inside a WebSocket callback, and if that
/// read could acquire, the bug this whole change exists to fix would simply
/// move rather than go away.
void main() {
  test('a fresh service holds nothing and never invents a stream', () {
    final mic = MicrophoneService();
    // No platform call happens here. If `liveStream` ever started acquiring,
    // this line would throw for want of a plugin — which is exactly the
    // regression worth catching.
    expect(mic.liveStream, isNull);
    expect(mic.hasLiveStream, isFalse);
  });

  test('releasing a service that holds nothing is a no-op', () async {
    final mic = MicrophoneService();
    await mic.release();
    await mic.release(); // idempotent: call teardown can run twice
    expect(mic.hasLiveStream, isFalse);
  });

  test('every failure the learner can act on has its own value', () {
    // One value per instruction. `denied` and `blocked` in particular must stay
    // distinct: one is "allow it", the other is "you have to go to settings",
    // and telling somebody the wrong one wastes their time.
    expect(
      MicFailure.values,
      containsAll(<MicFailure>[
        MicFailure.denied,
        MicFailure.blocked,
        MicFailure.notFound,
        MicFailure.busy,
        MicFailure.insecureContext,
        MicFailure.constraints,
        MicFailure.unknown,
      ]),
    );
  });

  test('permission has a fourth state for platforms that will not answer', () {
    // Safari does not answer for `microphone`, and some WebViews have no
    // Permissions API at all. That is not "denied" — collapsing it to denied
    // would refuse calls on platforms that would have worked.
    expect(MicPermission.values, contains(MicPermission.unsupported));
    expect(MicPermission.unsupported, isNot(MicPermission.denied));
  });

  test('a mic exception says which failure it was, not how it was thrown', () {
    const e = MicException(MicFailure.busy);
    expect(e.failure, MicFailure.busy);
    // Never a raw platform string: these reach the UI layer, which maps them
    // to sentences a learner can read.
    expect(e.toString(), 'MicException(busy)');
  });
}
