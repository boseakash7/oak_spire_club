/// Where an asking price sits against a bottle's market price.
enum DealVerdict {
  /// Under the recent low.
  belowLow,

  /// At least [DealCheck.fairBandPercent] under the average.
  good,

  /// Within [DealCheck.fairBandPercent] of the average.
  fair,

  /// More than [DealCheck.fairBandPercent] over the average, up to the high.
  aboveAverage,

  /// Over the recent high.
  aboveHigh;

  /// Short headline. Describes the price, never advises ("Buy").
  String get title => switch (this) {
    DealVerdict.belowLow => 'Below the recent low',
    DealVerdict.good => 'Good price',
    DealVerdict.fair => 'Fair price',
    DealVerdict.aboveAverage => 'Above average',
    DealVerdict.aboveHigh => 'Above the recent high',
  };

  bool get isFavourable =>
      this == DealVerdict.belowLow || this == DealVerdict.good;

  bool get isUnfavourable =>
      this == DealVerdict.aboveAverage || this == DealVerdict.aboveHigh;
}

/// The deal check on bottle detail: an asking price placed against the
/// bottle's average, low and high. Pure, so it is unit tested.
class DealCheck {
  const DealCheck._({
    required this.asking,
    required this.average,
    required this.low,
    required this.high,
    required this.verdict,
    required this.diffPercent,
    required this.position,
  });

  /// How close to the average still counts as "fair", in percent.
  static const double fairBandPercent = 5;

  final double asking;
  final double average;

  /// Null when the API gave no usable low / high.
  final double? low;
  final double? high;

  final DealVerdict verdict;

  /// Asking against average, signed: -11 means 11% under.
  final double diffPercent;

  /// Asking along the low–high bar, 0..1 (clamped). Null without a range.
  final double? position;

  /// Null when there is nothing to compare: no asking price or no average.
  static DealCheck? evaluate({
    required double? asking,
    required double? average,
    double? low,
    double? high,
  }) {
    if (asking == null || asking <= 0) return null;
    if (average == null || average <= 0) return null;

    // A range is only usable when both ends are real and in order.
    final hasRange = low != null && high != null && low > 0 && high >= low;
    final lo = hasRange ? low : null;
    final hi = hasRange ? high : null;

    final diff = (asking - average) / average * 100;
    final DealVerdict verdict;
    if (lo != null && asking < lo) {
      verdict = DealVerdict.belowLow;
    } else if (hi != null && asking > hi) {
      verdict = DealVerdict.aboveHigh;
    } else if (diff <= -fairBandPercent) {
      verdict = DealVerdict.good;
    } else if (diff < fairBandPercent) {
      verdict = DealVerdict.fair;
    } else {
      verdict = DealVerdict.aboveAverage;
    }

    double? position;
    if (lo != null && hi != null && hi > lo) {
      position = ((asking - lo) / (hi - lo)).clamp(0.0, 1.0);
    }

    return DealCheck._(
      asking: asking,
      average: average,
      low: lo,
      high: hi,
      verdict: verdict,
      diffPercent: diff,
      position: position,
    );
  }

  /// "11% under the market average", "At the market average",
  /// "8% over the market average".
  String get comparisonLabel {
    final pct = diffPercent.abs().round();
    if (pct == 0) return 'At the market average';
    return diffPercent < 0
        ? '$pct% under the market average'
        : '$pct% over the market average';
  }

  /// Where the average sits on the low–high bar, 0..1, or null.
  double? get averagePosition {
    final lo = low, hi = high;
    if (lo == null || hi == null || hi <= lo) return null;
    return ((average - lo) / (hi - lo)).clamp(0.0, 1.0);
  }
}
