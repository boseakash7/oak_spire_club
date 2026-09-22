import 'models/collection_item_display.dart';
import 'models/collection_item_model.dart';

/// Single source of truth for “money invested in collection” across Home and Collection.
///
/// Uses each row’s `pricePaid` × normalized `quantity`. The repository returns grouped
/// rows (duplicate bottles merged), so this matches server totals without relying on
/// chart endpoints or stale chart cache.
class CollectionValueCalculator {
  CollectionValueCalculator._();

  /// Change % from chart-data `first_price` / `last_price` (bourboneur home).
  ///
  /// `100 - (first / last) * 100` — same as `(last - first) / last * 100`.
  static double? movedPercentFromFirstLast({
    required double? first,
    required double? last,
  }) {
    if (first == null || last == null || last == 0) return null;
    return 100 - (first / last) * 100;
  }

  /// Mini-bar fill (0–1) for the same % shown in “Moved +64% …”.
  static double movedBarFractionFromPercent(double? percent) {
    if (percent == null) return 0;
    return (percent.abs() / 100).clamp(0.0, 1.0);
  }

  static double totalInvestedFromItems(Iterable<CollectionItemModel> items) {
    var sum = 0.0;
    for (final item in items) {
      final price = double.tryParse(item.pricePaid ?? '') ?? 0;
      final qtyRaw = int.tryParse(item.quantity ?? '');
      final qty = (qtyRaw == null || qtyRaw <= 0) ? 1 : qtyRaw;
      sum += price * qty;
    }
    return sum;
  }

  /// What the collection is worth today: each row's bluebook average ×
  /// quantity.
  ///
  /// Rows whose bluebook carries no price contribute nothing, so a partially
  /// priced collection still totals the part we can value. Returns null when
  /// *no* row has a market price — the caller then has nothing to show and
  /// should fall back to invested value rather than print `$0`.
  static double? totalMarketValueFromItems(
    Iterable<CollectionItemModel> items,
  ) {
    var sum = 0.0;
    var priced = false;
    for (final item in items) {
      final unit = item.marketAverageValue;
      if (unit == null) continue;
      priced = true;
      final qtyRaw = int.tryParse(item.quantity ?? '');
      final qty = (qtyRaw == null || qtyRaw <= 0) ? 1 : qtyRaw;
      sum += unit * qty;
    }
    return priced ? sum : null;
  }
}
