import 'proof_json.dart';

/// One physical bottle: a single `collection/all` row. A [CollectionItemModel]
/// merges the rows of one bluebook bottle and keeps them here so each can be
/// shown and changed on its own.
class OwnedBottle {
  const OwnedBottle({
    required this.id,
    required this.fill,
    this.pricePaid,
    this.createdAt,
    this.dateAcquired,
  });

  final String id;

  /// 1-100. Under 100 the bottle counts as opened.
  final int fill;
  final double? pricePaid;

  /// Unix seconds as the server stores them. Bottles from one add share it.
  final int? createdAt;

  /// The purchase date the user gave (`yyyy-MM-dd`), or null.
  final String? dateAcquired;

  bool get isOpened => fill < 100;

  /// The local day the bottle was bought: [dateAcquired] when set, else the
  /// day it was added.
  DateTime? get purchasedOn {
    final raw = dateAcquired?.trim();
    if (raw != null && raw.isNotEmpty && raw != 'null') {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    final at = createdAt;
    if (at == null) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(at * 1000);
    return DateTime(t.year, t.month, t.day);
  }

  /// [day] as the server stores [dateAcquired].
  static String formatPurchaseDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  OwnedBottle copyWith({int? fill, double? pricePaid, DateTime? purchasedOn}) =>
      OwnedBottle(
        id: id,
        fill: fill ?? this.fill,
        pricePaid: pricePaid ?? this.pricePaid,
        createdAt: createdAt,
        dateAcquired: purchasedOn == null
            ? dateAcquired
            : formatPurchaseDate(purchasedOn),
      );

  factory OwnedBottle.fromJson(Map<String, dynamic> json) {
    final fill = double.tryParse(json['fill']?.toString() ?? '');
    final date = json['date_acquired']?.toString();
    return OwnedBottle(
      id: json['id'].toString(),
      fill: fill == null ? 100 : fill.round().clamp(1, 100),
      pricePaid: double.tryParse(json['price_paid']?.toString() ?? ''),
      createdAt: int.tryParse(json['created_at']?.toString() ?? ''),
      dateAcquired: date == null || date == 'null' ? null : date,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fill': fill,
    'price_paid': pricePaid,
    'created_at': createdAt,
    'date_acquired': dateAcquired,
  };
}

class CollectionItemModel {
  CollectionItemModel({
    required this.id,
    required this.type,
    required this.createdAt,
    this.quantity,
    this.fill,
    this.image,
    this.proof,
    this.pricePaid,
    this.notes,
    this.dateAcquired,
    this.bluebook,
    this.priceMovement,
    this.openedQuantity,
    this.bottles,
  });

  final String id;
  final String? type;
  final String? createdAt;
  final String? quantity;
  final String? fill;

  /// Best-effort bottle art URL/path from API or nested `bluebook` (bourboneur CMS).
  final String? image;

  /// Proof / ABV from root or nested `bluebook`.
  final String? proof;
  final String? pricePaid;
  final String? notes;
  final String? dateAcquired;
  final Map<String, dynamic>? bluebook;

  /// From root or nested `bluebook` (`price_movement`).
  final String? priceMovement;

  /// Opened bottles in a row merged from several collection rows (see
  /// `CollectionRepository.groupItems`); null on a single row,
  /// whose fill says it.
  final int? openedQuantity;

  /// Every bottle behind this item, one per server row, in the order the
  /// server sent them. Null on an item cached by an older build.
  final List<OwnedBottle>? bottles;

  static const List<String> _imageKeys = [
    'image',
    'image_url',
    'img',
    'thumbnail',
    'thumb',
    'photo',
    'picture',
    'bottle_image',
    'bottle_image_url',
    'url',
  ];

  static String? _firstImageInMap(Map<String, dynamic> map) {
    for (final k in _imageKeys) {
      final v = map[k]?.toString().trim();
      if (v != null && v.isNotEmpty && v != 'null') return v;
    }
    return null;
  }

  static String? _coalescePriceMovement(
    Map<String, dynamic> json,
    Map<String, dynamic>? bluebook,
  ) {
    final root = json['price_movement']?.toString().trim();
    if (root != null && root.isNotEmpty && root != 'null') return root;
    if (bluebook != null) {
      final fromBb = bluebook['price_movement']?.toString().trim();
      if (fromBb != null && fromBb.isNotEmpty && fromBb != 'null') {
        return fromBb;
      }
    }
    return null;
  }

  static String? _coalesceImagePath(
    Map<String, dynamic> json,
    Map<String, dynamic>? bluebook,
  ) {
    final root = _firstImageInMap(json);
    if (root != null) return root;
    if (bluebook != null) {
      final fromBb = _firstImageInMap(bluebook);
      if (fromBb != null) return fromBb;
      final product = bluebook['product'];
      if (product is Map) {
        final p = _firstImageInMap(Map<String, dynamic>.from(product));
        if (p != null) return p;
      }
    }
    return null;
  }

  factory CollectionItemModel.fromJson(Map<String, dynamic> json) {
    final bluebook = json['bluebook'] is Map
        ? Map<String, dynamic>.from(json['bluebook'] as Map)
        : null;
    return CollectionItemModel(
      id: json['id'].toString(),
      type: json['type']?.toString(),
      createdAt: json['created_at']?.toString(),
      quantity: json['quantity']?.toString(),
      fill: json['fill']?.toString(),
      image: _coalesceImagePath(json, bluebook),
      proof: ProofJson.coalesce(json, bluebook: bluebook),
      pricePaid: json['price_paid']?.toString(),
      notes: json['notes']?.toString(),
      dateAcquired: json['date_acquired']?.toString(),
      bluebook: bluebook,
      priceMovement: _coalescePriceMovement(json, bluebook),
      openedQuantity: int.tryParse(json['opened_quantity']?.toString() ?? ''),
      bottles: json['bottles'] is List
          ? (json['bottles'] as List)
                .whereType<Map>()
                .map((e) => OwnedBottle.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'created_at': createdAt,
      'quantity': quantity,
      'fill': fill,
      'image': image,
      'proof': proof,
      'price_paid': pricePaid,
      'notes': notes,
      'date_acquired': dateAcquired,
      'bluebook': bluebook,
      'price_movement': priceMovement,
      'opened_quantity': openedQuantity,
      'bottles': bottles?.map((b) => b.toJson()).toList(),
    };
  }
}
