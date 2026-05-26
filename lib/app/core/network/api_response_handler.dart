import 'dart:convert';

import 'package:get/get.dart';

import '../../routes/subscription_limit_navigation.dart';
import 'api_exception.dart';
import 'api_flags.dart';
import 'limit_exceeded_exception.dart';

/// Shared parsing for `{ code, data }` API responses.
abstract final class ApiResponseHandler {
  static dynamic decodeBody(dynamic body) {
    if (body is String) {
      try {
        return jsonDecode(body);
      } catch (_) {
        throw ApiException('Unexpected server response.');
      }
    }
    return body;
  }

  static Map<String, dynamic> decodeMapResponse(Response<dynamic> response) {
    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    final json = decodeBody(response.body);
    if (json is! Map) {
      throw ApiException('Unexpected server response.');
    }
    return Map<String, dynamic>.from(json);
  }

  /// Throws when `code` is not `OK`. Handles [ApiFlags.limitExceeded] globally.
  static void ensureOk(Map<String, dynamic> json) {
    final code = json['code']?.toString();
    if (code == 'OK') return;

    final data = json['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final flag = map['flag']?.toString();
      if (flag == ApiFlags.limitExceeded) {
        final message = map['message']?.toString() ?? '';
        SubscriptionLimitNavigation.open(message);
        throw LimitExceededException(
          message.trim().isNotEmpty
              ? message.trim()
              : 'You have reached your free collection limit.',
        );
      }

      final message = map['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        throw ApiException(message.trim());
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      throw ApiException(data.trim());
    }

    throw ApiException('Something went wrong.');
  }

  static Map<String, dynamic> parseResponse(Response<dynamic> response) {
    final json = decodeMapResponse(response);
    ensureOk(json);
    return json;
  }
}
