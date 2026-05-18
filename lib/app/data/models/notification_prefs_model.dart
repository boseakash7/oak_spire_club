class NotificationPrefsModel {
  const NotificationPrefsModel({
    this.pushEnabled = true,
    this.collectionAlerts = true,
    this.marketBenchmarkAlerts = true,
    this.priceMovementAlerts = true,
    this.productUpdates = true,
  });

  final bool pushEnabled;
  final bool collectionAlerts;
  final bool marketBenchmarkAlerts;
  final bool priceMovementAlerts;
  final bool productUpdates;

  static const pushEnabledKey = 'push_enabled';
  static const collectionAlertsKey = 'collection_alerts';
  static const marketBenchmarkAlertsKey = 'market_benchmark_alerts';
  static const priceMovementAlertsKey = 'price_movement_alerts';
  static const productUpdatesKey = 'product_updates';

  factory NotificationPrefsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPrefsModel();
    bool readBool(String key, {bool defaultValue = true}) {
      final v = json[key];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return defaultValue;
    }

    return NotificationPrefsModel(
      pushEnabled: readBool(pushEnabledKey),
      collectionAlerts: readBool(collectionAlertsKey),
      marketBenchmarkAlerts: readBool(marketBenchmarkAlertsKey),
      priceMovementAlerts: readBool(priceMovementAlertsKey),
      productUpdates: readBool(productUpdatesKey),
    );
  }

  Map<String, dynamic> toJson() => {
        pushEnabledKey: pushEnabled,
        collectionAlertsKey: collectionAlerts,
        marketBenchmarkAlertsKey: marketBenchmarkAlerts,
        priceMovementAlertsKey: priceMovementAlerts,
        productUpdatesKey: productUpdates,
      };

  NotificationPrefsModel copyWith({
    bool? pushEnabled,
    bool? collectionAlerts,
    bool? marketBenchmarkAlerts,
    bool? priceMovementAlerts,
    bool? productUpdates,
  }) {
    return NotificationPrefsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      collectionAlerts: collectionAlerts ?? this.collectionAlerts,
      marketBenchmarkAlerts:
          marketBenchmarkAlerts ?? this.marketBenchmarkAlerts,
      priceMovementAlerts: priceMovementAlerts ?? this.priceMovementAlerts,
      productUpdates: productUpdates ?? this.productUpdates,
    );
  }
}
