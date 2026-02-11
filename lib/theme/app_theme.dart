
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warm & Cozy Palette
  static const Color backgroundColor = Color(0xFFFDFCF4); // Warm Cream/Beige
  static const Color primaryColor = Color(0xFF8D6E63); // Warm Brown (primary interactable)
  static const Color textColor = Color(0xFF4E342E); // Dark Brown
  static const Color secretGrey = Color(0xFF757575); // Secondary Text

  // Aesthetic Base Colors (Warm, Earthy, Pastel)
  static const List<Color> baseColors = [
    Color(0xFFFFF9C4), // Light Yellow (Default)
    Color(0xFFFFCC80), // Soft Orange
    Color(0xFFFFAB91), // Terracotta
    Color(0xFFE57373), // Muted Red
    Color(0xFFF48FB1), // Dusty Pink
    Color(0xFFCE93D8), // Lavender
    Color(0xFFB39DDB), // Periwinkle
    Color(0xFF9FA8DA), // Soft Indigo
    Color(0xFF90CAF9), // Sky Blue
    Color(0xFF80CBC4), // Muted Teal
    Color(0xFFA5D6A7), // Matcha Green
    Color(0xFFC5E1A5), // Light Sage
    Color(0xFFE6EE9C), // Lime
    Color(0xFFD7CCC8), // Clay/Beige
    Color(0xFFCFD8DC), // Blue Grey
  ];

  // Helper to generate 10 shades from Light to Dark for a given base color
  static List<Color> getShades(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    final List<Color> shades = [];
    
    // Generate 10 shades
    // Vary lightness from 0.95 (Very light) down to 0.15 (Very dark)
    for (int i = 0; i < 10; i++) {
        // Linear interpolation for lightness
       double lightness = 0.95 - (i * 0.085);
       shades.add(hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor());
    }
    return shades;
  }

  // Get contrast text color (Soft White or Dark Brown)
  static Color getContrastTextColor(Color backgroundColor) {
    // Calculate luminance
    if (backgroundColor.computeLuminance() > 0.5) {
      return textColor; // Dark Brown for light backgrounds
    } else {
      return const Color(0xFFF5F5F5); // Soft White for dark backgrounds
    }
  }

  static bool isSameBaseColor(Color c1, Color c2) {
    return c1.toARGB32() == c2.toARGB32();
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0, // We will handle shadows manually for that soft look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
