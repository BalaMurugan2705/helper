# HomeSync UI/UX Redesign — Design Spec

**Date:** 2026-06-11  
**Scope:** Full UI/UX redesign of the HomeSync Flutter app (all screens)  
**Approach:** Design System First — build tokens + shared widgets, then apply to all screens

---

## 1. Design Direction

**Aesthetic:** Rich & Premium dark base + Wellness-soft accents  
**Mode:** Dark-only (light mode is out of scope; may be added in a future phase)

The app uses a single deep-dark background across all screens. Each screen injects its own accent color through shared components — giving every area a distinct identity without fragmenting the visual language.

---

## 2. Color System

### 2.1 Dark Base Tokens (shared across all screens)

| Token | Value | Usage |
|---|---|---|
| `darkBase` | `#0F0D1A` | Scaffold background |
| `darkSurface` | `#13102A` | Sidebar, drawer |
| `glassCard` | `rgba(255,255,255,0.05)` | All card surfaces + `blur(16px)` |
| `glassBorder` | `rgba(255,255,255,0.08)` | Card and input borders |
| `glassBorderAccent` | `rgba(accent, 0.20)` | Card border when accent-tinted |
| `textPrimary` | `#F0E8FF` | All headings |
| `textMuted` | `rgba(255,255,255,0.55)` | Body / secondary text |
| `textSubtle` | `rgba(255,255,255,0.30)` | Labels, hints, timestamps |

### 2.2 Aurora Per-Screen Accent Map

Each screen exposes one `accentColor` and one `accentColor2` (for gradients). All other design tokens remain the dark base.

| Screen | Accent | Hex | Accent2 |
|---|---|---|---|
| Dashboard | Indigo | `#818CF8` | `#6366F1` |
| Cleaning | Sky Blue | `#38BDF8` | `#0EA5E9` |
| Shopping | Amber | `#FB923C` | `#F97316` |
| Budget | Emerald | `#34D399` | `#10B981` |
| Expenses | Rose | `#FB7185` | `#F43F5E` |
| Health | Hot Pink | `#F472B6` | `#EC4899` |
| Food Tracker | Lime | `#A3E635` | `#84CC16` |
| AI Advisor | Violet | `#A78BFA` | `#7C3AED` |
| Wishlist | Fuchsia | `#E879F9` | `#D946EF` |
| PCOS Guide | Lavender | `#C4B5FD` | `#A78BFA` |
| Login | Aurora gradient | `#818CF8` → `#C084FC` → `#F472B6` | — |

### 2.3 Semantic Status Colors

| Status | Color | Hex |
|---|---|---|
| Done / Success | Emerald | `#34D399` |
| Pending / Warning | Amber | `#FB923C` |
| Overdue / Error | Rose | `#FB7185` |
| Streak / Highlight | Hot Pink | `#F472B6` |

---

## 3. Typography

**Heading font:** Plus Jakarta Sans (weights: 700, 800)  
**Body font:** Outfit (weights: 300, 400, 500, 600, 700)

Both fonts are loaded via `google_fonts` package.

### Type Scale

| Token | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `displayLarge` | Plus Jakarta Sans | 32px | 800 | Login hero |
| `headlineLarge` | Plus Jakarta Sans | 24px | 800 | Page titles |
| `headlineMedium` | Plus Jakarta Sans | 20px | 700 | Section headers |
| `headlineSmall` | Plus Jakarta Sans | 16px | 700 | Card headings |
| `titleMedium` | Plus Jakarta Sans | 14px | 700 | List tile titles |
| `displayStat` | Plus Jakarta Sans | 28px | 800 | Stat numbers (not a Material token — used via explicit TextStyle) |
| `bodyLarge` | Outfit | 15px | 400 | AI chat, long descriptions |
| `bodyMedium` | Outfit | 13px | 400 | Subtitles, tile secondary |
| `bodySmall` | Outfit | 11px | 400 | Timestamps, hints |
| `labelLarge` | Outfit | 10px | 700 | Input labels, nav group labels (uppercase, 1.3px spacing) |
| `labelMedium` | Outfit | 10px | 700 | Screen eyebrows in accent color (uppercase) |
| `labelSmall` | Outfit | 10px | 500 | Tab labels, chip text |

---

## 4. Navigation Shell

### 4.1 Desktop / Tablet (≥ 800px) — Labeled Sidebar

- Width: `220px` (collapsed icon-only rail at 600–800px is out of scope for this phase)
- Background: `darkSurface` (`#13102A`) with subtle ambient glow at bottom
- Brand header: 34×34 aurora gradient logo icon + "HomeSync" (Plus Jakarta Sans 800, 15px) + "Smart Home Manager" subtitle
- Nav items grouped into sections with small uppercase labels:
  - **Overview:** Dashboard
  - **Home:** Cleaning · Shopping · Wishlist
  - **Finance:** Budget · Expenses
  - **Wellness:** Health · Food Tracker · PCOS Guide (admin only)
- Active item indicator: left-border accent bar (3px, screen's own color) + tinted icon background
- Badge counts on nav items where overdue/pending items exist
- Footer items (below divider): AI Advisor · Notifications · Sign Out
- Sign Out text is `rgba(251,113,133,0.6)` (destructive muted)

### 4.2 Mobile (< 800px) — Bottom Tab Bar

- App bar: minimal — page title (Plus Jakarta Sans 800, 16px) + dark-mode toggle + notifications bell. No hamburger.
- Bottom tab bar: `60px` tall, `rgba(13,10,28,0.97)` + `backdrop-filter: blur(20px)`, top border `rgba(255,255,255,0.07)`
- 5 tab slots: **Home · Shop · Budget · Health · More**
  - "More" opens a modal bottom sheet listing the remaining screens
- Active tab: tinted background in screen's accent color + accent-colored label + accent dot indicator
- Tab icons: 17px, unselected at `rgba(255,255,255,0.28)`

---

## 5. Component Library

All components live in `lib/core/widgets/`. They accept an optional `accentColor` parameter; screens pass their own accent token.

### 5.1 `GlassCard`

```
background: rgba(255,255,255,0.05)
border: 1px solid rgba(255,255,255,0.09)  [tinted to accent when provided]
border-radius: 16px
backdrop-filter: blur(16px)
box-shadow: 0 4px 24px rgba(accent, 0.08)  [when accent provided]
```

Variants: standard, stat (with progress bar), icon-bubble stat.

### 5.2 `AuroraHero`

Full-width gradient strip at the top of each screen. Receives `accentColor` from the screen. Shows:
- Eyebrow label (date / month) in `labelMedium` accent color
- Page title in `headlineLarge`
- Subtitle summary in `bodyMedium`

Background: `rgba(accent, 0.10)` + `border: 1px solid rgba(accent, 0.18)` + subtle radial glow in top-right corner.

### 5.3 `GlassTile`

List item component used for tasks, shopping items, habits, expenses.

```
padding: 12px 16px
border-radius: 14px
background: rgba(255,255,255,0.04)
border: 1px solid rgba(255,255,255,0.07)
```

Children: accent dot (8×8px circle in the screen's accent color) · title (`titleMedium`) · subtitle (`bodySmall`) · trailing status chip.

### 5.4 `StatusChip`

| Status | Background | Text color |
|---|---|---|
| Done | `rgba(52,211,153,0.12)` | `#6EE7B7` |
| Pending | `rgba(251,146,60,0.12)` | `#FDBA74` |
| Overdue | `rgba(251,113,133,0.12)` | `#FDA4AF` |
| Custom | `rgba(accent,0.12)` | accent light |

### 5.5 Buttons

| Variant | Background | Text |
|---|---|---|
| Primary | `linear-gradient(135deg, #818CF8, #6366F1)` | white |
| Accent | `linear-gradient(135deg, accent, accent2)` | dark or white |
| Ghost | `rgba(255,255,255,0.06)` + border | `rgba(255,255,255,0.7)` |
| Destructive | `rgba(251,113,133,0.12)` + border | `#FDA4AF` |

Border-radius: `12px`. Padding: `12px 22px`. Font: Plus Jakarta Sans 700, 14px.

### 5.6 Inputs

```
background: rgba(255,255,255,0.05)
border: 1px solid rgba(255,255,255,0.10)
border-radius: 12px
padding: 12px 14px
focus: border rgba(accent, 0.5) + box-shadow rgba(accent, 0.12) 3px spread
```

### 5.7 `GlassBottomSheet` / `GlassDialog`

**Mobile (< 800px):** `GlassBottomSheet` — slides up from bottom, `border-radius: 24px 24px 0 0`, handle bar, `backdrop-filter: blur(24px)`, background `rgba(18,14,38,0.98)`.

**Desktop/tablet (≥ 800px):** `GlassDialog` — centered modal, `border-radius: 20px`, same glass surface, max-width `480px`.

Both show the same form content. The screen decides which to show based on `MediaQuery`.

### 5.8 `AuroraToast`

Floating snackbar: `backdrop-filter: blur(20px)`, colored status dot, `border-radius: 14px`, floating behavior.

---

## 6. Screen-by-Screen Layout

All screens follow the same structure:

```
AuroraHero (accent-tinted header strip)
  └── Eyebrow label (date/context) + Page title + Summary subtitle
Scrollable body
  └── Stat cards row (GlassCard variants)
  └── Chart / progress section (where applicable)
  └── GlassTile list (main content)
FAB or header action button
  └── Opens GlassBottomSheet (mobile) or GlassDialog (desktop)
```

### Screen-specific notes

**Dashboard** — 4 stat cards (overdue tasks, budget %, health score, items to buy), monthly spend bar chart, today's plan list mixing tasks from Cleaning + Shopping + Health.

**Cleaning** — Sky accent. Stat cards: overdue count, streak. Task list grouped by room or frequency. FAB adds task.

**Shopping** — Amber accent. Items grouped by priority (high/medium/low). Checkbox to mark bought. FAB adds item.

**Budget** — Emerald accent. Total spend progress bar prominently at top. Per-category rows with inline progress bars. Header "+" adds category.

**Expenses** — Rose accent. List of transactions newest-first. Filter chips by category. FAB adds expense.

**Health** — Hot Pink accent. Wellness score ring, streak counter, habits list (done/pending/missed). FAB adds habit.

**Food Tracker** — Lime accent. Calorie ring (consumed vs goal), meal cards by time of day. FAB adds food entry.

**AI Advisor** — Violet accent. Chat-style layout. User bubbles right-aligned, AI bubbles left-aligned in glass cards. Input bar at bottom.

**Wishlist** — Fuchsia accent. Card grid (2-col on mobile, 3-col on desktop) showing item name, cost, priority. FAB adds item.

**PCOS Guide** — Lavender accent. Admin-only. Content sections with glass cards. Read-only reference screen.

**Login** — Full-bleed aurora gradient background. Centered glass card with email/password inputs and sign-in button. Sign-up toggle inline.

**Notification Settings** — Inherits Dashboard indigo. List of toggle switches in glass tiles.

---

## 7. Interaction Patterns

- **Add / Edit flows:** Bottom sheet on mobile, dialog popup on desktop. Same form widget rendered in both containers.
- **Delete:** Long-press or swipe-to-reveal on mobile. Confirmation dialog before destructive action.
- **Mark done:** Tap checkbox or row. Optimistic UI — immediate visual feedback, revert on error with toast.
- **Navigation active state:** Sidebar/tab accent changes per screen on navigation.
- **Ambient background glow:** Each screen's scaffold has a `DecoratedBox` overlay — `radial-gradient(ellipse 600px 400px at 15% 20%, rgba(accent, 0.06) 0%, transparent 70%)` — on top of `darkBase`. This is a purely visual layer; it does not affect hit-testing or scrolling.

---

## 8. Files to Create / Modify

### Retired files
- `lib/core/widgets/frost_widgets.dart` — deleted; all frost/linen widgets replaced by the new glass component library

### New files
- `lib/core/theme/app_colors.dart` — all color tokens and Aurora accent map
- `lib/core/theme/app_text_styles.dart` — full type scale
- `lib/core/widgets/glass_card.dart` — GlassCard widget
- `lib/core/widgets/aurora_hero.dart` — AuroraHero header strip
- `lib/core/widgets/glass_tile.dart` — GlassTile list item
- `lib/core/widgets/status_chip.dart` — StatusChip
- `lib/core/widgets/glass_bottom_sheet.dart` — adaptive bottom sheet / dialog
- `lib/core/widgets/aurora_toast.dart` — toast snackbar

### Modified files
- `lib/core/theme/app_theme.dart` — rebuilt for dark-only Aurora theme
- `lib/screens/shell/main_shell.dart` — new sidebar (grouped nav) + bottom tab bar
- `lib/screens/auth/login_screen.dart` — aurora gradient bg + glass card
- `lib/screens/dashboard/dashboard_screen.dart` — AuroraHero + glass cards + updated layout
- `lib/screens/cleaning/cleaning_screen.dart` — sky accent + new layout
- `lib/screens/shopping/shopping_screen.dart` — amber accent + new layout
- `lib/screens/budget/budget_screen.dart` — emerald accent + new layout
- `lib/screens/expenses/expense_screen.dart` — rose accent + new layout
- `lib/screens/health/health_screen.dart` — pink accent + new layout
- `lib/screens/food/food_tracker_screen.dart` — lime accent + new layout
- `lib/screens/advisor/advisor_screen.dart` — violet accent + new layout
- `lib/screens/wishlist/wishlist_screen.dart` — fuchsia accent + new layout
- `lib/screens/pcos_guide/pcos_guide_screen.dart` — lavender accent + new layout
- `lib/screens/settings/notification_settings_screen.dart` — indigo accent + glass tiles

---

## 9. Out of Scope

- Light mode (dark-only for this redesign)
- Collapsed icon-only sidebar rail (600–800px breakpoint)
- Animations beyond existing Flutter defaults (page transitions, hero animations are phase 2)
- New features — this redesign changes only UI/UX, not data or business logic
