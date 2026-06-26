import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/gamification_repository.dart';
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
