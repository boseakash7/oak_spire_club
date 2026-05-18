import '../../core/constants/app_constants.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/price_formatter.dart';
import 'collection_item_model.dart';

/// CMS static files usually live under `/v2/…`, not under `/v2/api/…`.
Uri _cmsRootUri(Uri apiBase) {
  final segs =
      List<String>.from(apiBase.pathSegments.where((s) => s.isNotEmpty));
  if (segs.isNotEmpty && segs.last.toLowerCase() == 'api') {
    segs.removeLast();
  }
  return Uri(
    scheme: apiBase.scheme,
    host: apiBase.host,
    port: apiBase.hasPort ? apiBase.port : null,
    path: segs.isEmpty ? '/' : '/${segs.join('/')}/',
  );
}

/// Display helpers for `collection/all` items (bourboneur-style payloads).
extension CollectionItemDisplay on CollectionItemModel {
  /// Some CMS responses differ in base-path; return a few candidates and try them in order.
  List<String> get resolvedImageCandidates {
    final raw0 = image?.trim();
    if (raw0 == null || raw0.isEmpty || raw0 == 'null') return const [];

    var raw = raw0;
    if (raw.startsWith('//')) raw = 'https:$raw';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri == null) return const [];

      final out = <String>[raw];
      // If someone accidentally returns `/v2/api/...` as an asset URL, try `/v2/...`.
      final p = uri.path;
      if (p.contains('/v2/api/')) {
        out.add(uri.replace(path: p.replaceFirst('/v2/api/', '/v2/')).toString());
      }
      return out.toSet().toList();
    }

    final api = Uri.parse(AppConstants.apiBaseUrl);
    final cmsRoot = _cmsRootUri(api);
    final uploadUrl = AppStorage.uploadUrl;
    final origin = Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: '/',
    );

    if (raw.startsWith('/')) {
      return [
        Uri(
          scheme: api.scheme,
          host: api.host,
          port: api.hasPort ? api.port : null,
          path: raw,
        ).toString(),
      ];
    }

    final candidates = <String>{
      cmsRoot.resolve(raw).toString(),
      origin.resolve(raw).toString(),
      // Also try under /v2/ explicitly.
      origin.resolve('v2/$raw').toString(),
      if (uploadUrl != null && uploadUrl.trim().isNotEmpty)
        '${uploadUrl.trim().replaceAll(RegExp(r'/+$'), '')}/$raw',
    };

    return candidates.toList();
  }

  /// Absolute URL for bottle art. Handles protocol-relative URLs and paths
  /// relative to the CMS root (same pattern as bourboneur reference app).
  String? get resolvedImageUrl {
    final list = resolvedImageCandidates;
    return list.isEmpty ? null : list.first;
  }

  String? _pickBluebook(List<String> keys) {
    final m = bluebook;
    if (m == null) return null;
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  /// Bluebook bottle id when present (for deduping home “top moved” rows).
  String? get bluebookBottleId {
    final id = bluebook?['id']?.toString().trim();
    if (id != null && id.isNotEmpty && id != 'null') return id;
    return null;
  }

  /// `price_movement` from `collection/all` (root or nested bluebook).
  String? get priceMovementRaw {
    final root = priceMovement?.trim();
    if (root != null && root.isNotEmpty && root != 'null') return root;
    return _pickBluebook(const ['price_movement', 'priceMovement']);
  }

  double? get priceMovementValue =>
      PriceFormatter.parsePriceMovementValue(priceMovementRaw);

  /// Market / bluebook average for display (not user `price_paid`).
  String get marketAverageLabel =>
      PriceFormatter.format(
        _pickBluebook(const ['average', 'avg', 'market_value', 'price']),
      );

  /// Primary line (brand / expression name).
  String get lineTitle =>
      _pickBluebook(const ['name', 'title', 'product_name', 'bottle_name']) ??
      'Unknown bottle';

  /// Secondary line (age, expression, etc.).
  String get lineSubtitle =>
      _pickBluebook(const ['age', 'years', 'year', 'subtitle', 'variant']) ??
      '';

  /// Proof line for collection cards. Falls back until API returns real values.
  static const String _proofPlaceholder = 'Proof 45';

  String get proofLabel {
    final raw = proof?.trim();
    final p = (raw != null && raw.isNotEmpty)
        ? raw
        : _pickBluebook(const [
            'proof',
            'abv',
            'bottle_proof',
            'alcohol_proof',
            'proof_value',
            'strength',
          ]);
    if (p == null || p.isEmpty) return _proofPlaceholder;
    final lower = p.toLowerCase();
    if (lower.contains('proof')) return p;
    return 'Proof $p';
  }

  /// Total paid for this line: unit `price_paid` × bottle `quantity` (default 1 when absent).
  String get priceLabel {
    final unit = double.tryParse(pricePaid ?? '') ?? 0;
    final qtyRaw = int.tryParse(quantity ?? '');
    final normalizedQty = (qtyRaw == null || qtyRaw <= 0) ? 1 : qtyRaw;
    final total = (unit * normalizedQty).round();
    return PriceFormatter.format(total.toString());
  }

  /// How full the bottle is for the gold bar (0–1).
  double get fillRatio {
    final v = double.tryParse(fill ?? '') ?? 0.65;
    if (v <= 1) return v.clamp(0.0, 1.0);
    if (v <= 100) return (v / 100).clamp(0.0, 1.0);
    return 1.0;
  }

  bool get isRareFind {
    final b = bluebook;
    if (b == null) return false;
    final r = b['rare_find'] ?? b['rare'];
    if (r == true || r == 1 || r == '1') return true;
    final t = type?.toLowerCase() ?? '';
    return t == 'rare_find' || t == 'rare';
  }

  bool get isOpenedHeuristic {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('opened') && !t.contains('unopened')) return true;
    if (t == 'consumed' || t == 'empty') return true;
    return fillRatio < 0.995;
  }
}
