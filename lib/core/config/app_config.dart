abstract final class AppConfig {
  static const bool useFakeBilling = bool.fromEnvironment(
    'FAKE_BILLING',
    defaultValue: true,
  );

  static const bool virtualTorchFallback = bool.fromEnvironment(
    'VIRTUAL_TORCH_FALLBACK',
    defaultValue: true,
  );

  static const Set<String> subscriptionProductIds = {
    'senter_premium_weekly',
    'senter_premium_monthly',
    'senter_premium_yearly',
  };
}
