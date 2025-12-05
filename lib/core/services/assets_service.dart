import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AssetsService {
  /// Returns list of raw maps (you can map them where used)
  static Future<List<Map<String, dynamic>>> fetchAssets({int limit = 200}) async {
    final base = await ApiClient.getBaseUrl();
    final safe = base.endsWith('/') ? '${base}assets?limit=$limit' : '$base/assets?limit=$limit';
    final uri = Uri.parse(safe);
    final headers = await ApiClient.getHeaders();
    final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is List) {
        return List<Map<String, dynamic>>.from(body);
      }
      if (body is Map && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      return [];
    } else {
      throw Exception('Failed to load assets: ${res.statusCode}');
    }
  }
}