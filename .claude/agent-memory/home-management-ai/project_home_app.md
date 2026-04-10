---
name: Home Management App
description: Single HTML file home management app built at D:/helper/home-management-app/index.html with all four modules
type: project
---

Built a production-quality single-file home management app (1700+ lines) at D:/helper/home-management-app/index.html.

**Why:** User requested a complete Flutter-companion-style app with all four home management modules in one file.

**How to apply:** When user asks to modify or extend the app, always read the current file first. The app uses localStorage key `homesync_v3` for persistence. Chart instances are cached in the `charts` object and destroyed before re-render via `destroyChart()`. Today's reference date is 2026-04-10.

Stack:
- Chart.js 4.4.0 from CDN (doughnut, bar, line, pie charts)
- Vanilla JS + CSS (no framework)
- LocalStorage for persistence
- Dark/light theme toggle (stored in `homesync_theme`)
- Seed data loaded when no localStorage found

Modules: Dashboard, Cleaning Tracker, Shopping Manager, Budget Tracker, Health Habits, AI Advisor
