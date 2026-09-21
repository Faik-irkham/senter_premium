import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/entitlement.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_repository.dart';
import 'purchase_verifier.dart';

class StoreSubscriptionRepository implements SubscriptionRepository {
  StoreSubscriptionRepository({
    required this._store,
    required this._productIds,
    this._verifier = const ClientSidePurchaseVerifier(),
  });

  final InAppPurchase _store;
  final Set<String> _productIds;
  final PurchaseVerifier _verifier;

  final _entitlementController = StreamController<Entitlement>.broadcast();
  final _productsById = <String, ProductDetails>{};
  final _pendingPurchases = <String, Completer<PurchaseOutcome>>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Entitlement _entitlement = Entitlement.free;
  bool _isAvailable = false;

  @override
  Entitlement get currentEntitlement => _entitlement;

  @override
  Stream<Entitlement> get entitlementChanges => _entitlementController.stream;

  @override
  Future<void> initialize() async {
    _purchaseSubscription ??= _store.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object e) => debugPrint('purchaseStream error: $e'),
    );
    _isAvailable = await _store.isAvailable();
    if (!_isAvailable) return;
    await _store.restorePurchases();
  }

  @override
  Future<List<SubscriptionPlan>> fetchPlans() async {
    if (!_isAvailable) return const [];
    final response = await _store.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('queryProductDetails error: ${response.error}');
    }
    _productsById.clear();
    for (final product in response.productDetails) {
      _productsById.putIfAbsent(product.id, () => product);
    }
    final plans = _productsById.values.map(_toPlan).toList()
      ..sort((a, b) => a.period.index.compareTo(b.period.index));
    return plans;
  }

  @override
  Future<PurchaseOutcome> purchase(String planId) async {
    if (!_isAvailable) return PurchaseOutcome.storeUnavailable;
    final product = _productsById[planId];
    if (product == null) return PurchaseOutcome.failed;

    final completer = Completer<PurchaseOutcome>();
    _pendingPurchases[planId] = completer;
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _pendingPurchases.remove(planId);
        return PurchaseOutcome.failed;
      }
    } catch (e) {
      debugPrint('buyNonConsumable error: $e');
      _pendingPurchases.remove(planId);
      return PurchaseOutcome.failed;
    }
    return completer.future;
  }

  @override
  Future<void> restore() async {
    if (!_isAvailable) return;
    await _store.restorePurchases();
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final outcome = await _handlePurchase(purchase);
      if (outcome != null) {
        _pendingPurchases.remove(purchase.productID)?.complete(outcome);
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<PurchaseOutcome?> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        return null;
      case PurchaseStatus.canceled:
        return PurchaseOutcome.cancelled;
      case PurchaseStatus.error:
        debugPrint('Purchase error: ${purchase.error}');
        return PurchaseOutcome.failed;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (!_productIds.contains(purchase.productID)) return null;
        if (!await _verifier.verify(purchase)) return PurchaseOutcome.failed;
        _setEntitlement(Entitlement.premium(productId: purchase.productID));
        return PurchaseOutcome.success;
    }
  }

  void _setEntitlement(Entitlement value) {
    if (value == _entitlement) return;
    _entitlement = value;
    _entitlementController.add(value);
  }

  SubscriptionPlan _toPlan(ProductDetails product) {
    final period = _periodFromId(product.id);
    return SubscriptionPlan(
      id: product.id,
      title: product.title,
      description: product.description,
      displayPrice: product.price,
      period: period,
      isHighlighted: period == BillingPeriod.yearly,
    );
  }

  static BillingPeriod _periodFromId(String id) {
    if (id.contains('weekly')) return BillingPeriod.weekly;
    if (id.contains('monthly')) return BillingPeriod.monthly;
    if (id.contains('yearly')) return BillingPeriod.yearly;
    return BillingPeriod.unknown;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    for (final completer in _pendingPurchases.values) {
      completer.complete(PurchaseOutcome.cancelled);
    }
    _pendingPurchases.clear();
    _entitlementController.close();
  }
}
