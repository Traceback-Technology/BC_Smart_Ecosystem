import 'package:flutter/material.dart';

import 'features/bc_eats/bc_eats_theme_dzanga.dart';
import 'features/bc_eats/screens/bc_eats_cart_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      // Uses the phone's system light or dark mode.
      theme: BCEatsTheme.lightTheme,
      darkTheme: BCEatsTheme.darkTheme,
      themeMode: ThemeMode.dark,

      home: BCEatsCartScreen(),
    ),
  );
}