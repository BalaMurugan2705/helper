// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static const Color primary      = AppColors.accentDashboard;
  static const Color primaryDeep  = AppColors.darkSurface;
  static const Color blueDeep     = AppColors.darkSurface;
  static const Color blueMid      = AppColors.accentDashboard;
  static const Color blueLight    = Color(0xFF6BA3C8);
  static const Color rose         = AppColors.statusOverdue;
  static const Color amber        = AppColors.statusPending;
  static const Color emerald      = AppColors.statusDone;
  static const Color primaryPurple = AppColors.accentDashboard;
  static const Color accentTeal    = Color(0xFF6BA3C8);
  static const Color blueGhost     = Color(0xFFE8F1F7);
  static const Color bluePale      = Color(0xFFC8DCE8);
  static const Color darkCard      = AppColors.darkSurface;
  static const Color frostBorder   = Color(0xFFD0E2EE);
  static const Color frostMuted    = Color(0xFF6BA3C8);
  static const Color frostPanel    = Color(0xFFF8FAFB);
  static const Color frostText     = Color(0xFF0D2030);

  static ThemeData darkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      extensions: const [AppColorsExt.dark],
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
      textTheme: _buildTextTheme(
        base.textTheme,
        primary: AppColors.textPrimary,
        muted:   const Color(0x99C7DCF0),
        subtle:  const Color(0x4DC7DCF0),
      ),
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
        hintStyle:  AppTextStyles.bodyMedium,
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
        contentTextStyle: AppTextStyles.bodyMedium,
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
        labelStyle: AppTextStyles.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    const surface    = Color(0xFFFFFFFF);
    const bgBase     = Color(0xFFF1F5F9);
    const cardBorder = Color(0x18000000);
    const cardFill   = Color(0x0A000000);
    const primary    = AppColors.accentDashboard;
    const textOn     = Color(0xFF0F172A);
    const textMuted  = Color(0xFF475569);
    const textSubtle = Color(0xFF94A3B8);

    return base.copyWith(
      extensions: const [AppColorsExt.light],
      colorScheme: ColorScheme.light(
        primary:     primary,
        secondary:   AppColors.accentHealth,
        surface:     surface,
        onPrimary:   Colors.white,
        onSecondary: Colors.white,
        onSurface:   textOn,
        error:       AppColors.statusOverdue,
      ),
      scaffoldBackgroundColor: bgBase,
      cardColor:               surface,
      textTheme: _buildTextTheme(
        base.textTheme,
        primary: textOn,
        muted:   textMuted,
        subtle:  textSubtle,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:        surface,
        foregroundColor:        textOn,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            false,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: textOn),
        shadowColor: const Color(0x0A000000),
      ),
      cardTheme: CardThemeData(
        color:     surface,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: cardFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: AppTextStyles.labelLarge.copyWith(color: textSubtle),
        hintStyle:  AppTextStyles.bodyMedium.copyWith(color: textSubtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
      ),
      dividerTheme: const DividerThemeData(
        color:     cardBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  surface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textOn),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle:   AppTextStyles.headlineSmall.copyWith(color: textOn),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation:       0,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardFill,
        labelStyle: AppTextStyles.labelSmall.copyWith(color: textMuted),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: const BorderSide(color: cardBorder),
      ),
    );
  }

  static TextTheme _buildTextTheme(
    TextTheme base, {
    required Color primary,
    required Color muted,
    required Color subtle,
  }) {
    return base.copyWith(
      displayLarge:   AppTextStyles.displayLarge.copyWith(color: primary),
      headlineLarge:  AppTextStyles.headlineLarge.copyWith(color: primary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
      headlineSmall:  AppTextStyles.headlineSmall.copyWith(color: primary),
      titleMedium:    AppTextStyles.titleMedium.copyWith(color: primary),
      bodyLarge:      AppTextStyles.bodyLarge.copyWith(color: muted),
      bodyMedium:     AppTextStyles.bodyMedium.copyWith(color: muted),
      bodySmall:      AppTextStyles.bodySmall.copyWith(color: subtle),
      labelLarge:     AppTextStyles.labelLarge.copyWith(color: subtle),
      labelSmall:     AppTextStyles.labelSmall.copyWith(color: subtle),
    );
  }
}
