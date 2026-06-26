import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/grammar_repository.dart';
import '../domain/models.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>(
  (ref) => GrammarRepository(ref.read(apiClientProvider)),
);

final grammarTopicsProvider = FutureProvider.autoDispose<List<GrammarTopic>>(
  (ref) => ref.read(grammarRepositoryProvider).listTopics(),
);

final grammarTopicDetailProvider = FutureProvider.autoDispose
    .family<GrammarTopicDetail, String>(
      (ref, topicId) => ref.read(grammarRepositoryProvider).getTopic(topicId),
    );
