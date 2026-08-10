import '../../../core/api/api_client.dart';
import '../domain/channel_gate.dart';

/// Asks the server whether this learner is in our Telegram channel.
///
/// Always a fresh call. The server remembers a yes for an hour, so the common
/// case is cheap; a no is deliberately never cached, because the whole flow
/// depends on "I've subscribed" being noticed seconds after they did it.
class ChannelRepository {
  ChannelRepository(this._api);

  final ApiClient _api;

  Future<ChannelGate> status() async =>
      ChannelGate.fromJson(await _api.get('/telegram/channel'));
}
