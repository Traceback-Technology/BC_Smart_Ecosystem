
import 'package:flutter/material.dart';
import 'features/bc_eats/screens/bc_eats_menu_screen.dart';
import 'features/bc_eats/bc_eats_theme_dzanga.dart';

// This preview lets us test the BC Eats menu
// using the device's system light or dark mode.
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: BCEatsTheme.lightTheme,
      darkTheme: BCEatsTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const BCEatsMenuScreen(),
    ),
  );
}