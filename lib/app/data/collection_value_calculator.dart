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
}
