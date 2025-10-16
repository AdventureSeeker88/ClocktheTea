import 'package:flutter/material.dart';

/// AppColors
/// Defines the complete color palette for the app, supporting both
/// light and dark themes.
///
/// Usage:
/// - AppColors.lightTheme
/// - AppColors.darkTheme
class AppColors {
  // Brand / Primary
  static const Color deepPurple = Color(0xFF4B0082); // Luxury, empowerment

  // Secondary / CTA
  static const Color gold = Color(0xFFFFD700); // Warm, celebratory

  // Neutral Base
  static const Color cream = Color(0xFFFFF8E7); // Soft, approachable

  // Accents
  static const Color teal = Color(0xFF2BBBAD); // Calm, modern
  static const Color rosePink = Color(0xFFFF69B4); // Playful, positive

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF6E6E6E);
  static const Color textOnDark = Colors.white;

  // Common surfaces
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  /// Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: deepPurple,
    scaffoldBackgroundColor: cream,
    cardColor: white,
    colorScheme: ColorScheme.light(
      primary: deepPurple,
      secondary: gold,
      surface: cream,
      background: cream,
      error: rosePink,
      onPrimary: textOnDark,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: textOnDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: deepPurple,
      foregroundColor: textOnDark,
      elevation: 0,
    ),
  );

  /// Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: deepPurple,
    scaffoldBackgroundColor: deepPurple,
    cardColor: const Color(0xFF2A2A2A), // dark surface
    colorScheme: ColorScheme.dark(
      primary: deepPurple,
      secondary: gold,
      surface: const Color(0xFF2A2A2A),
      background: deepPurple,
      error: rosePink,
      onPrimary: textOnDark,
      onSecondary: textOnDark,
      onSurface: textOnDark,
      onBackground: textOnDark,
      onError: textOnDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textOnDark),
      bodyMedium: TextStyle(color: Colors.grey),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: deepPurple,
      foregroundColor: textOnDark,
      elevation: 0,
    ),
  );
}
