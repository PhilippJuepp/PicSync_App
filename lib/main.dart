import 'package:flutter/material.dart';
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/server_conncection/server_connection_screen.dart';
import 'core/services/connection_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectionService.instance.start();
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

  if (!seenWelcome) {
    return const WelcomeScreen();
  }

  if (token != null && token.isNotEmpty) {
    return const HomeShell();
  }

  return const LoginScreen();
}