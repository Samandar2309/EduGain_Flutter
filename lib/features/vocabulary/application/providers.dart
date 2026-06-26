import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/vocabulary_repository.dart';
import '../domain/models.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>(
  (ref) => VocabularyRepository(ref.read(apiClientProvider)),
);

final vocabSetsProvider = FutureProvider.autoDispose<List<VocabSet>>(
  (ref) => ref.read(vocabularyRepositoryProvider).listSets(),
);

final vocabSetDetailProvider = FutureProvider.autoDispose
    .family<VocabSetDetail, String>(
      (ref, setId) => ref.read(vocabularyRepositoryProvider).getSet(setId),
    );

/// Words due for spaced-repetition review right now (drives the home nudge and
/// the review screen). Auto-disposed so it refetches when revisited.
final reviewDueProvider = FutureProvider.autoDispose<List<VocabItem>>(
  (ref) => ref.read(vocabularyRepositoryProvider).fetchReview(),
);
