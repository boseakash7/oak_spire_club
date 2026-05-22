import 'dart:io';

import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/collection_item_model.dart';

enum CollectionType { wishlist, normal }

class CollectionRemoteDataSource {
  CollectionRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _all = 'collection/all';
  static const String _chartData = 'collection/chart-data';
  static const String _add = 'collection/add';
  static const String _deleteByUserBottle = 'collection/delete-by-user-bottle';

  Future<Map<String, dynamic>> add({
    required String bottleId,
    required String userId,
    CollectionType type = CollectionType.normal,
    int quantity = 1,
    int fill = 100,
    double pricePaid = 0,
    String? notes,
    String? dateAcquired,
    File? imageFile,
    String? image,
  }) async {
    final fields = <String, String>{
      'bottle_id': bottleId,
      'user_id': userId,
      'type': type.name,
      'quantity': quantity.toString(),
      'fill': fill.toString(),
      'price_paid': pricePaid.toString(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (dateAcquired != null && dateAcquired.trim().isNotEmpty)
        'date_acquired': dateAcquired.trim(),
    };

    final form = FormData(fields);
    if (imageFile != null) {
      if (!await imageFile.exists()) {
        throw ApiException('Selected image file is missing.');
      }
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw ApiException('Selected image file is empty.');
      }
      final filename = imageFile.path.split(Platform.pathSeparator).last;
      form.files.add(
        MapEntry(
          'image',
          MultipartFile(
            bytes,
            filename: filename.isNotEmpty ? filename : 'bottle_image.jpg',
            contentType: _imageContentType(filename),
          ),
        ),
      );
    } else if (image != null && image.trim().isNotEmpty) {
      form.fields.add(MapEntry('image', image.trim()));
    }

    final response = await _client.post(_add, form);
    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = response.body;
    if (json is! Map) throw ApiException('Unexpected server response.');
    if (json['code']?.toString() != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is List) {
      return <String, dynamic>{'result': data};
    }
    if (data == null) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{'result': data};
  }

  static String _imageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<void> deleteByUserBottle({
    required String bottleId,
    required String userId,
    CollectionType type = CollectionType.normal,
  }) async {
    final json = await _client.postJson(_deleteByUserBottle, {
      'bottle_id': bottleId,
      'user_id': userId,
      'type': type.name,
    });
    final data = json['data'];
    if (data == null) return;
  }

  Future<List<CollectionItemModel>> all({
    required String userId,
    CollectionType type = CollectionType.normal,
  }) async {
    final response = await _client.get(
      _all,
      query: {'user_id': userId, 'type': type.name},
    );

    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = response.body;
    if (json is! Map) throw ApiException('Unexpected server response.');
    if (json['code']?.toString() != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    final data = json['data'];
    if (data is! List) throw ApiException('Unexpected server response.');

    return data
        .whereType<Map>()
        .map((e) => CollectionItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns the raw chart-data payload. Expects:
  /// `data` (market value series), `index_data` (BSMI), `first_price`,
  /// `last_price`, `index`, `invested_value`, etc.
  Future<Map<String, dynamic>> chartData({
    required String userId,
    required int lookBackDays,
  }) async {
    final response = await _client.get(
      _chartData,
      query: {'user_id': userId, 'look_back': lookBackDays.toString()},
    );

    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = response.body;
    if (json is! Map) throw ApiException('Unexpected server response.');
    if (json['code']?.toString() != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return Map<String, dynamic>.from(data);
  }
}
