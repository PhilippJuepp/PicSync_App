import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionService with WidgetsBindingObserver {
  ConnectionService._internal();
  static final ConnectionService _instance = ConnectionService._internal();
  static ConnectionService get instance => _instance;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;
  SharedPreferences? _prefs;
  bool _started = false;
  bool _isPaused = false;
  bool _isChecking = false;
  int _consecutiveFailures = 0;

  static const Duration _foregroundInterval = Duration(seconds: 5);
  static const Duration _resumeGrace = Duration(seconds: 2);
  static const int _offlineFailureThreshold = 2;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);
    _prefs = await SharedPreferences.getInstance();

    _scheduleForegroundPolling();
    unawaited(_checkHealth(force: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isPaused = true;
      _timer?.cancel();
      _timer = null;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      _scheduleForegroundPolling();
      Future<void>.delayed(_resumeGrace, () {
        if (!_isPaused) {
          unawaited(_checkHealth(force: true));
        }
      });
    }
  }

  void _scheduleForegroundPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_foregroundInterval, (_) {
      if (!_isPaused) {
        unawaited(_checkHealth());
      }
    });
  }

  Future<void> _checkHealth({bool force = false}) async {
    if (_isChecking && !force) return;
    _isChecking = true;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs ??= prefs;
    final base = prefs.getString('serverUrl');

    if (base == null || base.isEmpty) {
      _updateStatus(false);
      _isChecking = false;
      return;
    }

    try {
      final url = Uri.parse(
          base.endsWith('/') ? '${base}health' : '$base/health'
      );

      final r = await http.get(url).timeout(const Duration(seconds: 3));
      final healthy = r.statusCode == 200;

      if (healthy) {
        _consecutiveFailures = 0;
        _updateStatus(true);
      } else {
        _consecutiveFailures++;
        if (_consecutiveFailures >= _offlineFailureThreshold) {
          _updateStatus(false);
        }
      }
    } catch (_) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= _offlineFailureThreshold) {
        _updateStatus(false);
      }
    } finally {
      _isChecking = false;
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
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
    _started = false;
  }
}