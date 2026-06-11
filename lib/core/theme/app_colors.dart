// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Dark base ──────────────────────────────────────────────
  static const Color darkBase    = Color(0xFF0F0D1A);
  static const Color darkSurface = Color(0xFF13102A);

  // ── Glass surfaces ─────────────────────────────────────────
  static const Color glassCard        = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color glassBorder      = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassCardHover   = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary  = Color(0xFFF0E8FF);
  static const Color textMuted    = Color(0x8CFFFFFF); // rgba(255,255,255,0.55)
  static const Color textSubtle   = Color(0x4DFFFFFF); // rgba(255,255,255,0.30)

  // ── Status ─────────────────────────────────────────────────
  static const Color statusDone    = Color(0xFF34D399); // emerald
  static const Color statusPending = Color(0xFFFB923C); // amber
  static const Color statusOverdue = Color(0xFFFB7185); // rose

  // ── Aurora accent map ──────────────────────────────────────
  static const Color accentDashboard  = Color(0xFF818CF8); // indigo
  static const Color accentDashboard2 = Color(0xFF6366F1);
  static const Color accentCleaning   = Color(0xFF38BDF8); // sky
  static const Color accentCleaning2  = Color(0xFF0EA5E9);
  static const Color accentShopping   = Color(0xFFFB923C); // amber
  static const Color accentShopping2  = Color(0xFFF97316);
  static const Color accentBudget     = Color(0xFF34D399); // emerald
  static const Color accentBudget2    = Color(0xFF10B981);
  static const Color accentExpenses   = Color(0xFFFB7185); // rose
  static const Color accentExpenses2  = Color(0xFFF43F5E);
  static const Color accentHealth     = Color(0xFFF472B6); // pink
  static const Color accentHealth2    = Color(0xFFEC4899);
  static const Color accentFood       = Color(0xFFA3E635); // lime
  static const Color accentFood2      = Color(0xFF84CC16);
  static const Color accentAdvisor    = Color(0xFFA78BFA); // violet
  static const Color accentAdvisor2   = Color(0xFF7C3AED);
  static const Color accentWishlist   = Color(0xFFE879F9); // fuchsia
  static const Color accentWishlist2  = Color(0xFFD946EF);
  static const Color accentPcos       = Color(0xFFC4B5FD); // lavender
  static const Color accentPcos2      = Color(0xFFA78BFA);

  /// Returns `rgba(accent, 0.20)` border color for accent-tinted glass cards.
  static Color glassBorderAccent(Color accent) => accent.withValues(alpha: 0.20);

  /// Returns `rgba(accent, 0.10)` fill for GlassCard accent variant.
  static Color glassCardAccent(Color accent) => accent.withValues(alpha: 0.10);

  /// Returns `rgba(accent, 0.06)` for the ambient scaffold glow overlay.
  static Color scaffoldGlow(Color accent) => accent.withValues(alpha: 0.06);
}
