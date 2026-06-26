import 'package:edugain/core/format.dart';
import 'package:edugain/features/subscriptions/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatUzs adds thousands separators', () {
    expect(formatUzs(22000), "22 000 so'm");
    expect(formatUzs(176000), "176 000 so'm");
    expect(formatUzs(0), "0 so'm");
  });

  test('Plan parses the backend shape', () {
    final plan = Plan.fromJson(const {
      'tier': 'main',
      'price_uzs': 22000,
      'period': 'monthly',
      'features': ['15 AI sessions/day', 'Full feedback'],
    });
    expect(plan.tier, 'main');
    expect(plan.priceUzs, 22000);
    expect(plan.features.length, 2);
  });

  test('Subscription distinguishes free vs paid', () {
    final free = Subscription.fromJson(const {'tier': 'free', 'status': 'active'});
    final paid = Subscription.fromJson(const {
      'tier': 'main',
      'status': 'active',
      'expires_at': '2026-07-20T00:00:00+00:00',
    });
    expect(free.isPaid, isFalse);
    expect(paid.isPaid, isTrue);
    expect(paid.isActive, isTrue);
  });
}
