import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/expense.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';

// ─── Filter Providers ─────────────────────────────────────────────

enum _FilterMode { month, dateRange, week, all }

final _filterModeProvider =
    StateProvider<_FilterMode>((ref) => _FilterMode.month);

final _expenseMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final _dateFromProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final _dateToProvider = StateProvider<DateTime>((ref) => DateTime.now());

final _categoryFilterProvider = StateProvider<String?>((ref) => null);

// ─── Main Screen ──────────────────────────────────────────────────

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final totalThisMonth = ref.watch(totalThisMonthProvider);

    return Scaffold(
      body: expensesAsync.when(
        data: (all) => _ExpenseContent(
          allExpenses: all,
          totalThisMonth: totalThisMonth,
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddEditModal(context, ref.read(firebaseServiceProvider)!, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppColors.accentExpenses,
      ),
    );
  }
}

// ─── Content Widget ───────────────────────────────────────────────

class _ExpenseContent extends ConsumerWidget {
  final List<Expense> allExpenses;
  final double totalThisMonth;

  const _ExpenseContent({
    required this.allExpenses,
    required this.totalThisMonth,
  });

  static const _monthLabels = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode          = ref.watch(_filterModeProvider);
    final selectedMonth = ref.watch(_expenseMonthProvider);
    final dateFrom      = ref.watch(_dateFromProvider);
    final dateTo        = ref.watch(_dateToProvider);
    final selectedCat   = ref.watch(_categoryFilterProvider);

    // Step 1 — apply date filter
    final dateFiltered =
        _applyDateFilter(allExpenses, mode, selectedMonth, dateFrom, dateTo);

    // Step 2 — derive category list from date-filtered set
    final categories = (dateFiltered.map((e) => e.category).toSet().toList()
      ..sort());

    // Step 3 — apply category filter
    final filtered = selectedCat == null
        ? dateFiltered
        : dateFiltered.where((e) => e.category == selectedCat).toList();

    final total     = filtered.fold(0.0, (s, e) => s + e.amount);
    final avgPerDay = _avgPerDay(filtered, mode, selectedMonth, dateFrom, dateTo);

    return Column(
      children: [
        AuroraHero(
          accent: AppColors.accentExpenses,
          eyebrow: 'FINANCE · EXPENSES',
          title: 'Expenses',
          subtitle: '₹${total.toStringAsFixed(0)} total',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, total, avgPerDay),
                const SizedBox(height: 16),
                _buildFilters(context, ref, mode, selectedMonth, dateFrom, dateTo, categories, selectedCat),
                const SizedBox(height: 16),
                if (filtered.isNotEmpty) ...[
                  _buildSpendingChart(context, filtered),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(context, filtered),
                  const SizedBox(height: 16),
                ],
                _buildTransactionList(context, ref, filtered),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  List<Expense> _applyDateFilter(List<Expense> all, _FilterMode mode,
      DateTime month, DateTime from, DateTime to) {
    switch (mode) {
      case _FilterMode.week:
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return all.where((e) => e.date.isAfter(weekAgo)).toList();
      case _FilterMode.month:
        return all
            .where((e) =>
                e.date.year == month.year && e.date.month == month.month)
            .toList();
      case _FilterMode.dateRange:
        final start = DateTime(from.year, from.month, from.day);
        final end   = DateTime(to.year, to.month, to.day, 23, 59, 59);
        return all
            .where((e) =>
                !e.date.isBefore(start) && !e.date.isAfter(end))
            .toList();
      case _FilterMode.all:
        return all;
    }
  }

  double _avgPerDay(List<Expense> expenses, _FilterMode mode,
      DateTime selectedMonth, DateTime dateFrom, DateTime dateTo) {
    if (expenses.isEmpty) return 0;
    final now = DateTime.now();
    int days;
    switch (mode) {
      case _FilterMode.week:
        days = 7;
      case _FilterMode.month:
        final isCurrentMonth = selectedMonth.year == now.year &&
            selectedMonth.month == now.month;
        days = isCurrentMonth
            ? now.day
            : DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      case _FilterMode.dateRange:
        days = dateTo.difference(dateFrom).inDays + 1;
      case _FilterMode.all:
        final oldest = expenses.last.date;
        days = now.difference(oldest).inDays + 1;
    }
    return expenses.fold(0.0, (s, e) => s + e.amount) / days.clamp(1, 9999);
  }

  // ── Filter bar ─────────────────────────────────────────────────

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    _FilterMode mode,
    DateTime selectedMonth,
    DateTime dateFrom,
    DateTime dateTo,
    List<String> categories,
    String? selectedCat,
  ) {
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year &&
        selectedMonth.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Mode toggle ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: context.appColors.glassCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.glassBorder),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: _FilterMode.values.map((m) {
              final labels = {
                _FilterMode.month:     'Month',
                _FilterMode.dateRange: 'Date Range',
                _FilterMode.week:      'This Week',
                _FilterMode.all:       'All Time',
              };
              final selected = m == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(_filterModeProvider.notifier).state = m;
                    ref.read(_categoryFilterProvider.notifier).state = null;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentExpenses
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      labels[m]!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected
                            ? AppColors.textPrimary
                            : context.appColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Month navigator ────────────────────────────────────
        if (mode == _FilterMode.month) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: context.appColors.textMuted,
                onPressed: () {
                  final prev = DateTime(
                      selectedMonth.year, selectedMonth.month - 1);
                  ref.read(_expenseMonthProvider.notifier).state = prev;
                  ref.read(_categoryFilterProvider.notifier).state = null;
                },
              ),
              Text(
                '${_monthLabels[selectedMonth.month - 1]} ${selectedMonth.year}',
                style: AppTextStyles.titleMedium,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth
                      ? context.appColors.textSubtle
                      : context.appColors.textMuted,
                ),
                onPressed: isCurrentMonth
                    ? null
                    : () {
                        final next = DateTime(
                            selectedMonth.year, selectedMonth.month + 1);
                        ref.read(_expenseMonthProvider.notifier).state = next;
                        ref.read(_categoryFilterProvider.notifier).state =
                            null;
                      },
              ),
            ],
          ),
        ],

        // ── Date range pickers ─────────────────────────────────
        if (mode == _FilterMode.dateRange) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _datePicker(
                  context: context,
                  label: 'From',
                  date: dateFrom,
                  firstDate: DateTime(2020),
                  lastDate: dateTo,
                  onPicked: (d) {
                    ref.read(_dateFromProvider.notifier).state = d;
                    ref.read(_categoryFilterProvider.notifier).state = null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: context.appColors.textMuted),
              ),
              Expanded(
                child: _datePicker(
                  context: context,
                  label: 'To',
                  date: dateTo,
                  firstDate: dateFrom,
                  lastDate: DateTime.now(),
                  onPicked: (d) {
                    ref.read(_dateToProvider.notifier).state = d;
                    ref.read(_categoryFilterProvider.notifier).state = null;
                  },
                ),
              ),
            ],
          ),
        ],

        // ── Category chips ─────────────────────────────────────
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _catChip(context, 'All', selectedCat == null, () {
                  ref.read(_categoryFilterProvider.notifier).state = null;
                }),
                ...categories.map((c) => _catChip(
                      context,
                      c,
                      selectedCat == c,
                      () {
                        ref.read(_categoryFilterProvider.notifier).state =
                            selectedCat == c ? null : c;
                      },
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _catChip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentExpenses.withValues(alpha: 0.18)
              : context.appColors.glassCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? AppColors.accentExpenses : context.appColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected
                ? AppColors.accentExpenses
                : context.appColors.textMuted,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _datePicker({
    required BuildContext context,
    required String label,
    required DateTime date,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    final d = _monthLabels[date.month - 1];
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date.isBefore(firstDate)
              ? firstDate
              : date.isAfter(lastDate)
                  ? lastDate
                  : date,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appColors.glassCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accentExpenses.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: AppColors.accentExpenses),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted, fontSize: 10)),
                  Text('${date.day} $d ${date.year}',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, double total, double avgPerDay) {
    return GlassCard(
      accent: AppColors.accentExpenses,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Expenses', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: AppTextStyles.statDisplay.copyWith(color: AppColors.accentExpenses),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryPill(
                  context,
                  Icons.calendar_today_rounded,
                  'This Month: ₹${totalThisMonth.toStringAsFixed(0)}'),
              const SizedBox(width: 12),
              _summaryPill(
                  context,
                  Icons.trending_up_rounded,
                  'Avg/day: ₹${avgPerDay.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentExpenses.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.appColors.textPrimary, size: 13),
          const SizedBox(width: 5),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: context.appColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(BuildContext context, List<Expense> expenses) {
    // Build daily totals for bar chart
    final Map<String, double> dailyTotals = {};
    for (final e in expenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + e.amount;
    }

    final sortedKeys = dailyTotals.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox.shrink();

    final maxY = dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.3;

    return GlassCard(
      accent: AppColors.accentExpenses,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Spending', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.glassBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= sortedKeys.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = sortedKeys[idx].split('-');
                        final label = '${parts[2]}/${parts[1]}';
                        // Show every nth label to avoid crowding
                        final step = sortedKeys.length > 10 ? (sortedKeys.length / 6).ceil() : 1;
                        if (idx % step != 0 && idx != sortedKeys.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(label, style: AppTextStyles.bodySmall),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: sortedKeys.asMap().entries.map<BarChartGroupData>((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: dailyTotals[e.value]!,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentExpenses2, AppColors.accentExpenses],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: sortedKeys.length > 15 ? 6 : 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                    getTooltipItem: (group, _, rod, __) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}',
                        AppTextStyles.titleMedium.copyWith(color: AppColors.accentExpenses),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    if (map.isEmpty) return const SizedBox.shrink();

    final total = map.values.fold(0.0, (s, v) => s + v);
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    const colors = [
      Color(0xFFE07B39),
      Color(0xFF50A878),
      Color(0xFFFF6B6B),
      Color(0xFFFFD200),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFE91E63),
    ];

    return GlassCard(
      accent: AppColors.accentExpenses,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By Category', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ...sorted.asMap().entries.map<Widget>((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final pct = total > 0 ? cat.value / total : 0.0;
            final color = colors[idx % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(cat.key, style: AppTextStyles.titleMedium),
                        ],
                      ),
                      Text(
                        '₹${cat.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: val,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      BuildContext context, WidgetRef ref, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 48, color: context.appColors.textSubtle),
              const SizedBox(height: 12),
              Text('No expenses yet', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Text('Tap + to add your first expense', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }

    // Group by date
    final groups = <String, List<Expense>>{};
    for (final e in expenses) {
      final key = _dateLabel(e.date);
      groups.putIfAbsent(key, () => []).add(e);
    }

    final service = ref.read(firebaseServiceProvider)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transactions', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        ...groups.entries.map<Widget>((group) {
          final dayTotal = group.value.fold(0.0, (s, e) => s + e.amount);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(group.key, style: AppTextStyles.bodySmall),
                    Text('₹${dayTotal.toStringAsFixed(0)}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              ...group.value.map<Widget>((e) => _ExpenseTile(
                    expense: e,
                    service: service,
                    onEdit: () => _showAddEditModal(context, service, e),
                  )),
              const SizedBox(height: 4),
            ],
          );
        }),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Expense Tile ─────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final FirebaseService service;
  final VoidCallback onEdit;

  const _ExpenseTile({
    required this.expense,
    required this.service,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassTile(
        dotColor: AppColors.accentExpenses,
        title: expense.title,
        subtitle: expense.category +
            (expense.note.isNotEmpty ? ' · ${expense.note}' : ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(0)}',
              style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accentExpenses),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: context.appColors.textSubtle),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') service.deleteExpense(expense.id);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit Modal ─────────────────────────────────────────────

void _showAddEditModal(
    BuildContext context, FirebaseService service, Expense? expense) {
  showGlassSheet(
    context: context,
    title: expense == null ? 'Add Expense' : 'Edit Expense',
    content: _ExpenseModal(service: service, expense: expense),
  );
}

class _ExpenseModal extends ConsumerStatefulWidget {
  final FirebaseService service;
  final Expense? expense;
  const _ExpenseModal({required this.service, this.expense});

  @override
  ConsumerState<_ExpenseModal> createState() => _ExpenseModalState();
}

class _ExpenseModalState extends ConsumerState<_ExpenseModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late TextEditingController _categoryCtrl;
  late DateTime _date;
  late PaymentMethod _paymentMethod;
  bool _saving = false;

  static const _fallbackCategories = [
    'Groceries', 'Food & Dining', 'Transport', 'Utilities',
    'Entertainment', 'Health', 'Shopping', 'Education', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.expense?.title ?? '');
    _amountCtrl = TextEditingController(
        text: widget.expense != null
            ? widget.expense!.amount.toStringAsFixed(0)
            : '');
    _noteCtrl = TextEditingController(text: widget.expense?.note ?? '');
    _categoryCtrl =
        TextEditingController(text: widget.expense?.category ?? '');
    _date = widget.expense?.date ?? DateTime.now();
    _paymentMethod = widget.expense?.paymentMethod ?? PaymentMethod.upi;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final expense = Expense(
      id: widget.expense?.id ?? '',
      title: _titleCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      category: _categoryCtrl.text.trim().isEmpty
          ? 'Other'
          : _categoryCtrl.text.trim(),
      date: _date,
      note: _noteCtrl.text.trim(),
      paymentMethod: _paymentMethod,
    );
    if (widget.expense == null) {
      await widget.service.addExpense(expense);
    } else {
      await widget.service.updateExpense(expense);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final budgetCategories = ref.watch(budgetCategoryNamesProvider);
    final categories = budgetCategories.isEmpty ? _fallbackCategories : budgetCategories;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Amount row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.receipt_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category field + chips
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: categories.map((cat) {
              final selected = _categoryCtrl.text == cat;
              return GestureDetector(
                onTap: () => setState(() => _categoryCtrl.text = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentExpenses.withValues(alpha: 0.15)
                        : context.appColors.textMuted.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentExpenses
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected
                          ? AppColors.accentExpenses
                          : context.appColors.textMuted,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Date row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.appColors.glassBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: context.appColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          '${_date.day} ${months[_date.month - 1]} ${_date.year}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment method chips
          Text('Payment Method', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PaymentMethod.values.map((m) {
              final selected = _paymentMethod == m;
              final labels = {
                PaymentMethod.cash: 'Cash',
                PaymentMethod.card: 'Card',
                PaymentMethod.upi: 'UPI',
                PaymentMethod.netBanking: 'Net Banking',
                PaymentMethod.other: 'Other',
              };
              return ChoiceChip(
                label: Text(labels[m]!, style: AppTextStyles.bodySmall),
                selected: selected,
                selectedColor: AppColors.accentExpenses.withValues(alpha: 0.2),
                onSelected: (_) =>
                    setState(() => _paymentMethod = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Note field
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.note_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentExpenses,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.expense == null
                          ? 'Add Expense'
                          : 'Update Expense',
                      style: AppTextStyles.titleMedium,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
