import 'package:flutter/material.dart';

/// Brand accent colors — kept constant across light and dark mode, the way
/// a logo color or a "danger" red usually is.
class BcColors {
  BcColors._();
  static const primary = Color(0xFFF5A623); // BC yellow/orange
  static const teal = Color(0xFF14B8A6);
  static const danger = Color(0xFFE5383B);
  static const blue = Color(0xFF2F6BFF);
}

/// Light and dark [ThemeData] for the whole app. Everything that should
/// adapt to dark mode (backgrounds, card surfaces, body text, dividers)
/// goes through here instead of being hardcoded in widgets.
class BcTheme {
  BcTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: BcColors.primary,
      brightness: brightness,
    ).copyWith(secondary: BcColors.teal, error: BcColors.danger);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F8),
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      dividerColor: isDark ? Colors.white12 : const Color(0xFFEDEDED),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
            bodyColor: isDark ? Colors.white70 : Colors.black87,
            displayColor: isDark ? Colors.white : Colors.black,
          ),
      iconTheme: IconThemeData(color: isDark ? Colors.white70 : Colors.black87),
    );
  }
}

/// Small semantic helpers so screens/widgets read `context.textPrimary`
/// instead of hardcoding `Colors.black87` / `Colors.white`.
extension BcThemeContext on BuildContext {
  /// Ensure accent text remains readable on cards in either theme.
  Color readableAccent(Color accent) {
    final background = cardBg.computeLuminance();
    final target = isDark ? Colors.white : Colors.black;
    for (var step = 0; step <= 20; step++) {
      final candidate = Color.lerp(accent, target, step / 20)!;
      final foreground = candidate.computeLuminance();
      final lighter = foreground > background ? foreground : background;
      final darker = foreground < background ? foreground : background;
      if ((lighter + .05) / (darker + .05) >= 4.5) return candidate;
    }
    return target;
  }

  ColorScheme get bcColors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => Theme.of(this).cardColor;
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white60 : Colors.black54;
  Color get subtleBorder => isDark ? Colors.white12 : const Color(0xFFEDEDED);
  Color get chipBg => isDark ? const Color(0xFF262626) : const Color(0xFFF2F2F3);
}
