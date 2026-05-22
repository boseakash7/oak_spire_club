import 'proof_json.dart';

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
    };
  }
}

