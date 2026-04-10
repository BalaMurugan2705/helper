import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/budget_category.dart';
import '../../models/cleaning_task.dart';
import '../../models/expense.dart';
import '../../models/food_entry.dart';
import '../../models/health_habit.dart';
import '../../models/shopping_item.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleaningAsync = ref.watch(cleaningTasksProvider);
    final shoppingAsync = ref.watch(shoppingItemsProvider);
    final budgetAsync = ref.watch(budgetProvider);
    final healthAsync = ref.watch(healthProvider);
    final overdueTasks = ref.watch(overduTasksCountProvider);
    final itemsToBuy = ref.watch(itemsToBuyCountProvider);
    final budgetUsed = ref.watch(totalBudgetUsedProvider);
    final healthScore = ref.watch(healthScoreProvider);
    final selectedMonth = ref.watch(dashboardMonthProvider);
    final monthExpenses = ref.watch(selectedMonthExpensesProvider);
    final monthTotal = ref.watch(selectedMonthTotalProvider);
    final prevTotal = ref.watch(prevMonthTotalProvider);
    final byCategory = ref.watch(selectedMonthByCategoryProvider);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final foodAsync = ref.watch(foodEntriesProvider(todayDate));
    final calorieGoalAsync = ref.watch(calorieGoalProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, selectedMonth),
            const SizedBox(height: 20),
            _buildStatCards(
                context, overdueTasks, itemsToBuy, budgetUsed, healthScore),
            const SizedBox(height: 20),
            _buildTodaysNutrition(context, foodAsync, calorieGoalAsync),
            const SizedBox(height: 20),
            _buildMonthlyOverview(
                context, ref, selectedMonth, monthExpenses,
                monthTotal, prevTotal, byCategory),
            const SizedBox(height: 20),
            _buildChartsRow(context, budgetAsync, cleaningAsync),
            const SizedBox(height: 20),
            _buildUrgentItems(context, cleaningAsync, shoppingAsync),
            const SizedBox(height: 20),
            _buildTodaysPlan(
                context, cleaningAsync, shoppingAsync, budgetAsync, healthAsync),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${days[now.weekday - 1]}, ${monthShort[now.month - 1]} ${now.day}, ${now.year}';
    final cs = Theme.of(context).colorScheme;
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            // Month selector
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MonthNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      ref.read(dashboardMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month - 1);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          monthNames[selectedMonth.month - 1],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCurrentMonth
                                ? AppTheme.primaryPurple
                                : cs.onSurface,
                          ),
                        ),
                        Text(
                          '${selectedMonth.year}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MonthNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: isCurrentMonth
                        ? null
                        : () {
                            ref.read(dashboardMonthProvider.notifier).state =
                                DateTime(selectedMonth.year,
                                    selectedMonth.month + 1);
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview(
      BuildContext context,
      WidgetRef ref,
      DateTime selectedMonth,
      List<Expense> monthExpenses,
      double monthTotal,
      double prevTotal,
      Map<String, double> byCategory) {
    final cs = Theme.of(context).colorScheme;
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthLabel =
        '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}';
    final diff = monthTotal - prevTotal;
    final diffPct = prevTotal > 0 ? (diff / prevTotal * 100) : 0.0;
    final isUp = diff > 0;

    const colors = [
      Color(0xFF7C4DFF), Color(0xFF00BFA5), Color(0xFFFF6B6B),
      Color(0xFFFFD200), Color(0xFF4CAF50), Color(0xFF2196F3),
      Color(0xFFE91E63), Color(0xFFFF9800),
    ];

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title + total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Expenses',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthLabel,
                    style: GoogleFonts.inter(
                        color: AppTheme.primaryPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Total + vs previous month
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Spent',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: cs.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 2),
                      Text(
                        '₹${monthTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
                if (prevTotal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUp
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isUp ? Colors.red : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isUp ? '+' : ''}${diffPct.toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                  color: isUp ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                            Text(
                              'vs prev month',
                              style: GoogleFonts.inter(
                                  color: (isUp ? Colors.red : Colors.green)
                                      .withOpacity(0.7),
                                  fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Category breakdown
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No expenses recorded for $monthLabel',
                    style: GoogleFonts.inter(
                        color: cs.onSurface.withOpacity(0.4), fontSize: 13),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 16),
              Text('By Category',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.5))),
              const SizedBox(height: 10),
              ...sorted.take(5).toList().asMap().entries.map<Widget>((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final pct = monthTotal > 0 ? cat.value / monthTotal : 0.0;
                final color = colors[idx % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: Text(
                          cat.key,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: cs.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: val,
                              backgroundColor: color.withOpacity(0.1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '₹${cat.value.toStringAsFixed(0)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (sorted.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${sorted.length - 5} more categories',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.4)),
                  ),
                ),
            ],
            // Expense count chip
            if (monthExpenses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.receipt_long_rounded,
                    label: '${monthExpenses.length} transactions',
                    color: AppTheme.primaryPurple,
                  ),
                  if (sorted.isNotEmpty)
                    _InfoChip(
                      icon: Icons.category_rounded,
                      label: 'Top: ${sorted.first.key}',
                      color: AppTheme.accentTeal,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, int overdueTasks, int itemsToBuy,
      double budgetUsed, double healthScore) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final cards = [
      _StatCardData(
        title: 'Overdue Tasks',
        value: '$overdueTasks',
        subtitle: 'Need attention',
        icon: Icons.warning_amber_rounded,
        gradient: const [Color(0xFFFF6B6B), Color(0xFFEE0979)],
      ),
      _StatCardData(
        title: 'To Buy',
        value: '$itemsToBuy',
        subtitle: 'Items pending',
        icon: Icons.shopping_cart_rounded,
        gradient: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
      _StatCardData(
        title: 'Budget Used',
        value: '${(budgetUsed * 100).toStringAsFixed(0)}%',
        subtitle: 'of total budget',
        icon: Icons.account_balance_wallet_rounded,
        gradient: budgetUsed > 1.0
            ? const [Color(0xFFFF6B6B), Color(0xFFEE0979)]
            : budgetUsed > 0.9
                ? const [Color(0xFFFFD200), Color(0xFFFF8C00)]
                : const [Color(0xFF7C4DFF), Color(0xFF00BFA5)],
      ),
      _StatCardData(
        title: 'Health Score',
        value: '${healthScore.toStringAsFixed(0)}%',
        subtitle: 'Daily habits',
        icon: Icons.favorite_rounded,
        gradient: const [Color(0xFF4776E6), Color(0xFF8E54E9)],
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _StatCard(data: c),
                  ),
                ))
            .toList(),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: cards.map((c) => _StatCard(data: c)).toList(),
    );
  }

  Widget _buildChartsRow(BuildContext context,
      AsyncValue<List<BudgetCategory>> budgetAsync,
      AsyncValue<List<CleaningTask>> cleaningAsync) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final charts = [
      _buildBudgetPieChart(context, budgetAsync),
      _buildTaskPieChart(context, cleaningAsync),
    ];

    if (isWide) {
      return Row(
        children: charts
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: [
        charts[0],
        const SizedBox(height: 12),
        charts[1],
      ],
    );
  }

  Widget _buildBudgetPieChart(BuildContext context, AsyncValue<List<BudgetCategory>> budgetAsync) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget Breakdown',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: budgetAsync.when(
                data: (cats) {
                  if (cats.isEmpty) {
                    return const Center(child: Text('No data'));
                  }
                  final colors = [
                    const Color(0xFF4CAF50),
                    const Color(0xFFFF9800),
                    const Color(0xFFF44336),
                    const Color(0xFF2196F3),
                    const Color(0xFFE91E63),
                    AppTheme.primaryPurple,
                  ];
                  final sections = cats.asMap().entries.map<PieChartSectionData>((e) {
                    return PieChartSectionData(
                      value: e.value.budgetAmount,
                      color: colors[e.key % colors.length],
                      title: e.value.category.length > 6
                          ? '${e.value.category.substring(0, 5)}..'
                          : e.value.category,
                      titleStyle: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      radius: 60,
                    );
                  }).toList();
                  return PieChart(PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ));
                },
                loading: () => _shimmerBox(180),
                error: (e, _) => const Center(child: Text('Error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPieChart(BuildContext context, AsyncValue<List<CleaningTask>> cleaningAsync) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Status',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: cleaningAsync.when(
                data: (tasks) {
                  final done = tasks.where((t) => t.status.name == 'done').length;
                  final overdue = tasks.where((t) => t.isOverdue).length;
                  final pending = tasks.length - done - overdue;
                  final sections = [
                    PieChartSectionData(
                      value: done.toDouble(),
                      color: const Color(0xFF4CAF50),
                      title: 'Done\n$done',
                      titleStyle: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: overdue.toDouble(),
                      color: const Color(0xFFF44336),
                      title: 'Overdue\n$overdue',
                      titleStyle: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: pending > 0 ? pending.toDouble() : 0.001,
                      color: const Color(0xFFFF9800),
                      title: 'Pending\n$pending',
                      titleStyle: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      radius: 60,
                    ),
                  ];
                  return PieChart(PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ));
                },
                loading: () => _shimmerBox(180),
                error: (e, _) => const Center(child: Text('Error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentItems(BuildContext context,
      AsyncValue<List<CleaningTask>> cleaningAsync,
      AsyncValue<List<ShoppingItem>> shoppingAsync) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgent Items',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        cleaningAsync.when(
          data: (tasks) {
            final overdue = tasks
                .where((t) => t.isOverdue)
                .toList()
              ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
            if (overdue.isEmpty) {
              return _emptyState(context, 'No overdue tasks', Icons.check_circle_rounded);
            }
            return Column(
              children: overdue
                  .take(3)
                  .map((t) => _UrgentTaskTile(task: t))
                  .toList(),
            );
          },
          loading: () => _shimmerBox(100),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        shoppingAsync.when(
          data: (items) {
            final highPri = items
                .where((i) => !i.bought && i.priority == ItemPriority.high)
                .toList();
            return Column(
              children: highPri
                  .take(3)
                  .map((i) => _UrgentShoppingTile(item: i))
                  .toList(),
            );
          },
          loading: () => _shimmerBox(80),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTodaysPlan(
      BuildContext context,
      AsyncValue<List<CleaningTask>> cleaningAsync,
      AsyncValue<List<ShoppingItem>> shoppingAsync,
      AsyncValue<List<BudgetCategory>> budgetAsync,
      AsyncValue<List<HealthHabit>> healthAsync) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Plan",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cleaningAsync.when(
                  data: (tasks) {
                    final todayTasks = tasks.where((t) => t.isDueToday || t.isOverdue).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: todayTasks
                          .take(4)
                          .map((t) => _PlanItem(
                                icon: Icons.cleaning_services_rounded,
                                color: t.isOverdue
                                    ? Colors.red
                                    : AppTheme.accentTeal,
                                text: '${t.name} - ${t.room}',
                                badge: t.isOverdue ? 'OVERDUE' : 'TODAY',
                              ))
                          .toList(),
                    );
                  },
                  loading: () => _shimmerBox(60),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                healthAsync.when(
                  data: (habits) {
                    final incomplete = habits.where((h) => !h.isCompleted).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: incomplete
                          .take(3)
                          .map((h) => _PlanItem(
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFFE91E63),
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
                budgetAsync.when(
                  data: (cats) {
                    final overBudget = cats.where((c) => c.isOverBudget).toList();
                    return Column(
                      children: overBudget
                          .take(2)
                          .map((c) => _PlanItem(
                                icon: Icons.warning_amber_rounded,
                                color: Colors.red,
                                text:
                                    '${c.category} over budget by ₹${(c.spentAmount - c.budgetAmount).toStringAsFixed(0)}',
                                badge: 'BUDGET',
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
        ),
      ],
    );
  }

  // ─── Today's Nutrition ──────────────────────────────────────────

  Widget _buildTodaysNutrition(BuildContext context,
      AsyncValue<List<FoodEntry>> foodAsync, AsyncValue<int> goalAsync) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Nutrition",
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                ),
                foodAsync.when(
                  data: (entries) => _InfoChip(
                    icon: Icons.restaurant_menu_rounded,
                    label: '${entries.length} items logged',
                    color: const Color(0xFFFF9800),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            foodAsync.when(
              data: (entries) {
                final goal = goalAsync.when(
                    data: (g) => g.toDouble(),
                    loading: () => 2000.0,
                    error: (_, __) => 2000.0);
                final totalCals =
                    entries.fold(0.0, (s, e) => s + e.calories);
                final totalProtein =
                    entries.fold(0.0, (s, e) => s + e.protein);
                final totalCarbs =
                    entries.fold(0.0, (s, e) => s + e.carbs);
                final totalFat = entries.fold(0.0, (s, e) => s + e.fat);
                final progress =
                    goal > 0 ? (totalCals / goal).clamp(0.0, 1.0) : 0.0;
                final isOver = totalCals > goal;
                final ringColor =
                    isOver ? Colors.red : AppTheme.primaryPurple;
                final hasMacros =
                    totalProtein + totalCarbs + totalFat > 0;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Calorie ring
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(96, 96),
                            painter: _DashCalorieRingPainter(
                              progress: progress,
                              ringColor: ringColor,
                              bgColor:
                                  cs.onSurface.withOpacity(0.08),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalCals.toInt().toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isOver
                                      ? Colors.red
                                      : cs.onSurface,
                                ),
                              ),
                              Text(
                                'kcal',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Macro bars
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dashMacroBar(cs, 'Protein', totalProtein, 150,
                              const Color(0xFFFF5722)),
                          const SizedBox(height: 7),
                          _dashMacroBar(cs, 'Carbs', totalCarbs, 250,
                              const Color(0xFFFFC107)),
                          const SizedBox(height: 7),
                          _dashMacroBar(cs, 'Fat', totalFat, 65,
                              const Color(0xFF2196F3)),
                          const SizedBox(height: 8),
                          Text(
                            isOver
                                ? 'Over by ${(totalCals - goal).toInt()} kcal'
                                : '${(goal - totalCals).toInt()} kcal left of ${goal.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOver
                                  ? Colors.red
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Macro donut
                    if (hasMacros) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: PieChart(PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: totalProtein * 4,
                              color: const Color(0xFFFF5722),
                              title: '',
                              radius: 12,
                            ),
                            PieChartSectionData(
                              value: totalCarbs * 4,
                              color: const Color(0xFFFFC107),
                              title: '',
                              radius: 12,
                            ),
                            PieChartSectionData(
                              value: totalFat * 9,
                              color: const Color(0xFF2196F3),
                              title: '',
                              radius: 12,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 26,
                        )),
                      ),
                    ],
                  ],
                );
              },
              loading: () => _shimmerBox(96),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashMacroBar(
      ColorScheme cs, String label, double current, double target, Color color) {
    final progress =
        target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: cs.onSurface.withOpacity(0.55))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.onSurface.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('${current.toInt()}g',
            style: GoogleFonts.inter(
                fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String message, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentTeal, size: 20),
          const SizedBox(width: 8),
          Text(message,
              style: GoogleFonts.inter(
                  color: cs.onSurface.withOpacity(0.6), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _shimmerBox(double height) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A2E),
      highlightColor: const Color(0xFF252540),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ─── Month nav button ─────────────────────────────────────────────

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _MonthNavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? cs.onSurface.withOpacity(0.2)
              : cs.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: data.gradient.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: Colors.white70, size: 20),
              Text(
                data.value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentTaskTile extends StatelessWidget {
  final CleaningTask task;
  const _UrgentTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: task.daysOverdue > 7 ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(task.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text('${task.room} • ${task.daysOverdue} days overdue',
            style: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'OVERDUE',
            style: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _UrgentShoppingTile extends StatelessWidget {
  final ShoppingItem item;
  const _UrgentShoppingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart_rounded, color: Colors.red, size: 20),
        title: Text(item.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text('${item.category} • ₹${item.cost}',
            style: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'HIGH',
            style: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String badge;

  const _PlanItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: cs.onSurface, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calorie Ring Painter (Dashboard) ────────────────────────────

class _DashCalorieRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgColor;

  const _DashCalorieRingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 9.0;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashCalorieRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
