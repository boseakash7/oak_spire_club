import 'bluebook_model.dart';

/// A bottle on the user's wishlist (`wishlist/all`): the bottle as the market
/// list sends it, the average on the day it was added, and an optional target.
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.bottle,
    required this.raw,
    this.addedPrice,
    this.targetPrice,
    this.note,
    this.createdAt,
  });

  final String id;
  final BluebookModel bottle;

  /// The bottle's average when it was added; null when it had none.
  final double? addedPrice;
  final double? targetPrice;
  final String? note;
  final DateTime? createdAt;

  /// The row as the server sent it, kept for the cache.
  final Map<String, dynamic> raw;

  String get bottleId => bottle.id;

  /// Within this much above the target counts as "close".
  static const double nearTargetPercent = 10;

  static WishlistItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final bottle = map['bluebook'];
    if (bottle is! Map) return null;
    final seconds = int.tryParse('${map['created_at']}');
    final note = map['note']?.toString().trim();
    return WishlistItem(
      id: '${map['id']}',
      bottle: BluebookModel.fromJson(Map<String, dynamic>.from(bottle)),
      raw: map,
      addedPrice: _price(map['added_price']),
      targetPrice: _price(map['target_price']),
      note: note == null || note.isEmpty || note == 'null' ? null : note,
      createdAt: seconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
    );
  }

  Map<String, dynamic> toJson() => raw;

  /// Today's market average; null when the bottle has no price.
  double? get currentPrice => _price(bottle.average);

  /// Percent move from [addedPrice] to [currentPrice].
  double? get changeSinceAdded {
    final from = addedPrice, now = currentPrice;
    if (from == null || now == null) return null;
    return (now - from) / from * 100;
  }

  /// The market average is at or under the target.
  bool get atTarget {
    final target = targetPrice, now = currentPrice;
    return target != null && now != null && now <= target;
  }

  /// How far the price sits above the target, in percent; null at or under
  /// it, or without both prices.
  double? get aboveTargetPercent {
    final target = targetPrice, now = currentPrice;
    if (target == null || now == null || now <= target) return null;
    return (now - target) / target * 100;
  }

  bool get nearTarget {
    final above = aboveTargetPercent;
    return above != null && above <= nearTargetPercent;
  }

  static double? _price(Object? raw) {
    final v = double.tryParse('${raw ?? ''}');
    return v != null && v > 0 ? v : null;
  }
}
