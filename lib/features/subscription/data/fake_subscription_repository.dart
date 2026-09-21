import 'dart:async';

import '../domain/entitlement.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_repository.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    Entitlement initial = Entitlement.free,
    this.latency = const Duration(milliseconds: 1200),
  }) : _entitlement = initial;

  final Duration latency;
  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement _entitlement;

  static const plans = [
    SubscriptionPlan(
      id: 'senter_premium_weekly',
      title: 'Pemula Gelap',
      description: '7 hari hak mematikan senter',
      displayPrice: 'Rp15.000',
      period: BillingPeriod.weekly,
    ),
    SubscriptionPlan(
      id: 'senter_premium_monthly',
      title: 'Penikmat Gelap',
      description: '30 hari + boleh mematikan sambil rebahan',
      displayPrice: 'Rp49.000',
      originalPrice: 'Rp89.000',
      period: BillingPeriod.monthly,
    ),
    SubscriptionPlan(
      id: 'senter_premium_yearly',
      title: 'Sultan Kegelapan',
      description: 'Setahun penuh bebas dari cahaya',
      displayPrice: 'Rp399.000',
      originalPrice: 'Rp999.000',
      badge: 'PALING SULTAN',
      period: BillingPeriod.yearly,
      isHighlighted: true,
    ),
  ];

  @override
  Entitlement get currentEntitlement => _entitlement;

  @override
  Stream<Entitlement> get entitlementChanges => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<SubscriptionPlan>> fetchPlans() async {
    await Future<void>.delayed(latency);
    return plans;
  }

  @override
  Future<PurchaseOutcome> purchase(String planId) async {
    await Future<void>.delayed(latency);
    _set(Entitlement.premium(productId: planId));
    return PurchaseOutcome.success;
  }

  @override
  Future<void> restore() async => Future<void>.delayed(latency);

  void reset() => _set(Entitlement.free);

  void _set(Entitlement value) {
    _entitlement = value;
    _controller.add(value);
  }

  @override
  void dispose() => _controller.close();
}
