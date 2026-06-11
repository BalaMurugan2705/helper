// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Plus Jakarta Sans — Headings & Numbers ─────────────────
  static TextStyle displayLarge = GoogleFonts.plusJakartaSans(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.1,
  );
  static TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.2,
  );
  static TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2,
  );
  static TextStyle headlineSmall = GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  // no default color — caller must supply via .copyWith(color: accent)
  static TextStyle statDisplay = GoogleFonts.plusJakartaSans(
    fontSize: 28, fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  // ── Outfit — Body, Labels & UI ─────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textMuted, height: 1.6,
  );
  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textMuted, height: 1.5,
  );
  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textSubtle, height: 1.4,
  );
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textSubtle,
    letterSpacing: 1.3, height: 1.0,
  );
  // no default color — caller must supply via .copyWith(color: accent)
  static TextStyle labelAccent = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.3, height: 1.0,
  );
  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textSubtle,
  );

  /// Returns labelLarge tinted to [color]; pass the string uppercased by the caller.
  static TextStyle eyebrow({Color? color}) => labelLarge.copyWith(
    color: color ?? AppColors.textSubtle,
    letterSpacing: 1.3,
  );
}
