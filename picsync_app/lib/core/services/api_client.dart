import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('serverUrl') ?? 'http://127.0.0.1:8080';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {int timeoutSeconds = 10}) async {
    final baseUrl = await getBaseUrl();
    final safePath = path.startsWith('/') ? path : '/$path';
    final url = Uri.parse('$baseUrl$safePath');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(Duration(seconds: timeoutSeconds));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Request failed (${response.statusCode}): ${response.body}');
    }
  }

  static Future<bool> testConnection(Uri url) async {
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}