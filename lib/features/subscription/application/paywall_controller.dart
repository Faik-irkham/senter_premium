import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/subscription_repository.dart';
import 'subscription_providers.dart';

class PaywallState {
  const PaywallState({this.processingPlanId, this.isRestoring = false});

  final String? processingPlanId;
  final bool isRestoring;

  bool get isBusy => processingPlanId != null || isRestoring;
}

final paywallControllerProvider =
    NotifierProvider.autoDispose<PaywallController, PaywallState>(
      PaywallController.new,
    );

class PaywallController extends Notifier<PaywallState> {
  @override
  PaywallState build() => const PaywallState();

  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  Future<PurchaseOutcome> purchase(String planId) async {
    if (state.isBusy) return PurchaseOutcome.cancelled;
    state = PaywallState(processingPlanId: planId);
    try {
      return await _repository.purchase(planId);
    } finally {
      if (ref.mounted) state = const PaywallState();
    }
  }

  Future<void> restore() async {
    if (state.isBusy) return;
    state = const PaywallState(isRestoring: true);
    try {
      await _repository.restore();
    } finally {
      if (ref.mounted) state = const PaywallState();
    }
  }
}
