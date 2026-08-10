import '../../../core/api/api_client.dart';

/// Where a live call is allowed to route its media.
///
/// Fetched per call rather than compiled in, because the TURN credential the
/// server returns deliberately expires — a value baked into the bundle would be
/// stale long before the app reached anyone.
class IceRepository {
  IceRepository(this._api);

  final ApiClient _api;

  /// STUN only. Enough for two devices that can see each other, which is every
  /// call on wifi — and the reason a relay outage degrades rather than breaks.
  static const Map<String, dynamic> fallback = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
  };

  /// The RTCPeerConnection configuration for the next call.
  ///
  /// Never throws: a call that could have connected directly must not be lost
  /// because the relay lookup failed, so any error falls back to STUN.
  Future<Map<String, dynamic>> config() async {
    try {
      final data = await _api.get('/peer/ice');
      final servers = data['ice_servers'];
      if (servers is List && servers.isNotEmpty) {
        return {'iceServers': servers};
      }
    } catch (_) {
      // Fall through — direct connections still work.
    }
    return fallback;
  }
}
