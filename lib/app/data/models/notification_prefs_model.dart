/// Preference keys (stored locally; map to FCM topics in firebase_notification_topics.dart).
abstract final class NotificationPreferenceKey {
  static const pushNotifications = 'push_notifications';
  static const collectionValue = 'collection_value';
  static const marketBenchmarks = 'market_benchmarks';
  static const priceMovement = 'price_movement';
  static const tipsUpdates = 'tips_updates';
}

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

  /// Legacy local-storage keys (pre-API).
  static const _legacyPush = 'push_enabled';
  static const _legacyCollection = 'collection_alerts';
  static const _legacyMarket = 'market_benchmark_alerts';
  static const _legacyPrice = 'price_movement_alerts';
  static const _legacyProduct = 'product_updates';

  factory NotificationPrefsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPrefsModel();

    bool read(String apiKey, String legacyKey, {bool defaultValue = true}) {
      final v = json[apiKey] ?? json[legacyKey];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return defaultValue;
    }

    return NotificationPrefsModel(
      pushEnabled: read(
        NotificationPreferenceKey.pushNotifications,
        _legacyPush,
      ),
      collectionAlerts: read(
        NotificationPreferenceKey.collectionValue,
        _legacyCollection,
      ),
      marketBenchmarkAlerts: read(
        NotificationPreferenceKey.marketBenchmarks,
        _legacyMarket,
      ),
      priceMovementAlerts: read(
        NotificationPreferenceKey.priceMovement,
        _legacyPrice,
      ),
      productUpdates: read(
        NotificationPreferenceKey.tipsUpdates,
        _legacyProduct,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        NotificationPreferenceKey.pushNotifications: pushEnabled,
        NotificationPreferenceKey.collectionValue: collectionAlerts,
        NotificationPreferenceKey.marketBenchmarks: marketBenchmarkAlerts,
        NotificationPreferenceKey.priceMovement: priceMovementAlerts,
        NotificationPreferenceKey.tipsUpdates: productUpdates,
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

  NotificationPrefsModel copyWithPreferenceKey(String key, bool enabled) {
    switch (key) {
      case NotificationPreferenceKey.pushNotifications:
        return copyWith(pushEnabled: enabled);
      case NotificationPreferenceKey.collectionValue:
        return copyWith(collectionAlerts: enabled);
      case NotificationPreferenceKey.marketBenchmarks:
        return copyWith(marketBenchmarkAlerts: enabled);
      case NotificationPreferenceKey.priceMovement:
        return copyWith(priceMovementAlerts: enabled);
      case NotificationPreferenceKey.tipsUpdates:
        return copyWith(productUpdates: enabled);
      default:
        return this;
    }
  }
}
