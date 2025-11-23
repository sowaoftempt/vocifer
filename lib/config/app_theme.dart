// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Blue
  static const Color secondaryColor = Color(0xFF3B82F6); // Bright Blue
  static const Color accentColor = Color(0xFF10B981); // Green
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber

  // Status Colors
  static const Color activeColor = Color(0xFF10B981); // Green
  static const Color pendingColor = Color(0xFFF59E0B); // Amber
  static const Color resolvedColor = Color(0xFF6B7280); // Gray
  static const Color criticalColor = Color(0xFFDC2626); // Red

  // Severity Colors
  static const Color lowSeverity = Color(0xFF10B981); // Green
  static const Color mediumSeverity = Color(0xFFF59E0B); // Amber
  static const Color highSeverity = Color(0xFFEF4444); // Red

  // Background Colors
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,

    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[100]!,
      labelStyle: const TextStyle(color: textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  // Dark Theme (Optional)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: secondaryColor,
    scaffoldBackgroundColor: const Color(0xFF111827),

    colorScheme: const ColorScheme.dark(
      primary: secondaryColor,
      secondary: accentColor,
      surface: Color(0xFF1F2937),
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
  );

  // Utility Methods
  static Color getSeverityColor(int score) {
    if (score <= 33) return lowSeverity;
    if (score <= 66) return mediumSeverity;
    return highSeverity;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
        return pendingColor;
      case 'in_progress':
        return activeColor;
      case 'resolved':
      case 'completed':
        return resolvedColor;
      default:
        return textSecondary;
    }
  }

  static String getSeverityLabel(int score) {
    if (score <= 33) return 'Low';
    if (score <= 66) return 'Medium';
    return 'High';
  }
}