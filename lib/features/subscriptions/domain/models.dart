// Subscription / billing models (contract §3, §4.3).

class Plan {
  const Plan({
    required this.tier,
    required this.priceUzs,
    required this.period,
    required this.features,
  });

  final String tier;
  final int priceUzs;
  final String period; // monthly | yearly
  final List<String> features;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    tier: json['tier'] as String,
    priceUzs: (json['price_uzs'] as num?)?.toInt() ?? 0,
    period: json['period'] as String? ?? 'monthly',
    features: ((json['features'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class Subscription {
  const Subscription({
    required this.tier,
    required this.status,
    required this.autoRenew,
    this.expiresAt,
    this.billingPeriod,
  });

  final String tier;
  final String status; // active | expired | canceled | pending
  final bool autoRenew;
  final String? expiresAt;
  final String? billingPeriod;

  bool get isPaid => tier != 'free';
  bool get isActive => status == 'active';

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    tier: json['tier'] as String? ?? 'free',
    status: json['status'] as String? ?? 'active',
    autoRenew: json['auto_renew'] as bool? ?? false,
    expiresAt: json['expires_at'] as String?,
    billingPeriod: json['billing_period'] as String?,
  );
}

class Checkout {
  const Checkout({required this.paymentUrl, required this.paymentId});
  final String paymentUrl;
  final String paymentId;
}
