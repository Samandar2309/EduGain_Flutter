import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/group_api.dart';
import '../data/group_models.dart';

final groupApiProvider = Provider<GroupApi>(
  (ref) => GroupApi(ref.read(apiClientProvider)),
);

/// The lobby: live public rooms (refetched on demand / pull-to-refresh).
final groupLobbyProvider = FutureProvider.autoDispose<List<GroupRoom>>(
  (ref) => ref.read(groupApiProvider).listRooms(),
);

/// Topics AND the room cap — see [GroupApi.listTopics] for why the cap is not
/// a constant in the app.
final groupTopicsProvider = FutureProvider.autoDispose<GroupConfig>(
  (ref) => ref.read(groupApiProvider).listTopics(),
);
