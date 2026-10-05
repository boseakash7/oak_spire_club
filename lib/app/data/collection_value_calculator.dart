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

  /// Every figure the Home and Collection headers show, computed once.
  ///
  /// The headline is what the collection is worth today: each row at its
  /// bluebook average, or at what was paid when the bottle has no market
  /// price, so a bottle is never dropped from the total. Gain compares market
  /// against paid only on rows that have both, so a bottle valued at cost
  /// cannot pull the percentage toward 0.
  static CollectionValueSummary summarize(Iterable<CollectionItemModel> items) {
    var invested = 0.0;
    var value = 0.0;
    var gainMarket = 0.0;
    var gainPaid = 0.0;
    var priced = 0;
    var atCost = 0;

    for (final item in items) {
      final paid = item.paidTotalValue;
      final market = item.marketTotalValue;
      invested += paid;
      if (market == null) {
        value += paid;
        atCost++;
        continue;
      }
      value += market;
      priced++;
      if (paid > 0) {
        gainMarket += market;
        gainPaid += paid;
      }
    }

    final hasGain = gainPaid > 0;
    return CollectionValueSummary(
      invested: invested,
      value: value,
      showingInvestedAsValue: priced == 0,
      valuedAtCostCount: priced == 0 ? 0 : atCost,
      gain: hasGain ? gainMarket - gainPaid : null,
      gainPercent: hasGain ? (gainMarket - gainPaid) / gainPaid * 100 : null,
    );
  }
}

/// See [CollectionValueCalculator.summarize].
class CollectionValueSummary {
  const CollectionValueSummary({
    required this.invested,
    required this.value,
    required this.showingInvestedAsValue,
    required this.valuedAtCostCount,
    required this.gain,
    required this.gainPercent,
  });

  /// What the user paid in total.
  final double invested;

  /// Today's value: market price where known, price paid elsewhere.
  final double value;

  /// No bottle has a market price, so [value] is just [invested] and must be
  /// labelled as such rather than called "value".
  final bool showingInvestedAsValue;

  /// Bottles without a market price, counted in [value] at what was paid.
  final int valuedAtCostCount;

  /// Market minus paid over the bottles that have both; null when none do.
  final double? gain;
  final double? gainPercent;
}
