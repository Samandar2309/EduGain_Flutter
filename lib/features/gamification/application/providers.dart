import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/gamification_repository.dart';
import '../domain/leaderboard.dart';
import '../domain/models.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(ref.read(apiClientProvider)),
);

final gamificationProfileProvider =
    FutureProvider.autoDispose<GamificationProfile>(
      (ref) => ref.read(gamificationRepositoryProvider).profile(),
    );

final xpHistoryProvider = FutureProvider.autoDispose<List<XpEvent>>(
  (ref) => ref.read(gamificationRepositoryProvider).xpHistory(),
);

/// The weekly board. `false` is this week, `true` is last week's final result —
/// which is what gives the board a payoff, since this week's standings reset at
/// midnight on Sunday and the winner would otherwise never be seen.
final leaderboardProvider =
    FutureProvider.autoDispose.family<Leaderboard, bool>(
      (ref, previous) => ref
          .read(gamificationRepositoryProvider)
          .leaderboard(previous: previous),
    );
