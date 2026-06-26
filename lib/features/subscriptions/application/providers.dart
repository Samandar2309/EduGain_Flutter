import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/subscriptions_repository.dart';
import '../domain/models.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>(
  (ref) => SubscriptionsRepository(ref.read(apiClientProvider)),
);

final plansProvider = FutureProvider.autoDispose<List<Plan>>(
  (ref) => ref.read(subscriptionsRepositoryProvider).listPlans(),
);

final mySubscriptionProvider = FutureProvider.autoDispose<Subscription>(
  (ref) => ref.read(subscriptionsRepositoryProvider).mySubscription(),
);
