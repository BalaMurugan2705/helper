import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Aurora Hero Header ─────────────────────────────
            AuroraHero(
              accent: AppColors.accentDashboard,
              eyebrow: 'DASHBOARD',
              title: 'HomeSync',
              subtitle: '$overdueTasks overdue · Budget ${budgetUsed.toInt()}% · Health ${healthScore.toInt()}',
              trailing: _buildMonthSelector(context, ref, selectedMonth),
            ),
            // ── Content with padding ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(
                      context, overdueTasks, itemsToBuy, budgetUsed, healthScore),
                  const SizedBox(height: 24),
                  _buildTodaysNutrition(context, foodAsync, calorieGoalAsync),
                  const SizedBox(height: 24),
                  _buildMonthlyOverview(
                      context, ref, selectedMonth, monthExpenses,
                      monthTotal, prevTotal, byCategory),
                  const SizedBox(height: 24),
                  _buildChartsRow(context, budgetAsync, cleaningAsync),
                  const SizedBox(height: 24),
                  _buildUrgentItems(context, cleaningAsync, shoppingAsync),
                  const SizedBox(height: 24),
                  _buildTodaysPlan(
                      context, cleaningAsync, shoppingAsync, budgetAsync, healthAsync),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Month selector widget used as the trailing element in AuroraHero.
  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime selectedMonth) {
    final now = DateTime.now();
    const monthNames = ['January','February','March','April','May','June',
                        'July','August','September','October','November','December'];
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  monthNames[selectedMonth.month - 1],
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isCurrentMonth
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                Text(
                  '${selectedMonth.year}',
                  style: AppTextStyles.bodySmall,
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
                        DateTime(selectedMonth.year, selectedMonth.month + 1);
                  },
          ),
        ],
      ),
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
      AppColors.accentDashboard, AppColors.accentCleaning, AppColors.accentBudget,
      Color(0xFF1A9E6E), Color(0xFFF59E0B), Color(0xFFDC3545),
      AppColors.accentShopping, AppColors.accentHealth,
    ];

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      accent: AppColors.accentDashboard,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title + total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Expenses',
                  style: AppTextStyles.headlineSmall,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentDashboard.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthLabel,
                    style: AppTextStyles.labelAccent.copyWith(color: AppColors.accentDashboard),
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
                      Text('Total Spent', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        '₹${monthTotal.toStringAsFixed(0)}',
                        style: AppTextStyles.statDisplay.copyWith(
                            color: AppColors.accentDashboard),
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
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
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
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: isUp ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'vs prev month',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: (isUp ? Colors.red : Colors.green)
                                      .withValues(alpha: 0.7)),
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
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 16),
              Text('By Category', style: AppTextStyles.labelLarge),
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
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
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
                              backgroundColor: color.withValues(alpha: 0.1),
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
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
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
                    style: AppTextStyles.bodySmall,
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
                    color: AppColors.accentDashboard,
                  ),
                  if (sorted.isNotEmpty)
                    _InfoChip(
                      icon: Icons.category_rounded,
                      label: 'Top: ${sorted.first.key}',
                      color: AppColors.accentBudget,
                    ),
                ],
              ),
            ],
          ],
        ),
    );
  }

  Widget _buildStatCards(BuildContext context, int overdueTasks, int itemsToBuy,
      double budgetUsed, double healthScore) {
    return Row(children: [
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
        accent: AppColors.accentShopping,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TO BUY', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text('$itemsToBuy', style: AppTextStyles.statDisplay.copyWith(color: AppColors.accentShopping)),
          Text('items', style: AppTextStyles.bodySmall),
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
    ]);
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
    return GlassCard(
      accent: AppColors.accentBudget,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Breakdown', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: budgetAsync.when(
              data: (cats) {
                if (cats.isEmpty) {
                  return Center(child: Text('No data', style: AppTextStyles.bodyMedium));
                }
                const colors = [
                  AppColors.accentBudget,
                  AppColors.accentDashboard,
                  AppColors.accentCleaning,
                  Color(0xFF1A9E6E),
                  Color(0xFFF59E0B),
                  Color(0xFFDC3545),
                ];
                final sections = cats.asMap().entries.map<PieChartSectionData>((e) {
                  return PieChartSectionData(
                    value: e.value.budgetAmount,
                    color: colors[e.key % colors.length],
                    title: e.value.category.length > 6
                        ? '${e.value.category.substring(0, 5)}..'
                        : e.value.category,
                    titleStyle: AppTextStyles.bodySmall.copyWith(
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
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => const Center(child: Text('Error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPieChart(BuildContext context, AsyncValue<List<CleaningTask>> cleaningAsync) {
    return GlassCard(
      accent: AppColors.accentCleaning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Status', style: AppTextStyles.headlineSmall),
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
                    color: AppColors.statusDone,
                    title: 'Done\n$done',
                    titleStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600, color: Colors.white),
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: overdue.toDouble(),
                    color: AppColors.statusOverdue,
                    title: 'Overdue\n$overdue',
                    titleStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600, color: Colors.white),
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: pending > 0 ? pending.toDouble() : 0.001,
                    color: AppColors.statusPending,
                    title: 'Pending\n$pending',
                    titleStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600, color: Colors.white),
                    radius: 60,
                  ),
                ];
                return PieChart(PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ));
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => const Center(child: Text('Error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentItems(BuildContext context,
      AsyncValue<List<CleaningTask>> cleaningAsync,
      AsyncValue<List<ShoppingItem>> shoppingAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Urgent Items', color: AppColors.textPrimary),
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
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: "Today's Plan", color: AppColors.textPrimary),
        const SizedBox(height: 12),
        GlassCard(
          accent: AppColors.accentDashboard,
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
                                  ? AppColors.statusOverdue
                                  : AppColors.accentCleaning,
                              text: '${t.name} - ${t.room}',
                              badge: t.isOverdue ? 'OVERDUE' : 'TODAY',
                            ))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
      ],
    );
  }

  // ─── Today's Nutrition ──────────────────────────────────────────

  Widget _buildTodaysNutrition(BuildContext context,
      AsyncValue<List<FoodEntry>> foodAsync, AsyncValue<int> goalAsync) {
    return GlassCard(
      accent: AppColors.accentFood,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Nutrition", style: AppTextStyles.headlineSmall),
              foodAsync.when(
                data: (entries) => _InfoChip(
                  icon: Icons.restaurant_menu_rounded,
                  label: '${entries.length} items logged',
                  color: AppColors.accentFood,
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
                    isOver ? AppColors.statusOverdue : AppColors.accentFood;
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
                              bgColor: AppColors.glassBorder,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalCals.toInt().toString(),
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 20,
                                  color: isOver
                                      ? AppColors.statusOverdue
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text('kcal', style: AppTextStyles.bodySmall),
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
                          _dashMacroBar('Protein', totalProtein, 150,
                              const Color(0xFFFF5722)),
                          const SizedBox(height: 7),
                          _dashMacroBar('Carbs', totalCarbs, 250,
                              const Color(0xFFFFC107)),
                          const SizedBox(height: 7),
                          _dashMacroBar('Fat', totalFat, 65,
                              const Color(0xFF2196F3)),
                          const SizedBox(height: 8),
                          Text(
                            isOver
                                ? 'Over by ${(totalCals - goal).toInt()} kcal'
                                : '${(goal - totalCals).toInt()} kcal left of ${goal.toInt()}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isOver
                                  ? AppColors.statusOverdue
                                  : AppColors.statusDone,
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
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _dashMacroBar(
      String label, double current, double target, Color color) {
    final progress =
        target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.glassBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('${current.toInt()}g', style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBudget, size: 20),
          const SizedBox(width: 8),
          Text(message, style: AppTextStyles.bodyMedium),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? AppColors.textSubtle
              : AppColors.textMuted,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelAccent.copyWith(color: color)),
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
    final accent = task.daysOverdue > 7 ? AppColors.statusOverdue : AppColors.statusPending;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${task.room} · ${task.daysOverdue}d overdue',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${task.daysOverdue}d',
              style: AppTextStyles.labelAccent.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentShoppingTile extends StatelessWidget {
  final ShoppingItem item;
  const _UrgentShoppingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accentExpenses;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_cart_rounded,
                color: accent, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${item.category} · ₹${item.cost}',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              'HIGH',
              style: AppTextStyles.labelAccent.copyWith(color: accent),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: AppTextStyles.bodyMedium),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              badge,
              style: AppTextStyles.labelAccent.copyWith(color: color),
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


// ─── Section Title ────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accentDashboard,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
