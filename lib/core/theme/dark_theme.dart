import 'package:flutter/material.dart';

class AppColorsDark {
  static const primary = Color(0xFF4D7CFF); // modern electric blue
  static const navbar = Color(0xFF141A26);  // visible dark grey-blue
  static const iconInactive = Color(0xFF9CA3B0);
}

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0F1A),

  colorScheme: const ColorScheme.dark(
    primary: AppColorsDark.primary,
    secondary: AppColorsDark.primary,
    surface: AppColorsDark.navbar,
  ),

  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    iconTheme: IconThemeData(color: AppColorsDark.primary),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColorsDark.navbar,
    selectedItemColor: AppColorsDark.primary,
    unselectedItemColor: AppColorsDark.iconInactive,
  ),

  iconTheme: const IconThemeData(color: AppColorsDark.iconInactive),
);