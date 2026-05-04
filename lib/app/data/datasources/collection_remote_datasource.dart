import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/collection_item_model.dart';

enum CollectionType { wishlist, normal }

class CollectionRemoteDataSource {
  CollectionRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _all = 'collection/all';
  static const String _chartData = 'collection/chart-data';

  Future<List<CollectionItemModel>> all({
    required String userId,
    CollectionType type = CollectionType.normal,
  }) async {
    final response = await _client.get(_all, query: {
      'user_id': userId,
      'type': type.name,
    });

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
    final response = await _client.get(_chartData, query: {
      'user_id': userId,
      'look_back': lookBackDays.toString(),
    });

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

