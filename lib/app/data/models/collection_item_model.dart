class CollectionItemModel {
  CollectionItemModel({
    required this.id,
    required this.type,
    required this.createdAt,
    this.fill,
    this.image,
    this.proof,
    this.pricePaid,
    this.bluebook,
  });

  final String id;
  final String? type;
  final String? createdAt;
  final String? fill;
  /// Best-effort bottle art URL/path from API or nested `bluebook` (bourboneur CMS).
  final String? image;
  /// Proof / ABV from root or `bluebook` (e.g. `Proof 45` in UI).
  final String? proof;
  final String? pricePaid;
  final Map<String, dynamic>? bluebook;

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

  static const List<String> _proofKeys = [
    'proof',
    'bottle_proof',
    'alcohol_proof',
    'abv',
    'proof_value',
    'strength',
    'alcohol',
  ];

  static String? _firstProofInMap(Map<String, dynamic> map) {
    for (final k in _proofKeys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  static String? _coalesceProof(
    Map<String, dynamic> json,
    Map<String, dynamic>? bluebook,
  ) {
    final root = _firstProofInMap(json);
    if (root != null) return root;
    if (bluebook != null) {
      final fromBb = _firstProofInMap(bluebook);
      if (fromBb != null) return fromBb;
      final product = bluebook['product'];
      if (product is Map) {
        return _firstProofInMap(Map<String, dynamic>.from(product));
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
      fill: json['fill']?.toString(),
      image: _coalesceImagePath(json, bluebook),
      proof: _coalesceProof(json, bluebook),
      pricePaid: json['price_paid']?.toString(),
      bluebook: bluebook,
    );
  }
}

