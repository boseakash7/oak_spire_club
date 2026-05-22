import 'dart:convert';

import 'package:get/get.dart';

import '../constants/app_constants.dart';
import 'api_exception.dart';

class ApiClient extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConstants.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 60);
    super.onInit();
  }

  /// Matches the legacy API shape:
  /// - HTTP 200 with JSON: { code: "OK" | "ERROR", data: ... }
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await post(path, FormData(body));

    if (response.statusCode != 200) {
      throw ApiException('Internal server error.');
    }

    dynamic json = response.body;
    if (json is String) {
      try {
        json = jsonDecode(json);
      } catch (_) {
        throw ApiException('Unexpected server response.');
      }
    }

    if (json is! Map) {
      throw ApiException('Unexpected server response.');
    }

    final code = json['code']?.toString();
    if (code != 'OK') {
      throw ApiException(json['data']?.toString() ?? 'Something went wrong.');
    }

    return Map<String, dynamic>.from(json);
  }
}
