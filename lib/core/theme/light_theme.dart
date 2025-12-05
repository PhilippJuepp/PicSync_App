import 'package:flutter/material.dart';

class AppColorsLight {
  static const primary = Color(0xFF1A3DA0); // Modern dark blue
  static const navbar = Color(0xFFF3F4F6);  // Subtle visible grey
  static const iconInactive = Color(0xFF6C7280);
}

final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,

  colorScheme: const ColorScheme.light(
    primary: AppColorsLight.primary,
    secondary: Color(0xFF2B63E6),
    surface: AppColorsLight.navbar,
  ),

  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: AppColorsLight.primary),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColorsLight.navbar,
    selectedItemColor: AppColorsLight.primary,
    unselectedItemColor: AppColorsLight.iconInactive,
  ),

  iconTheme: const IconThemeData(color: AppColorsLight.iconInactive),
);