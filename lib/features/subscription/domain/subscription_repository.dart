import 'entitlement.dart';
import 'subscription_plan.dart';

enum PurchaseOutcome { success, pending, cancelled, failed, storeUnavailable }

abstract interface class SubscriptionRepository {
  Future<void> initialize();

  Entitlement get currentEntitlement;

  Stream<Entitlement> get entitlementChanges;

  Future<List<SubscriptionPlan>> fetchPlans();

  Future<PurchaseOutcome> purchase(String planId);

  Future<void> restore();

  void dispose();
}
