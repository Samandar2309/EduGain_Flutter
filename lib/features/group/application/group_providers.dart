import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/live_data.dart';
import '../../../core/providers.dart';
import '../data/group_api.dart';
import '../data/group_models.dart';

final groupApiProvider = Provider<GroupApi>(
  (ref) => GroupApi(ref.read(apiClientProvider)),
);

/// The lobby: live public rooms and how many are in each.
///
/// Rooms open, fill and empty while somebody stands here looking at the list,
/// and none of that happens on this device — so the list has to be re-read on
/// a timer rather than waited on. A lobby that only loads once shows rooms
/// that closed minutes ago and hides the one that just opened, which is the
/// worst possible lie for a screen whose entire job is "join someone".
///
/// Inside a room the roster is already live: `group.py` broadcasts
/// `peer_joined` / `peer_left` over the room's own socket, and that is left
/// exactly as it is.
///
/// Twelve seconds, matching the peer hub and the server's presence cadence.
final groupLobbyProvider = FutureProvider.autoDispose<List<GroupRoom>>((ref) {
  refreshEvery(ref, const Duration(seconds: 12));
  return ref.read(groupApiProvider).listRooms();
});

/// Topics AND the room cap — see [GroupApi.listTopics] for why the cap is not
/// a constant in the app.
final groupTopicsProvider = FutureProvider.autoDispose<GroupConfig>(
  (ref) => ref.read(groupApiProvider).listTopics(),
);
