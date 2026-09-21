class Entitlement {
  const Entitlement._({required this.isPremium, this.productId});

  const Entitlement.premium({required String productId})
    : this._(isPremium: true, productId: productId);

  static const free = Entitlement._(isPremium: false);

  final bool isPremium;

  final String? productId;

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.isPremium == isPremium &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(isPremium, productId);

  @override
  String toString() =>
      'Entitlement(isPremium: $isPremium, productId: $productId)';
}
