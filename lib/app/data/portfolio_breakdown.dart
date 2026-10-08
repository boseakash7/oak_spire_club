import 'models/collection_item_display.dart';
import 'models/collection_item_model.dart';

/// What the collection is split by in its portfolio mix.
enum PortfolioGrouping {
  type('Type'),
  brand('Brand');

  const PortfolioGrouping(this.label);

  final String label;
}

/// One share of the collection's value: a spirit type or a brand.
class PortfolioSlice {
  const PortfolioSlice({
    required this.label,
    required this.value,
    required this.share,
    required this.bottles,
    this.isOther = false,
  });

  final String label;

  /// Today's value of the bottles in this slice.
  final double value;

  /// [value] as a fraction of the whole collection (0–1).
  final double share;

  /// Bottles, not rows: quantities add up.
  final int bottles;

  /// The tail of smaller groups, folded into one slice.
  final bool isOther;
}

/// How a collection's value splits across spirit types or brands.
///
/// A row is worth what [CollectionValueCalculator.summarize] counts it at:
/// its market value, or what was paid when the bottle has no market price.
/// Rows worth nothing are left out.
class PortfolioBreakdown {
  const PortfolioBreakdown._();

  /// Label for a bottle whose type or brand the catalog doesn't record.
  static const String unspecified = 'Unspecified';

  /// The largest [maxSlices] groups, biggest first, then one "Other" slice
  /// for the rest when there is more than one group left over.
  static List<PortfolioSlice> of(
    Iterable<CollectionItemModel> items, {
    required PortfolioGrouping by,
    int maxSlices = 5,
  }) {
    // Grouped case-insensitively; the first spelling seen is the label.
    final labels = <String, String>{};
    final values = <String, double>{};
    final bottles = <String, int>{};
    var total = 0.0;

    for (final item in items) {
      final value = valueOf(item);
      if (value <= 0) continue;
      final label = _labelOf(item, by);
      final key = label.toLowerCase();
      labels.putIfAbsent(key, () => label);
      values[key] = (values[key] ?? 0) + value;
      bottles[key] = (bottles[key] ?? 0) + item.displayQuantity;
      total += value;
    }
    if (total <= 0) return const [];

    final keys = values.keys.toList()
      ..sort((a, b) {
        // Ties sort by name, so the order is stable.
        final byValue = values[b]!.compareTo(values[a]!);
        if (byValue != 0) return byValue;
        return labels[a]!.compareTo(labels[b]!);
      });

    // One leftover group is shown by name rather than as "Other".
    final shown = keys.length <= maxSlices + 1
        ? keys
        : keys.take(maxSlices).toList();
    final rest = keys.skip(shown.length);

    return [
      for (final k in shown)
        PortfolioSlice(
          label: labels[k]!,
          value: values[k]!,
          share: values[k]! / total,
          bottles: bottles[k]!,
        ),
      if (rest.isNotEmpty)
        PortfolioSlice(
          label: 'Other',
          value: rest.fold(0.0, (sum, k) => sum + values[k]!),
          share: rest.fold(0.0, (sum, k) => sum + values[k]!) / total,
          bottles: rest.fold(0, (sum, k) => sum + bottles[k]!),
          isOther: true,
        ),
    ];
  }

  /// What a row counts for: market value, else what was paid.
  static double valueOf(CollectionItemModel item) =>
      item.marketTotalValue ?? item.paidTotalValue;

  /// One bottle's price: its market average, else what was paid for one.
  static double unitValueOf(CollectionItemModel item) =>
      item.marketAverageValue ?? double.tryParse(item.pricePaid ?? '') ?? 0;

  /// The [limit] priciest bottles by [unitValueOf], one row per bottle.
  static List<CollectionItemModel> topPriced(
    Iterable<CollectionItemModel> items, {
    int limit = 3,
  }) {
    final priced = [
      for (final item in items)
        if (unitValueOf(item) > 0) item,
    ]..sort((a, b) => unitValueOf(b).compareTo(unitValueOf(a)));
    return priced.take(limit).toList(growable: false);
  }

  static String _labelOf(CollectionItemModel item, PortfolioGrouping by) {
    final d = item.details;
    final raw = switch (by) {
      PortfolioGrouping.type => d.spiritType,
      PortfolioGrouping.brand => d.brand ?? d.distillery,
    };
    final text = raw?.trim();
    return text == null || text.isEmpty ? unspecified : text;
  }
}
