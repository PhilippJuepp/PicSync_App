import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'gen_l10n/app_localizations.dart';
import 'features/onboarding/welcome_screen.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'main.dart';

class PixSyncApp extends StatelessWidget {
  const PixSyncApp({super.key});

Future<Widget> _getStartScreen() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');
  final seenWelcome = prefs.getBool('seenWelcome') ?? false;

  if (!seenWelcome) {
    return const WelcomeScreen();
  } else if (token != null && token.isNotEmpty) {
    return const HomeScreen();
  } else {
    return const LoginScreen();
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixSync',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: FutureBuilder<Widget>(
        future: getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}