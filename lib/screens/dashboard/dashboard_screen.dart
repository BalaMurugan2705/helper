import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../providers/providers.dart';
import '../../models/budget_category.dart';
import '../../models/cleaning_task.dart';
import '../../models/expense.dart';

// ── Chart/accent constants ───────────────────────────────────────
const _purple   = Color(0xFF4C1D95);   // TASKHUB chart purple
const _purple2  = Color(0xFF6D28D9);

// KPI icon colors
const _kpi1Ic   = Color(0xFFF472B6);
const _kpi2Ic   = Color(0xFFFB923C);
const _kpi3Ic   = Color(0xFF34D399);
const _kpi4Ic   = Color(0xFF818CF8);

// ── Context-aware colour helper ──────────────────────────────────
class _DC {
  final Color bg;
  final Color card;
  final Color border;
  final Color title;
  final Color sub;
  final Color kpi1Bg, kpi2Bg, kpi3Bg, kpi4Bg;

  const _DC({
    required this.bg, required this.card, required this.border,
    required this.title, required this.sub,
    required this.kpi1Bg, required this.kpi2Bg,
    required this.kpi3Bg, required this.kpi4Bg,
  });

  factory _DC.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _DC(
      bg:     isDark ? const Color(0xFF071223) : const Color(0xFFF9FAFB),
      card:   isDark ? const Color(0xFF0D1F3C) : Colors.white,
      border: isDark ? const Color(0x1A38BDF8) : const Color(0xFFE5E7EB),
      title:  isDark ? const Color(0xFFEFF6FF) : const Color(0xFF111827),
      sub:    isDark ? const Color(0xFF7096B8) : const Color(0xFF9CA3AF),
      kpi1Bg: isDark ? const Color(0x1FF472B6) : const Color(0xFFF3E8FF),
      kpi2Bg: isDark ? const Color(0x1FFB923C) : const Color(0xFFFFF7ED),
      kpi3Bg: isDark ? const Color(0x1F34D399) : const Color(0xFFECFDF5),
      kpi4Bg: isDark ? const Color(0x1F818CF8) : const Color(0xFFEEF2FF),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleaningAsync       = ref.watch(cleaningTasksProvider);
    final shoppingAsync       = ref.watch(shoppingItemsProvider);
    final budgetAsync         = ref.watch(budgetProvider);
    final budgetWithSpentAsync = ref.watch(budgetWithSpentProvider);
    final healthAsync         = ref.watch(healthProvider);
    final overdueTasks    = ref.watch(overduTasksCountProvider);
    final itemsToBuy      = ref.watch(itemsToBuyCountProvider);
    final budgetUsed      = ref.watch(totalBudgetUsedProvider);
    final healthScore     = ref.watch(healthScoreProvider);
    final selectedMonth   = ref.watch(dashboardMonthProvider);
    final monthExpenses   = ref.watch(selectedMonthExpensesProvider);
    final monthTotal      = ref.watch(selectedMonthTotalProvider);
    final prevTotal       = ref.watch(prevMonthTotalProvider);
    final byCategory      = ref.watch(selectedMonthByCategoryProvider);
    final now             = DateTime.now();
    final todayDate       = DateTime(now.year, now.month, now.day);
    final foodAsync       = ref.watch(foodEntriesProvider(todayDate));
    final calorieGoalAsync= ref.watch(calorieGoalProvider);

    final doneCount = cleaningAsync.when(
      data: (t) => t.where((x) => x.status.name == 'done').length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final dc = _DC.of(context);
    return Scaffold(
      backgroundColor: dc.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TASKHUB-style top bar ───────────────────────────
            _DashTopBar(
              selectedMonth: selectedMonth,
              ref: ref,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: LayoutBuilder(builder: (_, box) {
                final cols = box.maxWidth >= 900 ? 3 : box.maxWidth >= 560 ? 2 : 1;
                const gap = 10.0;

                final panels = <Widget>[
                    // ── TODAY'S TASK HISTORY panel ──────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Today's Task History",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: dc.title,
                                      )),
                                  const SizedBox(height: 2),
                                  Text('Task Summary',
                                      style: TextStyle(fontSize: 11, color: dc.sub)),
                                ],
                              ),
                              _ExportBtn(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _KpiTile(
                              bg: dc.kpi1Bg, iconColor: _kpi1Ic,
                              icon: Icons.assignment_rounded,
                              value: '$overdueTasks',
                              label: 'Overdue',
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiTile(
                              bg: dc.kpi2Bg, iconColor: _kpi2Ic,
                              icon: Icons.check_circle_rounded,
                              value: '$doneCount',
                              label: 'Complete',
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiTile(
                              bg: dc.kpi3Bg, iconColor: _kpi3Ic,
                              icon: Icons.shopping_cart_rounded,
                              value: '$itemsToBuy',
                              label: 'Shopping',
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiTile(
                              bg: dc.kpi4Bg, iconColor: _kpi4Ic,
                              icon: Icons.favorite_rounded,
                              value: '${healthScore.toInt()}',
                              label: 'Health',
                            )),
                          ]),
                        ],
                      ),
                    ),

                    // ── PROJECT CATEGORIES (budget bar chart) ───
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PanelTitle(title: 'Budget by Category'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: _BudgetBarChart(budgetAsync: budgetAsync),
                          ),
                        ],
                      ),
                    ),

                    // ── TASK ACTIVITY line chart ────────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _PanelTitle(title: 'Task Activity'),
                              _LegendRow(items: const [
                                _LegendItem(color: _purple, label: 'Overdue'),
                                _LegendItem(color: Color(0xFF34D399), label: 'Done'),
                                _LegendItem(color: Color(0xFFFB923C), label: 'Pending'),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: _TaskActivityChart(cleaningAsync: cleaningAsync),
                          ),
                        ],
                      ),
                    ),

                    // ── EXPENSE TREND (area chart) ──────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PanelTitle(title: 'Expense Trend'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: _ExpenseTrendChart(
                              expenses: monthExpenses,
                              monthTotal: monthTotal,
                              prevTotal: prevTotal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            _TrendLegend(
                              color: const Color(0xFF6D28D9),
                              label: 'Last Month',
                              value: '₹${prevTotal.toStringAsFixed(0)}',
                            ),
                            const SizedBox(width: 20),
                            _TrendLegend(
                              color: const Color(0xFF34D399),
                              label: 'This Month',
                              value: '₹${monthTotal.toStringAsFixed(0)}',
                            ),
                          ]),
                        ],
                      ),
                    ),

                    // ── BUDGET VS ACTUAL grouped bar ────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PanelTitle(title: 'Budget vs Actual'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: _BudgetVsActualChart(budgetAsync: budgetWithSpentAsync),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            _TrendLegend(
                                color: const Color(0xFFE5E7EB),
                                label: 'Budget',
                                value: budgetWithSpentAsync.when(
                                  data: (cats) =>
                                      '₹${cats.fold(0.0, (s, x) => s + x.budgetAmount).toStringAsFixed(0)}',
                                  loading: () => '—',
                                  error: (_, __) => '—',
                                )),
                            const SizedBox(width: 20),
                            _TrendLegend(
                                color: _purple2,
                                label: 'Spent',
                                value: budgetWithSpentAsync.when(
                                  data: (cats) =>
                                      '₹${cats.fold(0.0, (s, x) => s + x.spentAmount).toStringAsFixed(0)}',
                                  loading: () => '—',
                                  error: (_, __) => '—',
                                )),
                          ]),
                        ],
                      ),
                    ),

                    // ── LATEST WORK LIST ────────────────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _PanelTitle(title: 'Latest Work List'),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  border: Border.all(color: dc.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Today',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: dc.sub,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        size: 14, color: dc.sub),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          cleaningAsync.when(
                            data: (tasks) {
                              if (tasks.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('No tasks yet',
                                      style: TextStyle(color: dc.sub, fontSize: 13)),
                                );
                              }
                              final sorted = [...tasks]
                                ..sort((a, b) =>
                                    (b.isOverdue ? 1 : 0)
                                        .compareTo(a.isOverdue ? 1 : 0));
                              return Column(
                                children: sorted
                                    .take(5)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((e) => _WorkListRow(
                                          task: e.value,
                                          index: e.key,
                                        ))
                                    .toList(),
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    // ── NUTRITION summary ───────────────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PanelTitle(title: "Today's Nutrition"),
                          const SizedBox(height: 10),
                          foodAsync.when(
                            data: (entries) {
                              final goal = calorieGoalAsync.when(
                                  data: (g) => g.toDouble(),
                                  loading: () => 2000.0,
                                  error: (_, __) => 2000.0);
                              final totalCals =
                                  entries.fold(0.0, (s, e) => s + e.calories);
                              final totalProtein =
                                  entries.fold(0.0, (s, e) => s + e.protein);
                              final totalCarbs =
                                  entries.fold(0.0, (s, e) => s + e.carbs);
                              final totalFat =
                                  entries.fold(0.0, (s, e) => s + e.fat);
                              final progress = goal > 0
                                  ? (totalCals / goal).clamp(0.0, 1.0)
                                  : 0.0;
                              final isOver = totalCals > goal;

                              return Column(children: [
                                Row(children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CustomPaint(
                                          size: const Size(80, 80),
                                          painter: _RingPainter(
                                            progress: progress,
                                            color: isOver
                                                ? const Color(0xFFFB7185)
                                                : const Color(0xFF34D399),
                                            bg: dc.border,
                                          ),
                                        ),
                                        Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                totalCals.toInt().toString(),
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: dc.title,
                                                ),
                                              ),
                                              Text('kcal',
                                                  style: TextStyle(
                                                      fontSize: 10, color: dc.sub)),
                                            ]),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(children: [
                                      _MacroBar('Protein', totalProtein, 150,
                                          const Color(0xFFFF5722)),
                                      const SizedBox(height: 8),
                                      _MacroBar('Carbs', totalCarbs, 250,
                                          const Color(0xFFFFC107)),
                                      const SizedBox(height: 8),
                                      _MacroBar('Fat', totalFat, 65,
                                          const Color(0xFF2196F3)),
                                      const SizedBox(height: 8),
                                      Text(
                                        isOver
                                            ? 'Over by ${(totalCals - goal).toInt()} kcal'
                                            : '${(goal - totalCals).toInt()} kcal left',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isOver
                                              ? const Color(0xFFFB7185)
                                              : const Color(0xFF34D399),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ]),
                              ]);
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _purple2)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    // ── TODAY'S PLAN ────────────────────────────
                    _TkPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PanelTitle(title: "Today's Plan"),
                          const SizedBox(height: 10),
                          cleaningAsync.when(
                            data: (tasks) {
                              final due = tasks
                                  .where((t) => t.isDueToday || t.isOverdue)
                                  .take(4)
                                  .toList();
                              if (due.isEmpty) {
                                return Text('No tasks due today.',
                                    style: TextStyle(color: dc.sub, fontSize: 13));
                              }
                              return Column(
                                children: due
                                    .map((t) => _PlanRow(
                                          icon: Icons.cleaning_services_rounded,
                                          color: t.isOverdue
                                              ? const Color(0xFFFB7185)
                                              : const Color(0xFF34D399),
                                          text: '${t.name} · ${t.room}',
                                          badge: t.isOverdue ? 'OVERDUE' : 'TODAY',
                                        ))
                                    .toList(),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          healthAsync.when(
                            data: (habits) {
                              final incomplete =
                                  habits.where((h) => !h.isCompleted).take(3);
                              return Column(
                                children: incomplete
                                    .map((h) => _PlanRow(
                                          icon: Icons.favorite_rounded,
                                          color: const Color(0xFFF472B6),
                                          text:
                                              '${h.name}: ${h.todayValue}/${h.goal} ${h.unit}',
                                          badge: 'HEALTH',
                                        ))
                                    .toList(),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                ];

                final rows = <List<Widget>>[];
                for (var i = 0; i < panels.length; i += cols) {
                  rows.add(panels.sublist(
                      i, (i + cols).clamp(0, panels.length)));
                }

                return Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: gap),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var j = 0; j < rows[i].length; j++) ...[
                              if (j > 0) const SizedBox(width: gap),
                              Expanded(child: rows[i][j]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────

class _DashTopBar extends StatelessWidget {
  final DateTime selectedMonth;
  final WidgetRef ref;
  const _DashTopBar({required this.selectedMonth, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    const monthNames = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Container(
      color: dc.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: dc.title,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${monthNames[now.month - 1]} ${now.year}',
                    style: TextStyle(fontSize: 12, color: dc.sub),
                  ),
                ],
              ),
            ),
            // Month selector
            Container(
              decoration: BoxDecoration(
                color: dc.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dc.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _MiniNavBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    ref.read(dashboardMonthProvider.notifier).state =
                        DateTime(selectedMonth.year, selectedMonth.month - 1);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dc.title,
                    ),
                  ),
                ),
                _MiniNavBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentMonth
                      ? null
                      : () {
                          ref.read(dashboardMonthProvider.notifier).state =
                              DateTime(selectedMonth.year,
                                  selectedMonth.month + 1);
                        },
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── White panel card ──────────────────────────────────────────────

class _TkPanel extends StatelessWidget {
  final Widget child;
  const _TkPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── KPI tile ──────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final Color bg, iconColor;
  final IconData icon;
  final String value, label;
  const _KpiTile({
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Icon(Icons.more_horiz_rounded, size: 14, color: dc.sub),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: dc.title,
                height: 1.0,
              )),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 10, color: dc.sub)),
        ],
      ),
    );
  }
}

// ─── Budget bar chart ──────────────────────────────────────────────

class _BudgetBarChart extends StatelessWidget {
  final AsyncValue<List<BudgetCategory>> budgetAsync;
  const _BudgetBarChart({required this.budgetAsync});

  static const _barColors = [
    _purple, Color(0xFF6D28D9), Color(0xFF7C3AED),
    Color(0xFF8B5CF6), Color(0xFFA78BFA), Color(0xFFC4B5FD),
  ];

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    return budgetAsync.when(
      data: (cats) {
        if (cats.isEmpty) {
          return Center(
              child: Text('No budget data', style: TextStyle(color: dc.sub)));
        }
        final groups = cats.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.budgetAmount,
                color: _barColors[e.key % _barColors.length],
                width: 18,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5)),
              ),
            ],
          );
        }).toList();

        return BarChart(BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: dc.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: dc.sub),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i >= 0 && i < cats.length) {
                    final label = cats[i].category;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label.length > 6
                            ? '${label.substring(0, 5)}.'
                            : label,
                        style: TextStyle(fontSize: 9, color: dc.sub),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(enabled: false),
        ));
      },
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _purple2)),
      error: (_, __) =>
          Center(child: Text('Error', style: TextStyle(color: dc.sub))),
    );
  }
}

// ─── Task Activity line chart ──────────────────────────────────────

class _TaskActivityChart extends StatelessWidget {
  final AsyncValue<List<CleaningTask>> cleaningAsync;
  const _TaskActivityChart({required this.cleaningAsync});

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    return cleaningAsync.when(
      data: (tasks) {
        // build 7-point synthetic series from task data
        final rng = math.Random(42);
        final done = tasks.where((t) => t.status.name == 'done').length;
        final overdue = tasks.where((t) => t.isOverdue).length;
        final pending = tasks.length - done - overdue;

        List<FlSpot> makeSpots(int base) {
          final b = base.clamp(0, 9999);
          final maxNoise = ((b * 0.4).ceil() + 1).clamp(1, 9999);
          return List.generate(7, (i) {
            final noise = rng.nextInt(maxNoise) - (b * 0.2).ceil().clamp(0, 9999);
            return FlSpot(i.toDouble(), (b + noise).clamp(0, 9999).toDouble());
          });
        }

        final overdueSpots = makeSpots(overdue);
        final doneSpots    = makeSpots(done);
        final pendingSpots = makeSpots(pending.clamp(0, 9999));

        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

        LineChartData makeData() => LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: dc.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(days[v.toInt() % 7],
                      style: TextStyle(fontSize: 9, color: dc.sub)),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: TextStyle(fontSize: 9, color: dc.sub)),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            _smoothLine(overdueSpots, _purple),
            _smoothLine(doneSpots, const Color(0xFF34D399)),
            _smoothLine(pendingSpots, const Color(0xFFFB923C)),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        s.y.toStringAsFixed(0),
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ),
        );

        return LineChart(makeData());
      },
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _purple2)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  LineChartBarData _smoothLine(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.4,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
}

// ─── Expense trend chart ───────────────────────────────────────────

class _ExpenseTrendChart extends StatelessWidget {
  final List<Expense> expenses;
  final double monthTotal, prevTotal;
  const _ExpenseTrendChart({
    required this.expenses,
    required this.monthTotal,
    required this.prevTotal,
  });

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    // Build 8-point series from monthly data
    final rng = math.Random(99);
    final base = monthTotal > 0 ? monthTotal / 8 : 500;
    final pBase = prevTotal > 0 ? prevTotal / 8 : 450;

    List<FlSpot> makeSpots(double b, int seed) {
      final r = math.Random(seed);
      double acc = 0;
      return List.generate(8, (i) {
        acc += b + r.nextInt((b * 0.5).ceil() + 1);
        return FlSpot(i.toDouble(), acc);
      });
    }

    final thisSpots = makeSpots(base.toDouble(), 11);
    final prevSpots = makeSpots(pBase.toDouble(), 77);

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: dc.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: prevSpots,
          isCurved: true,
          curveSmoothness: 0.4,
          color: const Color(0xFF6D28D9),
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: const Color(0xFF6D28D9),
              strokeColor: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0x116D28D9),
          ),
        ),
        LineChartBarData(
          spots: thisSpots,
          isCurved: true,
          curveSmoothness: 0.4,
          color: const Color(0xFF34D399),
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: const Color(0xFF34D399),
              strokeColor: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0x1134D399),
          ),
        ),
      ],
      lineTouchData: LineTouchData(enabled: false),
    ));
  }
}

// ─── Budget vs Actual grouped bar chart ───────────────────────────

class _BudgetVsActualChart extends StatelessWidget {
  final AsyncValue<List<BudgetCategory>> budgetAsync;
  const _BudgetVsActualChart({required this.budgetAsync});

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    return budgetAsync.when(
      data: (cats) {
        if (cats.isEmpty) {
          return Center(
              child: Text('No data', style: TextStyle(color: dc.sub)));
        }
        final groups = cats.take(6).toList().asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barsSpace: 3,
            barRods: [
              BarChartRodData(
                toY: e.value.budgetAmount,
                color: const Color(0xFFE5E7EB),
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: e.value.spentAmount,
                color: _purple2,
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList();

        return BarChart(BarChartData(
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: dc.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  final list = cats.take(6).toList();
                  if (i >= 0 && i < list.length) {
                    final l = list[i].category;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.length > 5 ? l.substring(0, 4) : l,
                        style: TextStyle(fontSize: 9, color: dc.sub),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v >= 1000
                      ? '${(v / 1000).toStringAsFixed(0)}k'
                      : '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: dc.sub),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(enabled: false),
        ));
      },
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _purple2)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Latest Work List row ─────────────────────────────────────────

class _WorkListRow extends StatelessWidget {
  final CleaningTask task;
  final int index;
  const _WorkListRow({required this.task, required this.index});

  static const _barColors = [
    _purple, Color(0xFF34D399), Color(0xFFFB923C), Color(0xFF374151),
    Color(0xFF818CF8),
  ];

  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    final color = _barColors[index % _barColors.length];
    final pct = task.status.name == 'done'
        ? 1.0
        : task.isOverdue
            ? 0.2
            : 0.5;
    final pctLabel = '${(pct * 100).toInt()}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(task.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dc.title)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${task.room}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: dc.sub),
          ),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Text(pctLabel,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ]),
    );
  }
}

// ─── Plan row ─────────────────────────────────────────────────────

class _PlanRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text, badge;
  const _PlanRow(
      {required this.icon,
      required this.color,
      required this.text,
      required this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: _DC.of(context).title),
              overflow: TextOverflow.ellipsis),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Text(badge,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5)),
        ),
      ]),
    );
  }
}

// ─── Macro bar ────────────────────────────────────────────────────

class _MacroBar extends StatelessWidget {
  final String label;
  final double current, target;
  final Color color;
  const _MacroBar(this.label, this.current, this.target, this.color);

  @override
  Widget build(BuildContext context) {
    final progress =
        target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(children: [
      SizedBox(
          width: 46,
          child: Text(label,
              style: TextStyle(fontSize: 10, color: _DC.of(context).sub))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('${current.toInt()}g',
          style: TextStyle(fontSize: 10, color: _DC.of(context).sub)),
    ]);
  }
}

// ─── Calorie ring painter ─────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color, bg;
  const _RingPainter(
      {required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    const sw = 8.0;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = bg
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Small reusable widgets ───────────────────────────────────────

class _PanelTitle extends StatelessWidget {
  final String title;
  const _PanelTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _DC.of(context).title,
        ));
  }
}

class _ExportBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dc = _DC.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: dc.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.upload_rounded, size: 13, color: dc.sub),
        const SizedBox(width: 5),
        Text('Export',
            style: TextStyle(
                fontSize: 11,
                color: dc.sub,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final List<_LegendItem> items;
  const _LegendRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
        children: items
            .map((i) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i.color,
                          shape: BoxShape.circle,
                        )),
                    const SizedBox(width: 4),
                    Text(i.label,
                        style:
                            TextStyle(fontSize: 9, color: _DC.of(context).sub)),
                  ]),
                ))
            .toList());
  }
}

class _LegendItem {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
}

class _TrendLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _TrendLegend(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 9, color: _DC.of(context).sub)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _DC.of(context).title)),
      ]),
    ]);
  }
}

class _MiniNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MiniNavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon,
            size: 16,
            color: onTap == null ? const Color(0xFFD1D5DB) : _DC.of(context).sub),
      ),
    );
  }
}
