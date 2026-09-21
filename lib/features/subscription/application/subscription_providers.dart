import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/app_config.dart';
import '../data/fake_subscription_repository.dart';
import '../data/store_subscription_repository.dart';
import '../domain/entitlement.dart';
import '../domain/premium_feature.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final SubscriptionRepository repository = AppConfig.useFakeBilling
      ? FakeSubscriptionRepository()
      : StoreSubscriptionRepository(
          store: InAppPurchase.instance,
          productIds: AppConfig.subscriptionProductIds,
        );
  unawaited(repository.initialize());
  ref.onDispose(repository.dispose);
  return repository;
});

final entitlementProvider = NotifierProvider<EntitlementNotifier, Entitlement>(
  EntitlementNotifier.new,
);

class EntitlementNotifier extends Notifier<Entitlement> {
  @override
  Entitlement build() {
    final repository = ref.watch(subscriptionRepositoryProvider);
    final subscription = repository.entitlementChanges.listen(
      (value) => state = value,
    );
    ref.onDispose(subscription.cancel);
    return repository.currentEntitlement;
  }
}

final featureGateProvider = Provider<FeatureGate>(
  (ref) => FeatureGate(ref.watch(entitlementProvider)),
);

final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>(
      (ref) => ref.watch(subscriptionRepositoryProvider).fetchPlans(),
    );
