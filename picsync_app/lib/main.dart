import 'package:flutter/material.dart';
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/server_conncection/server_connection_screen.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startScreen = await getStartScreen();
  runApp(PicSyncApp(startScreen: startScreen));
}

Future<Widget> getStartScreen() async {
  final prefs = await SharedPreferences.getInstance();
  final serverUrl = prefs.getString('serverUrl');
  final seenWelcome = prefs.getBool('seenWelcome') ?? false;
  final token = prefs.getString('accessToken');

  if (serverUrl == null || serverUrl.isEmpty) {
    return const ServerConnectionScreen();
  }

  final healthy = await _checkServerHealth(serverUrl);
  if (!healthy) {
    return const ServerConnectionScreen();
  }

  if (!seenWelcome) {
    return const WelcomeScreen();
  }

  if (token != null && token.isNotEmpty) {
    return const HomeScreen();
  }

  return const LoginScreen();
}

Future<bool> _checkServerHealth(String base) async {
  try {
    final url = Uri.parse(base.endsWith('/') ? '${base}health' : '$base/health');
    final r = await http.get(url).timeout(const Duration(seconds: 3));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}