import 'bluebook_model.dart';

export 'bottle_market_stats.dart';

double? _num(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s == 'null') return null;
  return double.tryParse(s);
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}

List<BluebookModel> _bottles(dynamic v) => v is List
    ? v
          .whereType<Map>()
          .map((e) => BluebookModel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
    : const [];

/// One day of an index.
class MarketIndexPoint {
  const MarketIndexPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// An Oak Spire index: its latest value, how it has moved, and a recent
/// daily series (oakspireweb `MarketIndex::summary`).
class MarketIndexSummary {
  const MarketIndexSummary({
    required this.slug,
    required this.name,
    this.description,
    required this.isHeadline,
    required this.value,
    this.asOf,
    required this.constituents,
    this.change1d,
    this.change30d,
    this.change90d,
    this.change365d,
    required this.stale,
    required this.series,
  });

  final String slug;
  final String name;
  final String? description;
  final bool isHeadline;
  final double value;
  final DateTime? asOf;

  /// Bottles in the index on [asOf].
  final int constituents;
  final double? change1d;
  final double? change30d;
  final double? change90d;
  final double? change365d;

  /// The nightly job has not run for over two days.
  final bool stale;
  final List<MarketIndexPoint> series;

  /// The change over [days] (1, 30, 90 or 365), or null.
  double? changeOver(int days) => switch (days) {
    1 => change1d,
    30 => change30d,
    90 => change90d,
    365 => change365d,
    _ => null,
  };

  static MarketIndexSummary? fromJson(dynamic json) {
    if (json is! Map) return null;
    final slug = _str(json['slug']);
    final value = _num(json['value']);
    if (slug == null || value == null) return null;
    final rawSeries = json['series'];
    return MarketIndexSummary(
      slug: slug,
      name: _str(json['name']) ?? slug,
      description: _str(json['description']),
      isHeadline: json['is_headline'] == true || json['is_headline'] == 1,
      value: value,
      asOf: DateTime.tryParse(_str(json['as_of']) ?? ''),
      constituents: _num(json['constituents'])?.round() ?? 0,
      change1d: _num(json['change_1d']),
      change30d: _num(json['change_30d']),
      change90d: _num(json['change_90d']),
      change365d: _num(json['change_365d']),
      stale: json['stale'] == true,
      series: [
        if (rawSeries is List)
          for (final p in rawSeries.whereType<Map>())
            if (DateTime.tryParse(_str(p['d']) ?? '') != null &&
                _num(p['v']) != null)
              MarketIndexPoint(
                DateTime.parse(p['d'].toString()),
                _num(p['v'])!,
              ),
      ],
    );
  }
}

/// `market/overview`: the headline index and the biggest movers.
class MarketOverview {
  const MarketOverview({
    this.index,
    required this.gainers,
    required this.losers,
    required this.windowDays,
    this.lastUpdated,
  });

  final MarketIndexSummary? index;
  final List<BluebookModel> gainers;
  final List<BluebookModel> losers;

  /// The window the movers cover, in days.
  final int windowDays;

  /// "10.05.2026", or null.
  final String? lastUpdated;

  bool get isEmpty => index == null && gainers.isEmpty && losers.isEmpty;

  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    final updated = json['last_updated'];
    return MarketOverview(
      index: MarketIndexSummary.fromJson(json['index']),
      gainers: _bottles(json['gainers']),
      losers: _bottles(json['losers']),
      windowDays: _num(json['window_days'])?.round() ?? 30,
      lastUpdated: updated is Map ? _str(updated['readable']) : null,
    );
  }
}

/// `market/index-detail`: one index in depth.
class MarketIndexDetail {
  const MarketIndexDetail({
    this.index,
    required this.days,
    required this.contributorsWindowDays,
    required this.risers,
    required this.fallers,
    required this.methodology,
  });

  final MarketIndexSummary? index;
  final int days;
  final int contributorsWindowDays;
  final List<BluebookModel> risers;
  final List<BluebookModel> fallers;

  /// Plain-language paragraphs on how the index is built.
  final List<String> methodology;

  factory MarketIndexDetail.fromJson(Map<String, dynamic> json) {
    final m = json['methodology'];
    return MarketIndexDetail(
      index: MarketIndexSummary.fromJson(json['index']),
      days: _num(json['days'])?.round() ?? 90,
      contributorsWindowDays:
          _num(json['contributors_window_days'])?.round() ?? 30,
      risers: _bottles(json['risers']),
      fallers: _bottles(json['fallers']),
      methodology: [
        if (m is List)
          for (final p in m)
            if (_str(p) != null) _str(p)!,
      ],
    );
  }
}

/// A bottle in one of `market/highlights`' lists, with the community figure
/// the list is about. Fields that don't apply to the list are null.
class HighlightBottle {
  const HighlightBottle({
    required this.bottle,
    this.collectors,
    this.added30d,
    this.firstPricedOn,
  });

  final BluebookModel bottle;

  /// Distinct collectors who hold it (Most collected, Top rated).
  final int? collectors;

  /// Distinct collectors who added it in the last 30 days (Hot).
  final int? added30d;

  /// The day of its first recorded price (New to the market).
  final DateTime? firstPricedOn;

  static List<HighlightBottle> listFrom(dynamic v) => [
    if (v is List)
      for (final e in v.whereType<Map>())
        HighlightBottle._fromJson(Map<String, dynamic>.from(e)),
  ];

  factory HighlightBottle._fromJson(Map<String, dynamic> json) {
    final c = json['community'];
    final community = c is Map ? c : const {};
    return HighlightBottle(
      bottle: BluebookModel.fromJson(json),
      collectors: _num(community['collectors'])?.round(),
      added30d: _num(community['added_30d'])?.round(),
      firstPricedOn: DateTime.tryParse(
        _str(community['first_priced_on']) ?? '',
      ),
    );
  }
}

/// `market/highlights`: the Home tab's market breadth and community lists.
class MarketHighlights {
  const MarketHighlights({
    required this.windowDays,
    required this.rising,
    required this.falling,
    required this.flat,
    required this.hot,
    required this.newlyPriced,
    required this.mostCollected,
    required this.topRated,
  });

  static const empty = MarketHighlights(
    windowDays: 30,
    rising: 0,
    falling: 0,
    flat: 0,
    hot: [],
    newlyPriced: [],
    mostCollected: [],
    topRated: [],
  );

  /// The window [rising] / [falling] / [flat] cover, in days.
  final int windowDays;

  /// Market bottles that rose, fell or held over [windowDays].
  final int rising;
  final int falling;
  final int flat;

  /// Most added to collections in the last 30 days.
  final List<HighlightBottle> hot;

  /// First priced in the last 30 days.
  final List<HighlightBottle> newlyPriced;

  /// Held by the most collectors.
  final List<HighlightBottle> mostCollected;

  /// The highest-rated bottles collectors hold.
  final List<HighlightBottle> topRated;

  bool get hasBreadth => rising + falling + flat > 0;

  factory MarketHighlights.fromJson(Map<String, dynamic> json) {
    final b = json['breadth'];
    final breadth = b is Map ? b : const {};
    return MarketHighlights(
      windowDays: _num(breadth['window_days'])?.round() ?? 30,
      rising: _num(breadth['up'])?.round() ?? 0,
      falling: _num(breadth['down'])?.round() ?? 0,
      flat: _num(breadth['flat'])?.round() ?? 0,
      hot: HighlightBottle.listFrom(json['hot']),
      newlyPriced: HighlightBottle.listFrom(json['new']),
      mostCollected: HighlightBottle.listFrom(json['most_collected']),
      topRated: HighlightBottle.listFrom(json['top_rated']),
    );
  }
}
