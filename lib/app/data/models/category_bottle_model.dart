import '../../core/constants/app_constants.dart';
import '../../core/storage/app_storage.dart';

class CategoryBottleModel {
  CategoryBottleModel({
    required this.id,
    required this.bottleName,
    this.image,
    this.average,
    this.low,
    this.high,
    this.status,
    this.createdAt,
    this.categoryAddedAt,
  });

  final String id;
  final String bottleName;
  final String? image;
  final String? average;
  final String? low;
  final String? high;
  final String? status;
  final String? createdAt;
  final String? categoryAddedAt;

  factory CategoryBottleModel.fromJson(Map<String, dynamic> json) {
    return CategoryBottleModel(
      id: json['id'].toString(),
      bottleName: (json['bottle_name'] ?? '').toString(),
      image: json['image']?.toString(),
      average: json['average']?.toString(),
      low: json['low']?.toString(),
      high: json['high']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      categoryAddedAt: json['category_added_at']?.toString(),
    );
  }

  /// Best-effort bottle image URL using `upload_url` when available.
  String? get resolvedImageUrl {
    final raw0 = image?.trim();
    if (raw0 == null || raw0.isEmpty || raw0 == 'null') return null;

    var raw = raw0;
    if (raw.startsWith('//')) raw = 'https:$raw';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final uploadUrl = AppStorage.uploadUrl;
    if (uploadUrl != null && uploadUrl.trim().isNotEmpty) {
      return '${uploadUrl.trim().replaceAll(RegExp(r'/+$'), '')}/$raw';
    }

    // Fallback: resolve against the same host as API base.
    final api = Uri.parse(AppConstants.apiBaseUrl);
    return Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: raw.startsWith('/') ? raw : '/$raw',
    ).toString();
  }
}

