// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Dark base — navy (matches login screen) ────────────────
  static const Color darkBase    = Color(0xFF071223); // deep navy
  static const Color darkSurface = Color(0xFF0B1A35); // navy surface

  // ── Glass surfaces ─────────────────────────────────────────
  static const Color glassCard      = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color glassBorder    = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassCardHover = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEFF6FF); // blue-tinted white
  static const Color textMuted   = Color(0x99C7DCF0); // rgba(soft blue, 0.60)
  static const Color textSubtle  = Color(0x4DC7DCF0); // rgba(soft blue, 0.30)

  // ── Status ─────────────────────────────────────────────────
  static const Color statusDone    = Color(0xFF34D399); // emerald
  static const Color statusPending = Color(0xFFFB923C); // amber
  static const Color statusOverdue = Color(0xFFFB7185); // rose

  // ── Primary blue accent (login screen palette) ─────────────
  static const Color accentDashboard  = Color(0xFF38BDF8); // sky-400
  static const Color accentDashboard2 = Color(0xFF0EA5E9); // sky-500

  // ── Per-module accent map ──────────────────────────────────
  static const Color accentCleaning   = Color(0xFF34D399); // emerald
  static const Color accentCleaning2  = Color(0xFF10B981);
  static const Color accentShopping   = Color(0xFFFB923C); // amber
  static const Color accentShopping2  = Color(0xFFF97316);
  static const Color accentBudget     = Color(0xFF4ADE80); // green
  static const Color accentBudget2    = Color(0xFF22C55E);
  static const Color accentExpenses   = Color(0xFFFB7185); // rose
  static const Color accentExpenses2  = Color(0xFFF43F5E);
  static const Color accentHealth     = Color(0xFFF472B6); // pink
  static const Color accentHealth2    = Color(0xFFEC4899);
  static const Color accentFood       = Color(0xFFA3E635); // lime
  static const Color accentFood2      = Color(0xFF84CC16);
  static const Color accentAdvisor    = Color(0xFF60A5FA); // blue-400
  static const Color accentAdvisor2   = Color(0xFF3B82F6); // blue-500
  static const Color accentWishlist   = Color(0xFFE879F9); // fuchsia
  static const Color accentWishlist2  = Color(0xFFD946EF);
  static const Color accentPcos       = Color(0xFF93C5FD); // blue-300
  static const Color accentPcos2      = Color(0xFF60A5FA); // blue-400

  /// Returns `rgba(accent, 0.20)` border for accent-tinted glass cards.
  static Color glassBorderAccent(Color accent) => accent.withValues(alpha: 0.20);

  /// Returns `rgba(accent, 0.10)` fill for GlassCard accent variant.
  static Color glassCardAccent(Color accent) => accent.withValues(alpha: 0.10);

  /// Returns `rgba(accent, 0.06)` for the ambient scaffold glow overlay.
  static Color scaffoldGlow(Color accent) => accent.withValues(alpha: 0.06);
}

/// ThemeExtension carrying surface/glass/text colours for both modes.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  final Color base;        // scaffold background
  final Color surface;     // card / panel surface
  final Color glassCard;   // frosted-glass fill
  final Color glassBorder; // frosted-glass border
  final Color textPrimary;
  final Color textMuted;
  final Color textSubtle;

  const AppColorsExt({
    required this.base,
    required this.surface,
    required this.glassCard,
    required this.glassBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.textSubtle,
  });

  // ── Dark variant (matches existing AppColors constants) ────────
  static const dark = AppColorsExt(
    base:        Color(0xFF071223),
    surface:     Color(0xFF0B1A35),
    glassCard:   Color(0x0DFFFFFF),
    glassBorder: Color(0x14FFFFFF),
    textPrimary: Color(0xFFEFF6FF),
    textMuted:   Color(0x99C7DCF0),
    textSubtle:  Color(0x4DC7DCF0),
  );

  // ── Light variant ──────────────────────────────────────────────
  static const light = AppColorsExt(
    base:        Color(0xFFF1F5F9),
    surface:     Color(0xFFFFFFFF),
    glassCard:   Color(0x0A000000),
    glassBorder: Color(0x18000000),
    textPrimary: Color(0xFF0F172A),
    textMuted:   Color(0xFF475569),
    textSubtle:  Color(0xFF94A3B8),
  );

  Color glassBorderAccent(Color accent) => accent.withValues(alpha: 0.25);
  Color glassCardAccent(Color accent) => accent.withValues(alpha: 0.10);

  @override
  AppColorsExt copyWith({
    Color? base, Color? surface, Color? glassCard, Color? glassBorder,
    Color? textPrimary, Color? textMuted, Color? textSubtle,
  }) => AppColorsExt(
    base:        base        ?? this.base,
    surface:     surface     ?? this.surface,
    glassCard:   glassCard   ?? this.glassCard,
    glassBorder: glassBorder ?? this.glassBorder,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted:   textMuted   ?? this.textMuted,
    textSubtle:  textSubtle  ?? this.textSubtle,
  );

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      base:        Color.lerp(base,        other.base,        t)!,
      surface:     Color.lerp(surface,     other.surface,     t)!,
      glassCard:   Color.lerp(glassCard,   other.glassCard,   t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted:   Color.lerp(textMuted,   other.textMuted,   t)!,
      textSubtle:  Color.lerp(textSubtle,  other.textSubtle,  t)!,
    );
  }
}

/// Convenience accessor: `context.appColors.glassCard` etc.
extension AppColorsX on BuildContext {
  AppColorsExt get appColors =>
      Theme.of(this).extension<AppColorsExt>() ?? AppColorsExt.dark;
}
