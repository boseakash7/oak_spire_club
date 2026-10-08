import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// `wishlist/*` (oakspireweb `Api\Wishlist`). Rows are returned raw; the
/// repository parses them.
class WishlistRemoteDataSource {
  WishlistRemoteDataSource(this._client);
  final ApiClient _client;

  static const String _all = 'wishlist/all';
  static const String _save = 'wishlist/save';
  static const String _remove = 'wishlist/remove';

  Future<List<dynamic>> all({required String userId}) async {
    final response = await _client.get(_all, query: {'user_id': userId});
    final data = _client.parseEnvelope(response)['data'];
    if (data is! List) throw ApiException('Unexpected server response.');
    return data;
  }

  /// Adds the bottle, or updates its target and note. A null [targetPrice]
  /// clears the target.
  Future<Map<String, dynamic>> save({
    required String userId,
    required String bottleId,
    double? targetPrice,
    String? note,
  }) async {
    final json = await _client.postJson(_save, {
      'user_id': userId,
      'bottle_id': bottleId,
      'target_price': targetPrice == null ? '' : targetPrice.toStringAsFixed(2),
      'note': note ?? '',
    });
    final data = json['data'];
    if (data is! Map) throw ApiException('Unexpected server response.');
    return Map<String, dynamic>.from(data);
  }

  Future<void> remove({required String userId, required String bottleId}) =>
      _client.postJson(_remove, {'user_id': userId, 'bottle_id': bottleId});
}
