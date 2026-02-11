
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFFCC00); // Warm Yellow
  static const Color backgroundColor = Color(0xFFFFFDE7); // Soft light yellow/white
  static const Color surfaceColor = Colors.white;
  static const Color backgroundHeaderColor = Color(0xFFFFCC00); // Warm Yellow
  static const Color textColor = Color(0xFF4E342E); // Dark Brown

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
      ),
    );
  }
}
