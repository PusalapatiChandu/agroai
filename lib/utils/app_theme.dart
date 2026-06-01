// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color accentAmber = Color(0xFFFFA000);
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color soilBrown = Color(0xFF795548);
  static const Color skyBlue = Color(0xFF0288D1);
  static const Color bgLight = Color(0xFFF1F8E9);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: lightGreen,
          tertiary: accentAmber,
          surface: bgLight,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarThemeData(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cardWhite,
        ),
        inputDecorationTheme: InputDecorationThemeData(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      );
}

// Severity color helper
Color severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'low':
      return const Color(0xFF66BB6A);
    case 'moderate':
      return const Color(0xFFFFA000);
    case 'high':
      return const Color(0xFFFF5722);
    case 'critical':
      return const Color(0xFFD32F2F);
    default:
      return Colors.grey;
  }
}

String severityEmoji(String severity) {
  switch (severity.toLowerCase()) {
    case 'low': return '🟢';
    case 'moderate': return '🟡';
    case 'high': return '🟠';
    case 'critical': return '🔴';
    default: return '⚪';
  }
}
