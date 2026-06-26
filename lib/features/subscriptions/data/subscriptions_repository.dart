import 'dart:math';

import '../../../core/api/api_client.dart';
import '../domain/models.dart';

class SubscriptionsRepository {
  SubscriptionsRepository(this._api);

  final ApiClient _api;

  Future<List<Plan>> listPlans() async {
    final data = await _api.get('/subscriptions/plans');
    final plans = (data['plans'] as List?) ?? const [];
    return plans.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Subscription> mySubscription() async {
    final data = await _api.get('/subscriptions/me');
    return Subscription.fromJson(data['subscription'] as Map<String, dynamic>);
  }

  /// Create a payment and return the provider checkout URL. The Idempotency-Key
  /// header stops a retried tap from double-charging (REQ-04-005).
  Future<Checkout> checkout({
    required String tier,
    required String period,
    required String provider,
  }) async {
    final data = await _api.post(
      '/subscriptions/checkout',
      body: {'tier': tier, 'period': period, 'provider': provider},
      headers: {'Idempotency-Key': _idempotencyKey()},
    );
    return Checkout(
      paymentUrl: data['payment_url'] as String,
      paymentId: data['payment_id'] as String,
    );
  }

  Future<void> cancel() => _api.post('/subscriptions/cancel');

  String _idempotencyKey() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
}
