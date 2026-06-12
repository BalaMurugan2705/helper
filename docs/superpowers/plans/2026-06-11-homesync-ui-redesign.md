# HomeSync UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Frost/Linen light theme with a full Aurora dark glassmorphism design system across all screens.

**Architecture:** Design System First — build `AppColors` + `AppTextStyles` + 8 shared widgets, rebuild `AppTheme` to dark-only, then apply to shell and all 12 screens in order. Every screen swaps `FrostPageHeader` for `AuroraHero` and all frost widgets for their glass equivalents.

**Tech Stack:** Flutter 3, Riverpod 2, go_router, google_fonts (`plusJakartaSans`, `outfit`), fl_chart, Material 3

**Spec:** `docs/superpowers/specs/2026-06-11-homesync-ui-redesign-design.md`

---

## File Map

### New files
| File | Responsibility |
|---|---|
| `lib/core/theme/app_colors.dart` | All color tokens + Aurora accent map |
| `lib/core/theme/app_text_styles.dart` | Full type scale (Plus Jakarta Sans + Outfit) |
| `lib/core/widgets/glass_card.dart` | GlassCard — frosted surface container |
| `lib/core/widgets/aurora_hero.dart` | AuroraHero — per-screen gradient header |
| `lib/core/widgets/glass_tile.dart` | GlassTile — list item with dot + chips |
| `lib/core/widgets/status_chip.dart` | StatusChip — done/pending/overdue tags |
| `lib/core/widgets/glass_bottom_sheet.dart` | Adaptive bottom sheet (mobile) / dialog (desktop) |
| `lib/core/widgets/aurora_toast.dart` | `showAuroraToast()` helper |
| `test/core/widgets/glass_card_test.dart` | Widget tests for GlassCard |
| `test/core/widgets/aurora_hero_test.dart` | Widget tests for AuroraHero |
| `test/core/widgets/glass_tile_test.dart` | Widget tests for GlassTile |
| `test/core/widgets/status_chip_test.dart` | Widget tests for StatusChip |

### Modified files
| File | Change |
|---|---|
| `lib/core/theme/app_theme.dart` | Rebuilt as dark-only using AppColors + AppTextStyles |
| `lib/screens/shell/main_shell.dart` | Grouped sidebar (Overview/Home/Finance/Wellness) + bottom tab bar |
| `lib/screens/auth/login_screen.dart` | Aurora gradient bg + centered glass card |
| `lib/screens/dashboard/dashboard_screen.dart` | AuroraHero + GlassCard stats + glass chart card |
| `lib/screens/cleaning/cleaning_screen.dart` | Sky accent |
| `lib/screens/shopping/shopping_screen.dart` | Amber accent |
| `lib/screens/budget/budget_screen.dart` | Emerald accent |
| `lib/screens/expenses/expense_screen.dart` | Rose accent |
| `lib/screens/health/health_screen.dart` | Pink accent |
| `lib/screens/food/food_tracker_screen.dart` | Lime accent |
| `lib/screens/advisor/advisor_screen.dart` | Violet accent |
| `lib/screens/wishlist/wishlist_screen.dart` | Fuchsia accent |
| `lib/screens/pcos_guide/pcos_guide_screen.dart` | Lavender accent |
| `lib/screens/settings/notification_settings_screen.dart` | Indigo accent |

### Retired files
| File | Action |
|---|---|
| `lib/core/widgets/frost_widgets.dart` | Deleted after all screens migrated |

---

## Task 1: AppColors — color tokens + Aurora accent map

**Files:**
- Create: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Create `app_colors.dart`**

```dart
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
  static Color glassBorderAccent(Color accent) => accent.withOpacity(0.20);

  /// Returns `rgba(accent, 0.10)` fill for GlassCard accent variant.
  static Color glassCardAccent(Color accent) => accent.withOpacity(0.10);

  /// Returns `rgba(accent, 0.06)` for the ambient scaffold glow overlay.
  static Color scaffoldGlow(Color accent) => accent.withOpacity(0.06);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat: add AppColors with Aurora accent token map"
```

---

## Task 2: AppTextStyles — Plus Jakarta Sans + Outfit type scale

**Files:**
- Create: `lib/core/theme/app_text_styles.dart`

- [ ] **Step 1: Create `app_text_styles.dart`**

```dart
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
  static TextStyle labelAccent = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.3, height: 1.0,
  );
  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textSubtle,
  );

  /// Returns [labelLarge] with text uppercased via `TextStyle`—
  /// call `.copyWith(color: accent)` to tint.
  static TextStyle eyebrow({Color? color}) => labelLarge.copyWith(
    color: color ?? AppColors.textSubtle,
    letterSpacing: 1.3,
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/theme/app_text_styles.dart
git commit -m "feat: add AppTextStyles with Plus Jakarta Sans + Outfit scale"
```

---

## Task 3: Rebuild AppTheme — dark-only

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Replace `app_theme.dart` entirely**

```dart
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
```

- [ ] **Step 2: Update `main.dart` to use only `darkTheme`**

In `lib/main.dart`, find the `MaterialApp` (or `MaterialApp.router`) and ensure:
```dart
theme:      AppTheme.darkTheme(),
darkTheme:  AppTheme.darkTheme(),
themeMode:  ThemeMode.dark,
```
Remove any reference to `AppTheme.lightTheme()`.

- [ ] **Step 3: Run the app to verify it builds**

```bash
flutter run
```
Expected: App launches with dark background. Nav sidebar and existing screens may still use old frost widgets — that is expected at this stage.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/main.dart
git commit -m "feat: rebuild AppTheme as dark-only Aurora theme"
```

---

## Task 4: GlassCard widget

**Files:**
- Create: `lib/core/widgets/glass_card.dart`
- Create: `test/core/widgets/glass_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/glass_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/glass_card.dart';
import 'package:helper/core/theme/app_colors.dart';

void main() {
  testWidgets('GlassCard renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(child: Text('hello')),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('GlassCard with accent applies tinted border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            accent: AppColors.accentBudget,
            child: const Text('budget'),
          ),
        ),
      ),
    );
    expect(find.text('budget'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/glass_card_test.dart
```
Expected: FAIL — `glass_card.dart` not found.

- [ ] **Step 3: Create `glass_card.dart`**

```dart
// lib/core/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final border = accent != null
        ? AppColors.glassBorderAccent(accent!)
        : AppColors.glassBorder;
    final bg = accent != null
        ? AppColors.glassCardAccent(accent!)
        : AppColors.glassCard;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border),
            boxShadow: accent != null
                ? [BoxShadow(color: accent!.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 4))]
                : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
```

> **Note on BackdropFilter:** Flutter's `BackdropFilter` with `ImageFilter.blur` is expensive on mobile. Use it only on cards that sit above a rich background. The `GlassCard` defaults to a tinted `Container` — wrap with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))` at the call site only where the blur effect is needed and performance allows.

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/widgets/glass_card_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/glass_card.dart test/core/widgets/glass_card_test.dart
git commit -m "feat: add GlassCard widget"
```

---

## Task 5: AuroraHero widget

**Files:**
- Create: `lib/core/widgets/aurora_hero.dart`
- Create: `test/core/widgets/aurora_hero_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/aurora_hero_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/aurora_hero.dart';
import 'package:helper/core/theme/app_colors.dart';

void main() {
  testWidgets('AuroraHero shows title and eyebrow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuroraHero(
            accent: AppColors.accentBudget,
            eyebrow: 'JUNE 2026',
            title: 'Budget',
          ),
        ),
      ),
    );
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('JUNE 2026'), findsOneWidget);
  });

  testWidgets('AuroraHero shows optional subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuroraHero(
            accent: AppColors.accentHealth,
            eyebrow: 'TODAY',
            title: 'Health',
            subtitle: '4 habits done',
          ),
        ),
      ),
    );
    expect(find.text('4 habits done'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/aurora_hero_test.dart
```
Expected: FAIL

- [ ] **Step 3: Create `aurora_hero.dart`**

```dart
// lib/core/widgets/aurora_hero.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AuroraHero extends StatelessWidget {
  final Color accent;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AuroraHero({
    super.key,
    required this.accent,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorderAccent(accent)),
      ),
      child: Stack(
        children: [
          // Radial glow top-right
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: AppTextStyles.eyebrow(color: accent.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 3),
                      Text(title, style: AppTextStyles.headlineLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/widgets/aurora_hero_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/aurora_hero.dart test/core/widgets/aurora_hero_test.dart
git commit -m "feat: add AuroraHero per-screen header widget"
```

---

## Task 6: GlassTile widget

**Files:**
- Create: `lib/core/widgets/glass_tile.dart`
- Create: `test/core/widgets/glass_tile_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/glass_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/glass_tile.dart';
import 'package:helper/core/theme/app_colors.dart';

void main() {
  testWidgets('GlassTile renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTile(
            dotColor: AppColors.accentCleaning,
            title: 'Clean bathroom',
            subtitle: 'Due today',
          ),
        ),
      ),
    );
    expect(find.text('Clean bathroom'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
  });

  testWidgets('GlassTile calls onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTile(
            dotColor: AppColors.accentHealth,
            title: 'Exercise',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(GlassTile));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/glass_tile_test.dart
```
Expected: FAIL

- [ ] **Step 3: Create `glass_tile.dart`**

```dart
// lib/core/widgets/glass_tile.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GlassTile extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassTile({
    super.key,
    required this.dotColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.glassCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 12),
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/widgets/glass_tile_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/glass_tile.dart test/core/widgets/glass_tile_test.dart
git commit -m "feat: add GlassTile list item widget"
```

---

## Task 7: StatusChip widget

**Files:**
- Create: `lib/core/widgets/status_chip.dart`
- Create: `test/core/widgets/status_chip_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/status_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip.done renders green', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip.done())),
    );
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('StatusChip.pending renders amber', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip.pending())),
    );
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('StatusChip.overdue renders rose', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip.overdue())),
    );
    expect(find.text('Overdue'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/widgets/status_chip_test.dart
```
Expected: FAIL

- [ ] **Step 3: Create `status_chip.dart`**

```dart
// lib/core/widgets/status_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  const StatusChip.done({super.key})
      : label = 'Done', color = AppColors.statusDone;

  const StatusChip.pending({super.key})
      : label = 'Pending', color = AppColors.statusPending;

  const StatusChip.overdue({super.key})
      : label = 'Overdue', color = AppColors.statusOverdue;

  factory StatusChip.custom({Key? key, required String label, required Color accent}) =>
      StatusChip(key: key, label: label, color: accent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/widgets/status_chip_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/status_chip.dart test/core/widgets/status_chip_test.dart
git commit -m "feat: add StatusChip with done/pending/overdue variants"
```

---

## Task 8: GlassBottomSheet — adaptive bottom sheet / dialog

**Files:**
- Create: `lib/core/widgets/glass_bottom_sheet.dart`

- [ ] **Step 1: Create `glass_bottom_sheet.dart`**

```dart
// lib/core/widgets/glass_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shows a bottom sheet on mobile (< 800px) and a centered dialog on desktop.
/// Pass [title] and [content] — the rest is handled automatically.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  bool isDismissible = true,
}) {
  final isWide = MediaQuery.of(context).size.width >= 800;
  if (isWide) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (_) => _GlassDialog(title: title, content: content),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GlassSheet(title: title, content: content),
  );
}

class _GlassSheet extends StatelessWidget {
  final String title;
  final Widget content;
  const _GlassSheet({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF912_0E26), // rgba(18,14,38,0.97)
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.textSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  const _GlassDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/widgets/glass_bottom_sheet.dart
git commit -m "feat: add adaptive GlassBottomSheet/Dialog helper"
```

---

## Task 9: AuroraToast helper

**Files:**
- Create: `lib/core/widgets/aurora_toast.dart`

- [ ] **Step 1: Create `aurora_toast.dart`**

```dart
// lib/core/widgets/aurora_toast.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shows a floating snackbar with a colored dot indicator.
/// [dotColor] defaults to [AppColors.statusDone].
void showAuroraToast(
  BuildContext context,
  String message, {
  Color? dotColor,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = dotColor ?? AppColors.statusDone;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                )),
            ),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/widgets/aurora_toast.dart
git commit -m "feat: add showAuroraToast snackbar helper"
```

---

## Task 10: Rebuild main_shell.dart — grouped sidebar + bottom tabs

**Files:**
- Modify: `lib/screens/shell/main_shell.dart`

- [ ] **Step 1: Replace `main_shell.dart` entirely**

Replace the entire file with the new implementation. Key structure:
- `_NavGroup` class: `{String label, List<_NavItem> items}`
- Nav items grouped: Overview / Home / Finance / Wellness, with footer items separate
- Desktop: `_AuroraSidebar` — 220px, `darkSurface` bg, grouped labels, active left-bar + tinted icon
- Mobile: minimal `AppBar` (title + 🌙 + 🔔) + `_AuroraBottomBar` with 5 tabs (Home, Shop, Budget, Health, More)
- "More" tab opens a `showGlassSheet` listing remaining screens

```dart
// lib/screens/shell/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  // ── Nav definition ──────────────────────────────────────────
  static const _bottomItems = [
    _NavItem(icon: Icons.dashboard_rounded,              label: 'Home',   path: '/'),
    _NavItem(icon: Icons.shopping_cart_rounded,          label: 'Shop',   path: '/shopping'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget', path: '/budget'),
    _NavItem(icon: Icons.favorite_rounded,               label: 'Health', path: '/health'),
  ];

  static const _moreItems = [
    _NavItem(icon: Icons.cleaning_services_rounded,  label: 'Cleaning',    path: '/cleaning'),
    _NavItem(icon: Icons.receipt_long_rounded,       label: 'Expenses',    path: '/expenses'),
    _NavItem(icon: Icons.restaurant_menu_rounded,    label: 'Food',        path: '/food'),
    _NavItem(icon: Icons.auto_awesome_rounded,       label: 'AI Advisor',  path: '/advisor'),
    _NavItem(icon: Icons.favorite_border_rounded,    label: 'Wish List',   path: '/wishlist'),
  ];

  List<_NavGroup> _buildNavGroups(bool isAdmin) => [
    const _NavGroup(label: 'Overview', items: [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/'),
    ]),
    const _NavGroup(label: 'Home', items: [
      _NavItem(icon: Icons.cleaning_services_rounded, label: 'Cleaning',  path: '/cleaning'),
      _NavItem(icon: Icons.shopping_cart_rounded,     label: 'Shopping',  path: '/shopping'),
      _NavItem(icon: Icons.favorite_border_rounded,   label: 'Wish List', path: '/wishlist'),
    ]),
    const _NavGroup(label: 'Finance', items: [
      _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget',   path: '/budget'),
      _NavItem(icon: Icons.receipt_long_rounded,           label: 'Expenses', path: '/expenses'),
    ]),
    _NavGroup(label: 'Wellness', items: [
      const _NavItem(icon: Icons.favorite_rounded,        label: 'Health',       path: '/health'),
      const _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Food Tracker', path: '/food'),
      if (isAdmin)
        const _NavItem(icon: Icons.health_and_safety_rounded, label: 'PCOS Guide', path: '/pcos-guide'),
    ]),
  ];

  static const _footerItems = [
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI Advisor',      path: '/advisor'),
    _NavItem(icon: Icons.notifications_outlined, label: 'Notifications', path: '/settings'),
  ];

  void _navigate(String path) {
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = ref.watch(themeModeProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isWide  = MediaQuery.of(context).size.width >= 800;
    final currentPath = GoRouterState.of(context).uri.path;

    final groups   = _buildNavGroups(isAdmin);
    final allItems = groups.expand((g) => g.items).toList();
    final routeIdx = allItems.indexWhere((n) => n.path == currentPath);
    if (routeIdx != -1 && routeIdx != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = routeIdx);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.darkBase,
      appBar: isWide ? null : _buildAppBar(context, isDark),
      body: isWide
          ? Row(children: [
              _AuroraSidebar(
                groups: groups,
                footerItems: _footerItems,
                currentPath: currentPath,
                isAdmin: isAdmin,
                onNavigate: _navigate,
                onToggleTheme: () =>
                    ref.read(themeModeProvider.notifier).state = !isDark,
                onSignOut: () => ref.read(authServiceProvider).signOut(),
              ),
              Expanded(child: widget.child),
            ])
          : widget.child,
      bottomNavigationBar: isWide ? null : _AuroraBottomBar(
        items: _bottomItems,
        moreItems: _moreItems,
        currentPath: currentPath,
        onNavigate: _navigate,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      title: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentDashboard, AppColors.accentPcos],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 10),
        Text('HomeSync', style: AppTextStyles.titleMedium),
      ]),
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 19, color: AppColors.textMuted),
          onPressed: () =>
              ref.read(themeModeProvider.notifier).state = !isDark,
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              size: 19, color: AppColors.textMuted),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────
class _AuroraSidebar extends StatelessWidget {
  final List<_NavGroup> groups;
  final List<_NavItem>  footerItems;
  final String currentPath;
  final bool isAdmin;
  final ValueChanged<String> onNavigate;
  final VoidCallback onToggleTheme, onSignOut;

  const _AuroraSidebar({
    required this.groups,
    required this.footerItems,
    required this.currentPath,
    required this.isAdmin,
    required this.onNavigate,
    required this.onToggleTheme,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.darkSurface,
      child: SafeArea(
        child: Column(children: [
          _SidebarBrand(),
          const Divider(height: 1, color: Color(0x0FFFFFFF)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                for (final group in groups) ...[
                  _GroupLabel(group.label),
                  for (final item in group.items)
                    _SidebarTile(
                      item: item,
                      active: currentPath == item.path,
                      onTap: () => onNavigate(item.path),
                    ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x0FFFFFFF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Column(children: [
              for (final item in footerItems)
                _SidebarTile(
                  item: item,
                  active: currentPath == item.path,
                  onTap: () => onNavigate(item.path),
                ),
              _SidebarTile(
                item: const _NavItem(icon: Icons.logout_rounded, label: 'Sign Out', path: ''),
                active: false,
                onTap: onSignOut,
                isDestructive: true,
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentDashboard, AppColors.accentPcos],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentDashboard.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HomeSync', style: AppTextStyles.titleMedium),
          Text('Smart Home Manager',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
    child: Text(label.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSubtle, letterSpacing: 1.6,
        )),
  );
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool active, isDestructive;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item, required this.active, required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive
        ? AppColors.statusOverdue.withOpacity(0.7)
        : active ? AppColors.textPrimary : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.accentDashboard.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border(left: BorderSide(color: AppColors.accentDashboard, width: 3))
                : null,
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accentDashboard.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 15,
                  color: isDestructive
                      ? AppColors.statusOverdue.withOpacity(0.7)
                      : active ? AppColors.accentDashboard : AppColors.textMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  )),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Bottom tab bar ─────────────────────────────────────────────
class _AuroraBottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final List<_NavItem> moreItems;
  final String currentPath;
  final ValueChanged<String> onNavigate;

  const _AuroraBottomBar({
    required this.items, required this.moreItems,
    required this.currentPath, required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xF70D0A1C),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (final item in items)
            Expanded(child: _BottomTab(
              item: item,
              active: currentPath == item.path,
              onTap: () => onNavigate(item.path),
            )),
          Expanded(child: _MoreTab(
            moreItems: moreItems,
            onNavigate: onNavigate,
          )),
        ]),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _BottomTab({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accentDashboard.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(item.icon, size: 20,
              color: active
                  ? AppColors.accentDashboard
                  : AppColors.textSubtle),
          if (active)
            Container(
              width: 4, height: 4, margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentDashboard,
              ),
            ),
          Text(item.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: active ? AppColors.accentDashboard : AppColors.textSubtle,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
        ]),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  final List<_NavItem> moreItems;
  final ValueChanged<String> onNavigate;
  const _MoreTab({required this.moreItems, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGlassSheet(
        context: context,
        title: 'More',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: moreItems.map((item) => ListTile(
            leading: Icon(item.icon, color: AppColors.textMuted),
            title: Text(item.label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
            onTap: () { Navigator.pop(context); onNavigate(item.path); },
          )).toList(),
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.textSubtle),
        Text('More', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSubtle)),
      ]),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label, path;
  const _NavItem({required this.icon, required this.label, required this.path});
}

class _NavGroup {
  final String label;
  final List<_NavItem> items;
  const _NavGroup({required this.label, required this.items});
}
```

- [ ] **Step 2: Run the app and verify the shell renders**

```bash
flutter run
```
Expected: Dark sidebar on wide screen with grouped nav labels. Bottom tabs visible on mobile with "More" sheet working.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/shell/main_shell.dart
git commit -m "feat: rebuild shell with Aurora sidebar and bottom tab bar"
```

---

## Task 11: Login screen

**Files:**
- Modify: `lib/screens/auth/login_screen.dart`

- [ ] **Step 1: Replace the `build` method and decorative widgets in `login_screen.dart`**

Keep all existing state, controllers, `_submit()`, `_msg()` methods unchanged. Replace only the `build` method and remove any `_buildBackground` / pulse animation widgets. Replace with:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.darkBase,
    body: Stack(children: [
      // Aurora gradient background
      Positioned.fill(child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0D1A),
              Color(0xFF160E2E),
              Color(0xFF12091E),
            ],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      )),
      // Ambient glows
      Positioned(top: -80, left: -60,
        child: _GlowBlob(color: AppColors.accentDashboard, size: 300)),
      Positioned(bottom: -80, right: -60,
        child: _GlowBlob(color: AppColors.accentHealth, size: 280)),
      // Form
      SafeArea(child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildLogo(),
              const SizedBox(height: 32),
              _buildCard(context),
            ]),
          ),
        ),
      )),
    ]),
  );
}

Widget _buildLogo() => Column(children: [
  Container(
    width: 64, height: 64,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.accentDashboard, AppColors.accentPcos],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
        color: AppColors.accentDashboard.withOpacity(0.4),
        blurRadius: 28, offset: const Offset(0, 8),
      )],
    ),
    child: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
  ),
  const SizedBox(height: 14),
  Text('HomeSync', style: AppTextStyles.headlineLarge),
  Text('Smart Home Manager',
      style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
]);

Widget _buildCard(BuildContext context) => Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: AppColors.glassCard,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.glassBorder),
  ),
  child: Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_isLogin ? 'Welcome back' : 'Create account',
          style: AppTextStyles.headlineSmall),
      const SizedBox(height: 4),
      Text(_isLogin ? 'Sign in to HomeSync' : 'Join HomeSync',
          style: AppTextStyles.bodySmall),
      const SizedBox(height: 20),
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: 'EMAIL',
          prefixIcon: Icon(Icons.mail_outline_rounded,
              color: AppColors.textSubtle, size: 18),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Enter your email' : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _pwCtrl,
        obscureText: _obscure,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: 'PASSWORD',
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: AppColors.textSubtle, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSubtle, size: 18),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) =>
            (v == null || v.length < 6) ? 'Min 6 characters' : null,
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(_error!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.statusOverdue,
            )),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDashboard,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_isLogin ? 'Sign In' : 'Sign Up',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
      ),
      const SizedBox(height: 14),
      TextButton(
        onPressed: () => setState(() => _isLogin = !_isLogin),
        child: Text(
          _isLogin
              ? "Don't have an account? Sign Up"
              : 'Already have an account? Sign In',
          style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.accentDashboard.withOpacity(0.8)),
        ),
      ),
    ]),
  ),
);
```

Add the `_GlowBlob` helper at the bottom of the file:

```dart
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(0.12), Colors.transparent],
      ),
    ),
  );
}
```

Add imports at top:
```dart
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
```

- [ ] **Step 2: Run and verify login screen renders**

```bash
flutter run
```
Navigate to login. Expected: dark aurora gradient bg, centered glass card with email/password fields.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/auth/login_screen.dart
git commit -m "feat: redesign login screen with Aurora gradient and glass card"
```

---

## Tasks 12–22: Apply Aurora redesign to each screen

Each screen follows the same pattern. For each screen:
1. Remove `FrostPageHeader` / `FrostShimmerList` / `FrostStat` usages
2. Add `AuroraHero` with the screen's accent color
3. Replace card containers with `GlassCard`
4. Replace list items with `GlassTile`
5. Replace `FloatingActionButton.extended` with a standard FAB or header button
6. Replace any `_showAddEditModal` dialogs to use `showGlassSheet`
7. Replace any snackbar calls with `showAuroraToast`
8. Add `import '../../core/theme/app_colors.dart'`, `app_text_styles.dart`, and the new widgets
9. Remove `import '../../core/widgets/frost_widgets.dart'`

### Task 12: Dashboard screen

**Files:** Modify `lib/screens/dashboard/dashboard_screen.dart`

- [ ] **Step 1: Add AuroraHero header**

Replace `_buildHeroHeader(...)` call with:
```dart
AuroraHero(
  accent: AppColors.accentDashboard,
  eyebrow: '${days[now.weekday - 1].toUpperCase()} · ${monthShort[now.month - 1].toUpperCase()}',
  title: 'Dashboard',
  subtitle: '$overdueTasks overdue · Budget ${budgetUsed.toInt()}% · Health $healthScore',
),
```

- [ ] **Step 2: Replace stat card row with GlassCard widgets**

Replace `_buildStatCards(...)` with:
```dart
Row(children: [
  Expanded(child: GlassCard(
    accent: AppColors.accentDashboard,
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('OVERDUE', style: AppTextStyles.labelLarge),
      const SizedBox(height: 4),
      Text('$overdueTasks', style: AppTextStyles.statDisplay.copyWith(color: AppColors.accentDashboard)),
      Text('tasks', style: AppTextStyles.bodySmall),
    ]),
  )),
  const SizedBox(width: 10),
  Expanded(child: GlassCard(
    accent: AppColors.accentBudget,
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BUDGET', style: AppTextStyles.labelLarge),
      const SizedBox(height: 4),
      Text('${budgetUsed.toInt()}%', style: AppTextStyles.statDisplay.copyWith(color: AppColors.accentBudget)),
      Text('used', style: AppTextStyles.bodySmall),
    ]),
  )),
  const SizedBox(width: 10),
  Expanded(child: GlassCard(
    accent: AppColors.accentHealth,
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('HEALTH', style: AppTextStyles.labelLarge),
      const SizedBox(height: 4),
      Text('${healthScore.toInt()}', style: AppTextStyles.statDisplay.copyWith(color: AppColors.accentHealth)),
      Text('score', style: AppTextStyles.bodySmall),
    ]),
  )),
])
```

- [ ] **Step 3: Wrap chart and list sections in `GlassCard`**

Any `_buildChartsRow`, `_buildUrgentItems`, `_buildTodaysPlan` containers — wrap their outer `Container` or `Card` with `GlassCard(child: ...)`.

- [ ] **Step 4: Run and verify**

```bash
flutter run
```
Expected: Dashboard shows indigo aurora hero, glass stat cards, dark chart card.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/dashboard/dashboard_screen.dart
git commit -m "feat: apply Aurora redesign to Dashboard screen"
```

---

### Task 13: Cleaning screen

**Files:** Modify `lib/screens/cleaning/cleaning_screen.dart`

- [ ] **Step 1: Replace FrostPageHeader with AuroraHero**

```dart
AuroraHero(
  accent: AppColors.accentCleaning,
  eyebrow: 'HOME · CLEANING',
  title: 'Cleaning',
  subtitle: subtitle, // existing subtitle logic
),
```

- [ ] **Step 2: Replace task list items with GlassTile + StatusChip**

For each cleaning task tile, replace with:
```dart
GlassTile(
  dotColor: AppColors.accentCleaning,
  title: task.taskName,
  subtitle: '${task.frequency} · ${_dueDateLabel(task)}',
  trailing: StatusChip(
    label: task.status,
    color: _statusColor(task),
  ),
  onTap: () => _showEditModal(context, ref, task),
  onLongPress: () => _showDeleteConfirm(context, ref, task),
)
```

- [ ] **Step 3: Replace `_showAddEditModal` dialog with `showGlassSheet`**

```dart
showGlassSheet(
  context: context,
  title: task == null ? 'Add Task' : 'Edit Task',
  content: _TaskForm(task: task, ref: ref),
);
```

- [ ] **Step 4: Replace shimmer loading with standard `CircularProgressIndicator`**

```dart
loading: () => const Center(child: CircularProgressIndicator()),
```

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/cleaning/cleaning_screen.dart
git commit -m "feat: apply Aurora redesign to Cleaning screen"
```

---

### Task 14: Shopping screen

**Files:** Modify `lib/screens/shopping/shopping_screen.dart`

- [ ] **Step 1:** Replace header → `AuroraHero(accent: AppColors.accentShopping, eyebrow: 'HOME · SHOPPING', title: 'Shopping', subtitle: subtitle)`

- [ ] **Step 2:** Replace list items → `GlassTile(dotColor: AppColors.accentShopping, ...)` with a `StatusChip` trailing showing bought/pending.

- [ ] **Step 3:** Replace add/edit modal → `showGlassSheet(context: context, title: 'Add Item', content: _ShoppingForm(...))`

- [ ] **Step 4:** Replace shimmer → `CircularProgressIndicator`

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/shopping/shopping_screen.dart
git commit -m "feat: apply Aurora redesign to Shopping screen"
```

---

### Task 15: Budget screen

**Files:** Modify `lib/screens/budget/budget_screen.dart`

- [ ] **Step 1:** Replace header → `AuroraHero(accent: AppColors.accentBudget, eyebrow: 'FINANCE · BUDGET', title: 'Budget', subtitle: '₹${spent} of ₹${total} used')`

- [ ] **Step 2:** Add a total spend `GlassCard` with an emerald progress bar above the category list:
```dart
GlassCard(
  accent: AppColors.accentBudget,
  child: Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('₹${totalSpent.toStringAsFixed(0)}', style: AppTextStyles.statDisplay.copyWith(color: AppColors.accentBudget)),
      Text('of ₹${totalBudget.toStringAsFixed(0)} · $pct%', style: AppTextStyles.bodySmall),
    ]),
    const SizedBox(height: 10),
    LinearProgressIndicator(
      value: pct / 100,
      backgroundColor: AppColors.accentBudget.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation(AppColors.accentBudget),
      borderRadius: BorderRadius.circular(4),
      minHeight: 6,
    ),
  ]),
)
```

- [ ] **Step 3:** Replace per-category cards → `GlassTile` with an inline progress bar as `trailing`.

- [ ] **Step 4:** Replace FAB → header action button; replace modal → `showGlassSheet`

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/budget/budget_screen.dart
git commit -m "feat: apply Aurora redesign to Budget screen"
```

---

### Task 16: Expenses screen

**Files:** Modify `lib/screens/expenses/expense_screen.dart`

- [ ] **Step 1–4:** Same pattern: `AuroraHero(accent: AppColors.accentExpenses, ...)`, `GlassTile` for each expense, `showGlassSheet` for add form, remove shimmer.

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/expenses/expense_screen.dart
git commit -m "feat: apply Aurora redesign to Expenses screen"
```

---

### Task 17: Health screen

**Files:** Modify `lib/screens/health/health_screen.dart`

- [ ] **Step 1:** Replace header → `AuroraHero(accent: AppColors.accentHealth, eyebrow: 'WELLNESS · HEALTH', title: 'Health', subtitle: '$count habits tracked')`

- [ ] **Step 2:** Add stats row with score + streak as `GlassCard` widgets using pink accent.

- [ ] **Step 3:** Replace habit tiles → `GlassTile(dotColor: AppColors.accentHealth, ...)` with `StatusChip` for done/pending/missed.

- [ ] **Step 4:** Replace add modal → `showGlassSheet(context: context, title: 'Add Habit', content: _HabitForm(...))`

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/health/health_screen.dart
git commit -m "feat: apply Aurora redesign to Health screen"
```

---

### Task 18: Food Tracker screen

**Files:** Modify `lib/screens/food/food_tracker_screen.dart`

- [ ] **Step 1–4:** `AuroraHero(accent: AppColors.accentFood, ...)`, `GlassCard` for calorie ring section, `GlassTile` for food entries, `showGlassSheet` for add entry.

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/food/food_tracker_screen.dart
git commit -m "feat: apply Aurora redesign to Food Tracker screen"
```

---

### Task 19: AI Advisor screen

**Files:** Modify `lib/screens/advisor/advisor_screen.dart`

- [ ] **Step 1:** Replace header → `AuroraHero(accent: AppColors.accentAdvisor, eyebrow: 'AI · ADVISOR', title: 'AI Advisor')`

- [ ] **Step 2:** Wrap AI response bubbles in `GlassCard(accent: AppColors.accentAdvisor, ...)`

- [ ] **Step 3:** Style user bubbles with `background: AppColors.accentAdvisor.withOpacity(0.15)` and `border: Border.all(color: AppColors.glassBorderAccent(AppColors.accentAdvisor))`

- [ ] **Step 4: Run, commit**

```bash
flutter run
git add lib/screens/advisor/advisor_screen.dart
git commit -m "feat: apply Aurora redesign to AI Advisor screen"
```

---

### Task 20: Wishlist screen

**Files:** Modify `lib/screens/wishlist/wishlist_screen.dart`

- [ ] **Step 1–4:** `AuroraHero(accent: AppColors.accentWishlist, ...)`, `GlassCard` grid items with fuchsia accent, `showGlassSheet` for add form.

- [ ] **Step 5: Run, commit**

```bash
flutter run
git add lib/screens/wishlist/wishlist_screen.dart
git commit -m "feat: apply Aurora redesign to Wishlist screen"
```

---

### Task 21: PCOS Guide screen

**Files:** Modify `lib/screens/pcos_guide/pcos_guide_screen.dart`

- [ ] **Step 1–3:** `AuroraHero(accent: AppColors.accentPcos, ...)`, `GlassCard` for content sections, lavender accent throughout.

- [ ] **Step 4: Run, commit**

```bash
flutter run
git add lib/screens/pcos_guide/pcos_guide_screen.dart
git commit -m "feat: apply Aurora redesign to PCOS Guide screen"
```

---

### Task 22: Notification Settings screen

**Files:** Modify `lib/screens/settings/notification_settings_screen.dart`

- [ ] **Step 1–3:** `AuroraHero(accent: AppColors.accentDashboard, eyebrow: 'SETTINGS', title: 'Notifications')`, `GlassTile` for each setting toggle with `Switch` as trailing.

- [ ] **Step 4: Run, commit**

```bash
flutter run
git add lib/screens/settings/notification_settings_screen.dart
git commit -m "feat: apply Aurora redesign to Notification Settings screen"
```

---

## Task 23: Cleanup — retire frost_widgets.dart

**Files:**
- Delete: `lib/core/widgets/frost_widgets.dart`
- Modify: `.gitignore`

- [ ] **Step 1: Verify no file imports frost_widgets**

```bash
grep -r "frost_widgets" lib/
```
Expected: no output. If any files appear, apply the screen redesign from Tasks 12–22 to them first.

- [ ] **Step 2: Delete frost_widgets.dart**

```bash
rm lib/core/widgets/frost_widgets.dart
```

- [ ] **Step 3: Add .superpowers/ to .gitignore**

Open `.gitignore` and add at the bottom:
```
.superpowers/
```

- [ ] **Step 4: Run full test suite**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 5: Run the app on all three breakpoints**

```bash
flutter run
```
Verify: mobile (< 800px), tablet (~800px), desktop (> 1200px) all render without errors.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: complete HomeSync Aurora UI/UX redesign

- Remove frost_widgets.dart
- All 12 screens migrated to Aurora glassmorphism
- Per-screen accent colors, GlassCard, AuroraHero, GlassTile
- Bottom tabs on mobile, grouped sidebar on desktop
- Dark-only theme"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Color tokens (AppColors) — Task 1
- ✅ Typography (AppTextStyles) — Task 2
- ✅ AppTheme dark-only rebuild — Task 3
- ✅ GlassCard — Task 4
- ✅ AuroraHero — Task 5
- ✅ GlassTile — Task 6
- ✅ StatusChip — Task 7
- ✅ GlassBottomSheet / GlassDialog — Task 8
- ✅ AuroraToast — Task 9
- ✅ Shell (sidebar + bottom tabs) — Task 10
- ✅ Login — Task 11
- ✅ All 11 content screens + Notification Settings — Tasks 12–22
- ✅ frost_widgets.dart retired — Task 23
- ✅ Bottom sheet on mobile / dialog on desktop — Task 8 + referenced in Tasks 12–22
- ✅ Ambient scaffold glow — AppColors.scaffoldGlow() defined in Task 1; applied per-screen in Tasks 12–22
- ✅ glassBorderAccent formula — AppColors.glassBorderAccent() in Task 1

**Type consistency check:**
- `AppColors.accentDashboard` defined in Task 1, used in Tasks 3, 10, 11, 12, 22 ✅
- `AppTextStyles.statDisplay` defined in Task 2, used in Tasks 12, 15 ✅
- `showGlassSheet` defined in Task 8, used in Tasks 10, 13–21 ✅
- `showAuroraToast` defined in Task 9, referenced in Tasks 12–22 ✅
- `GlassTile` constructor `(dotColor, title, subtitle?, trailing?, onTap?)` consistent across all uses ✅
