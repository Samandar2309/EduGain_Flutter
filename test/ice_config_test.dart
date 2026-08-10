import 'package:edugain/features/peer/data/ice_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where a live call is allowed to route its media.
///
/// The failure this guards is asymmetric. Losing the relay costs the calls that
/// needed it — roughly one in five, all of them on mobile data. Losing STUN as
/// well would cost *every* call, including the ones that were about to connect
/// directly. So the lookup must never be able to take the easy case down with
/// it.
void main() {
  test('the fallback is a usable configuration on its own', () {
    // Not an empty shell: two devices that can see each other connect on STUN
    // alone, which is every call on wifi.
    final servers = IceRepository.fallback['iceServers'] as List;
    expect(servers, isNotEmpty);
    final urls = servers.first['urls'] as List;
    expect(urls.any((u) => (u as String).startsWith('stun:')), isTrue);
  });

  test('the fallback carries no credentials', () {
    // Nothing to leak and nothing to expire — that is the point of it being
    // the offline answer.
    final servers = IceRepository.fallback['iceServers'] as List;
    expect(servers.first.containsKey('credential'), isFalse);
    expect(servers.first.containsKey('username'), isFalse);
  });

  test('the shape matches what RTCPeerConnection expects', () {
    // createPeerConnection reads exactly this key, and a mistyped one fails at
    // call time rather than at compile time.
    expect(IceRepository.fallback.keys, contains('iceServers'));
    expect(IceRepository.fallback['iceServers'], isA<List>());
  });
}
