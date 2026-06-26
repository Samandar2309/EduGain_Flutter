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
