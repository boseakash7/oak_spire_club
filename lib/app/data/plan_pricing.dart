/// Figures the subscription screen derives from the plans' prices.
class PlanPricing {
  const PlanPricing._();

  /// How much less a year of [yearly] costs than twelve months of [monthly],
  /// as a whole percent. Null when either price is missing or it isn't a
  /// saving.
  static int? yearlySavingPercent({double? monthly, double? yearly}) {
    if (monthly == null || yearly == null || monthly <= 0 || yearly <= 0) {
      return null;
    }
    final pct = ((1 - yearly / (monthly * 12)) * 100).round();
    return pct > 0 ? pct : null;
  }

  /// A yearly price spread over twelve months.
  static double perMonth(double yearly) => yearly / 12;

  /// `25` → `25`, `2.0833` → `2.08`.
  static String amount(double value) {
    final cents = (value * 100).round();
    if (cents % 100 == 0) return '${cents ~/ 100}';
    return (cents / 100).toStringAsFixed(2);
  }
}
