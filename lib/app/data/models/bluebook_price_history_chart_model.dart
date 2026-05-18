import 'bluebook_model.dart';

/// One `{ date, price, price_movement }` entry from chart dashboard `prices[]`.
class BluebookPriceChartPoint {
  const BluebookPriceChartPoint({
    required this.date,
    required this.price,
    this.priceMovement,
    this.bsmi,
  });

  final DateTime date;
  final double price;
  final String? priceMovement;
  /// Optional BSMI value for this date when API provides `bsmi`.
  final double? bsmi;

  factory BluebookPriceChartPoint.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date']?.toString();
    DateTime date;
    if (dateRaw != null && dateRaw.isNotEmpty) {
      date = DateTime.tryParse(dateRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      date = DateTime.fromMillisecondsSinceEpoch(0);
    }
    final priceRaw = json['price']?.toString().trim() ?? '';
    final price = double.tryParse(priceRaw.replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0;
    final pm = json['price_movement']?.toString().trim();
    final bsmiRaw = json['bsmi']?.toString().trim();
    final bsmi = double.tryParse((bsmiRaw ?? '').replaceAll(RegExp(r'[^\d.-]'), ''));
    return BluebookPriceChartPoint(
      date: date,
      price: price,
      priceMovement: (pm == null || pm.isEmpty || pm == 'null') ? null : pm,
      bsmi: bsmi,
    );
  }
}

/// One row in `data.data[]` from `chart-data-dashboard`.
class BluebookPriceHistoryDashboardRow {
  const BluebookPriceHistoryDashboardRow({
    required this.id,
    this.bluebook,
    required this.prices,
  });

  final String id;
  final BluebookModel? bluebook;
  final List<BluebookPriceChartPoint> prices;

  factory BluebookPriceHistoryDashboardRow.fromJson(Map<String, dynamic> json) {
    final bbRaw = json['bluebook'];
    BluebookModel? bb;
    if (bbRaw is Map) {
      bb = BluebookModel.fromJson(Map<String, dynamic>.from(bbRaw));
    }
    final pricesRaw = json['prices'];
    final prices = <BluebookPriceChartPoint>[];
    if (pricesRaw is List) {
      for (final e in pricesRaw) {
        if (e is Map) {
          prices.add(BluebookPriceChartPoint.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return BluebookPriceHistoryDashboardRow(
      id: json['id']?.toString() ?? '',
      bluebook: bb,
      prices: prices,
    );
  }

  /// Points sorted by date ascending (for chart X order).
  List<BluebookPriceChartPoint> get sortedPrices {
    final copy = [...prices];
    copy.sort((a, b) => a.date.compareTo(b.date));
    return copy;
  }
}
