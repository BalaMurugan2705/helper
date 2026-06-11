// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  // Keep legacy colour aliases so any screen not yet migrated still compiles.
  static const Color primary      = AppColors.accentDashboard;
  static const Color primaryDeep  = AppColors.darkSurface;
  static const Color blueDeep     = AppColors.darkSurface;
  static const Color blueMid      = AppColors.accentDashboard;
  static const Color blueLight    = Color(0xFF6BA3C8);
  static const Color rose         = AppColors.statusOverdue;
  static const Color amber        = AppColors.statusPending;
  static const Color emerald      = AppColors.statusDone;

  // Additional legacy aliases for screens not yet migrated.
  static const Color primaryPurple = AppColors.accentDashboard;
  static const Color accentTeal    = Color(0xFF6BA3C8);
  // FIXME: light-palette aliases — render incorrectly on dark scaffold until
  // login_screen.dart and dashboard_screen.dart are migrated in Tasks 11–12.
  static const Color blueGhost     = Color(0xFFE8F1F7);
  static const Color bluePale      = Color(0xFFC8DCE8);
  static const Color darkCard      = AppColors.darkSurface;
  // FIXME: light-palette aliases — render incorrectly on dark scaffold until
  // login_screen.dart and dashboard_screen.dart are migrated in Tasks 11–12.
  static const Color frostBorder   = Color(0xFFD0E2EE);
  static const Color frostMuted    = Color(0xFF6BA3C8);
  static const Color frostPanel    = Color(0xFFF8FAFB);
  static const Color frostText     = Color(0xFF0D2030);

  static ThemeData darkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary:     AppColors.accentDashboard,
        secondary:   AppColors.accentHealth,
        surface:     AppColors.darkSurface,
        onPrimary:   Colors.white,
        onSecondary: Colors.white,
        onSurface:   AppColors.textPrimary,
        error:       AppColors.statusOverdue,
      ),
      scaffoldBackgroundColor: AppColors.darkBase,
      cardColor:               AppColors.darkSurface,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor:        AppColors.darkSurface,
        foregroundColor:        AppColors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            false,
        titleTextStyle:         AppTextStyles.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color:     AppColors.glassCard,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.glassCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accentDashboard, width: 1.5),
        ),
        labelStyle: AppTextStyles.labelLarge,
        hintStyle:  AppTextStyles.bodyMedium.copyWith(color: AppColors.textSubtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentDashboard,
        foregroundColor: Colors.white,
        elevation:       0,
      ),
      dividerTheme: DividerThemeData(
        color:     AppColors.glassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.darkSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle:   AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDashboard,
          foregroundColor: Colors.white,
          elevation:       0,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassCard,
        labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge:   AppTextStyles.displayLarge,
      headlineLarge:  AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall:  AppTextStyles.headlineSmall,
      titleMedium:    AppTextStyles.titleMedium,
      bodyLarge:      AppTextStyles.bodyLarge,
      bodyMedium:     AppTextStyles.bodyMedium,
      bodySmall:      AppTextStyles.bodySmall,
      labelLarge:     AppTextStyles.labelLarge,
      labelSmall:     AppTextStyles.labelSmall,
    );
  }
}
