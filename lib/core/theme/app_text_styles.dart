// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle displayLarge = GoogleFonts.plusJakartaSans(
    fontSize: 32, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, height: 1.1,
  );
  static TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w800,
    letterSpacing: -0.3, height: 1.2,
  );
  static TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 20, fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static TextStyle headlineSmall = GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w700,
  );
  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w700,
  );
  static TextStyle statDisplay = GoogleFonts.plusJakartaSans(
    fontSize: 28, fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w400, height: 1.6,
  );
  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
  );
  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w400, height: 1.4,
  );
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.3, height: 1.0,
  );
  static TextStyle labelAccent = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.3, height: 1.0,
  );
  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w500,
  );

  static TextStyle eyebrow({Color? color}) => labelLarge.copyWith(
    color: color,
    letterSpacing: 1.3,
  );
}
