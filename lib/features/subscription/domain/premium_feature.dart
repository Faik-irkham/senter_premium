import 'entitlement.dart';

enum PremiumFeature { turnOffFlashlight }

class FeatureGate {
  const FeatureGate(this.entitlement);

  final Entitlement entitlement;

  bool canUse(PremiumFeature feature) => switch (feature) {
    PremiumFeature.turnOffFlashlight => entitlement.isPremium,
  };
}
