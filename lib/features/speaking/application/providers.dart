import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/speaking_repository.dart';
import '../domain/models.dart';

final speakingRepositoryProvider = Provider<SpeakingRepository>(
  (ref) => SpeakingRepository(ref.read(apiClientProvider)),
);

/// Scenario catalogue for the picker (auto-disposed, refetch on revisit).
final scenariosProvider = FutureProvider.autoDispose<List<Scenario>>(
  (ref) => ref.read(speakingRepositoryProvider).listScenarios(),
);
