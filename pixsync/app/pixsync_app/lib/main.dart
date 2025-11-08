import 'package:flutter/material.dart';
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const PixSyncApp());
}

Future<Widget> getStartScreen() async {
  final prefs = await SharedPreferences.getInstance();

  final seenWelcome = prefs.getBool('seenWelcome') ?? false;
  final token = prefs.getString('accessToken');
  final serverIp = prefs.getString('serverIp');
/*
  if (serverIp == null || serverIp.isEmpty) {
    return const ServerSetupScreen();
  }
*/
  if (!seenWelcome) {
    return const WelcomeScreen();
  }

  if (token != null && token.isNotEmpty) {
    return const HomeScreen();
  }

  return const LoginScreen();
}