import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('serverUrl') ?? 'http://127.0.0.1:8080';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
  ) async {
    final first = await send();

    if (first.statusCode != 401) {
      return first;
    }

    try {
      await refreshToken();
    } catch (_) {
      await logoutLocally();
      throw ApiException("Unauthorized", statusCode: 401);
    }

    final retry = await send();

    if (retry.statusCode == 401) {
      await logoutLocally();
      throw ApiException("Unauthorized", statusCode: 401);
    }

    return retry;
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    int timeoutSeconds = 10,
  }) async {
    final baseUrl = await getBaseUrl();
    final safePath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$safePath');
    final headers = await getHeaders();

    final response = await _sendWithRetry(() => http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(Duration(seconds: timeoutSeconds)));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty
          ? {}
          : jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      'Request failed: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final baseUrl = await getBaseUrl();
    final safePath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$safePath');
    final headers = await getHeaders();

    final response = await _sendWithRetry(() => http.get(url, headers: headers));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw ApiException(
      'GET failed: ${response.body}',
      statusCode: response.statusCode,
    );
  }

  static Future<bool> testConnection(Uri url) async {
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> postBytes(
    String path, {
    required Map<String, String> query,
    required List<int> body,
    int timeoutSeconds = 20,
  }) async {
    final baseUrl = await getBaseUrl();
    final safePath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$safePath').replace(queryParameters: query);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final headers = {
      'Content-Type': 'application/octet-stream',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _sendWithRetry(() => http
        .post(url, headers: headers, body: body)
        .timeout(Duration(seconds: timeoutSeconds)));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty
          ? {}
          : jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      'Bytes upload failed: ${response.body}',
      statusCode: response.statusCode,
    );
  }


  static Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) throw Exception("No refresh token stored");

    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      await prefs.setString('accessToken', body['access_token']);
      if (body['refresh_token'] != null) {
        await prefs.setString('refreshToken', body['refresh_token']);
      }
    } else {
      throw Exception('Refresh token failed: ${res.body}');
    }
  }

  static Future<void> logoutLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userEmail');
    await prefs.remove('userId');
  }
}