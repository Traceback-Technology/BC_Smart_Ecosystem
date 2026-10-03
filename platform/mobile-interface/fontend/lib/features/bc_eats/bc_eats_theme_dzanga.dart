
import 'package:flutter/material.dart';

// This file keeps the BC Eats light and dark themes in one place.
// The main app can later use these themes so all screens follow the phone's system settings.
class BCEatsTheme {
  // These are the colours we are using for the light version of BC Eats.
  // I kept the red and yellow because they match the branding we have been using.
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color lightCard = Colors.white;
  static const Color lightText = Colors.black;
  static const Color lightSecondaryText = Colors.grey;

  // These colours will be used when the user has dark mode enabled.
  // The background is darker, but the BC Eats branding colours can still stand out.
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  static const Color darkSecondaryText = Color(0xFFBDBDBD);

  // These are shared brand colours for both light and dark mode.
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryYellow = Color(0xFFF4B400);
  static const Color primaryGreen = Color(0xFF00BFA5);

  // This is the light theme used when the device is in light mode.
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,

      scaffoldBackgroundColor: lightBackground,

      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: primaryYellow,
        surface: lightCard,
        onSurface: lightText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: lightText,
        elevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: lightCard,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // This is the dark theme used when the device is in dark mode.
  // The main app can switch to this automatically using ThemeMode.system.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,

      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryYellow,
        surface: darkCard,
        onSurface: darkText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkText,
        elevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkCard,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}