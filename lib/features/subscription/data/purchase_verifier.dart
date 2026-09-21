import 'package:in_app_purchase/in_app_purchase.dart';

abstract interface class PurchaseVerifier {
  Future<bool> verify(PurchaseDetails purchase);
}

class ClientSidePurchaseVerifier implements PurchaseVerifier {
  const ClientSidePurchaseVerifier();

  @override
  Future<bool> verify(PurchaseDetails purchase) async => true;
}
