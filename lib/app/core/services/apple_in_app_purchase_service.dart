import 'dart:async';
import 'dart:developer' as developer;

import 'package:in_app_purchase/in_app_purchase.dart';

/// iOS App Store subscription helper (bourboneur `select_package.dart` pattern).
class AppleInAppPurchaseService {
  AppleInAppPurchaseService({required this.onPurchaseUpdated});

  final void Function(PurchaseDetails purchase) onPurchaseUpdated;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  var isAvailable = false;
  final products = <ProductDetails>[];

  Future<void> loadProducts(Set<String> productIds) async {
    if (productIds.isEmpty) return;

    isAvailable = await _iap.isAvailable();
    developer.log(
      '[IAP] Store available: $isAvailable, querying: $productIds',
      name: 'AppleIAP',
    );

    if (!isAvailable) return;

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      developer.log(
        '[IAP] queryProductDetails error: ${response.error}',
        name: 'AppleIAP',
      );
    }
    if (response.notFoundIDs.isNotEmpty) {
      developer.log(
        '[IAP] Products not found: ${response.notFoundIDs}',
        name: 'AppleIAP',
      );
    }

    products
      ..clear()
      ..addAll(response.productDetails);

    for (final product in products) {
      developer.log(
        '[IAP] Loaded product id=${product.id} '
        'title=${product.title} price=${product.price}',
        name: 'AppleIAP',
      );
    }
  }

  void startListening() {
    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseBatch,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        developer.log('[IAP] purchaseStream error: $error', name: 'AppleIAP');
      },
    );
  }

  Future<void> _handlePurchaseBatch(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      _logPurchase(purchase);
      onPurchaseUpdated(purchase);
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  ProductDetails? productForAppleId(String appleProductId) {
    final id = appleProductId.trim();
    if (id.isEmpty) return null;
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  /// App Store localized price (e.g. `$4.99`) for a product id.
  String? localizedPrice(String appleProductId) =>
      productForAppleId(appleProductId)?.price;

  Future<bool> purchase(ProductDetails product) async {
    developer.log('[IAP] Starting purchase for ${product.id}', name: 'AppleIAP');
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() async {
    developer.log('[IAP] Restoring purchases', name: 'AppleIAP');
    await _iap.restorePurchases();
  }

  void _logPurchase(PurchaseDetails purchase) {
    developer.log(
      '[IAP] Purchase update:\n'
      '  productID: ${purchase.productID}\n'
      '  purchaseID: ${purchase.purchaseID}\n'
      '  status: ${purchase.status}\n'
      '  pendingComplete: ${purchase.pendingCompletePurchase}\n'
      '  transactionDate: ${purchase.transactionDate}\n'
      '  verificationData.server: ${purchase.verificationData.serverVerificationData}\n'
      '  verificationData.local: ${purchase.verificationData.localVerificationData}',
      name: 'AppleIAP',
    );
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}
