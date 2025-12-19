import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionService {
  ConnectionService._internal();
  static final ConnectionService _instance = ConnectionService._internal();
  static ConnectionService get instance => _instance;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  Future<void> start() async {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkHealth();
    });

    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final prefs = await SharedPreferences.getInstance();
    final base = prefs.getString('serverUrl');

    if (base == null || base.isEmpty) {
      _updateStatus(false);
      return;
    }

    try {
      final url = Uri.parse(
          base.endsWith('/') ? '${base}health' : '$base/health'
      );

      final r = await http.get(url).timeout(const Duration(seconds: 3));
      final healthy = r.statusCode == 200;

      _updateStatus(healthy);
    } catch (_) {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _controller.add(_isOnline);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}