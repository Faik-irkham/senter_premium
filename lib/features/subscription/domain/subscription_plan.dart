enum BillingPeriod { weekly, monthly, yearly, unknown }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.displayPrice,
    required this.period,
    this.isHighlighted = false,
    this.originalPrice,
    this.badge,
  });

  final String id;
  final String title;
  final String description;

  final String displayPrice;
  final BillingPeriod period;

  final bool isHighlighted;

  final String? originalPrice;

  final String? badge;
}
