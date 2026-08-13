import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/live_data.dart';
import '../../../core/providers.dart';
import '../data/gamification_repository.dart';
import '../domain/leaderboard.dart';
import '../domain/models.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(ref.read(apiClientProvider)),
);

/// Total XP, level and streak.
///
/// XP is earned all over the app and the number is shown on a tab that never
/// goes away, so it has to be re-read rather than waited on — see
/// [refreshOnResume] and the shell's own refresh for the whole story of why
/// this used to need the app restarting.
final gamificationProfileProvider =
    FutureProvider.autoDispose<GamificationProfile>((ref) {
      refreshOnResume(ref);
      return ref.read(gamificationRepositoryProvider).profile();
    });

final xpHistoryProvider = FutureProvider.autoDispose<List<XpEvent>>((ref) {
  refreshOnResume(ref);
  return ref.read(gamificationRepositoryProvider).xpHistory();
});

/// The weekly board. `false` is this week, `true` is last week's final result —
/// which is what gives the board a payoff, since this week's standings reset at
/// midnight on Sunday and the winner would otherwise never be seen.
///
/// This week's board moves without this learner doing anything at all: it is
/// other people's XP. That makes it the one figure here that is stale purely
/// through the passage of time, so coming back to the app has to re-read it.
/// Last week's is final and cannot change — refreshing it is harmless and not
/// worth a branch to avoid.
final leaderboardProvider = FutureProvider.autoDispose
    .family<Leaderboard, bool>((ref, previous) {
      refreshOnResume(ref);
      return ref
          .read(gamificationRepositoryProvider)
          .leaderboard(previous: previous);
    });
