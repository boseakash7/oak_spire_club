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

  Future<Map<String, dynamic>> add({
    required String bottleId,
    required String userId,
    CollectionType type = CollectionType.normal,
    int quantity = 1,
    int fill = 100,
    double pricePaid = 0,
    File? imageFile,
    String? image,
  }) async {
    final body = <String, dynamic>{
      'bottle_id': bottleId,
      'user_id': userId,
      'type': type.name,
      'quantity': quantity,
      'fill': fill,
      'price_paid': pricePaid,
    };

    final form = FormData(body);
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split(Platform.pathSeparator).last;
      form.files.add(
        MapEntry('image', MultipartFile(bytes, filename: filename)),
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
    if (data is! Map) throw ApiException('Unexpected server response.');
    return Map<String, dynamic>.from(data);
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

  /// Returns the raw chart-data payload. Reference app expects:
  /// { data: [...], first_price: "...", last_price: "..." }
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
