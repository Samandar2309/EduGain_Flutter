import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/placement_repository.dart';
import '../domain/models.dart';

final placementRepositoryProvider = Provider<PlacementRepository>(
  (ref) => PlacementRepository(ref.read(apiClientProvider)),
);

final placementTestProvider =
    FutureProvider.autoDispose<List<PlacementQuestion>>(
      (ref) => ref.read(placementRepositoryProvider).getTest(),
    );

/// The last measured level, or a result with none if the test was never taken.
///
/// Read before the test is fetched: someone who already has a level is usually
/// arriving to check it, not to sit the whole thing again, and sending them
/// straight into question one throws away the answer they came for.
final placementResultProvider = FutureProvider.autoDispose<PlacementResult>(
  (ref) => ref.read(placementRepositoryProvider).latestResult(),
);
