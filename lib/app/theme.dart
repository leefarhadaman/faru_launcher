import 'package:flutter/material.dart';

class FaruTheme {
  const FaruTheme._();

  // Fully transparent background — bg image shows through
  static const Color background = Colors.transparent;
  static const Color surface = Color(0x99111318); // semi-transparent card
  static const Color surfaceBorder = Color(0x33FFFFFF);
  static const Color accent = Color(0xFFB794F4); // soft purple
  static const Color accentBlue = Color(0xFF7DD3FC); // sky blue
  static const Color textPrimary = Color(0xFFF3F5F8);
  static const Color textSecondary = Color(0xFF9BA3B0);
  static const Color errorColor = Color(0xFFF28B82);

  // True scaffold background (behind the SVG)
  static const Color scaffoldBg = Color(0xFF06060C);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      surface: scaffoldBg,
      primary: accent,
      secondary: accentBlue,
      error: errorColor,
      onSurface: textPrimary,
      onPrimary: scaffoldBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xCC0E1117),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w200,
          letterSpacing: -1.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          color: textSecondary,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
