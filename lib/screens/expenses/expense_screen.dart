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

// ─── Filter Enum ──────────────────────────────────────────────────

enum ExpensePeriod { week, month, all }

final _periodProvider = StateProvider<ExpensePeriod>((ref) => ExpensePeriod.month);

// ─── Main Screen ──────────────────────────────────────────────────

class ExpenseScreen extends ConsumerWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final period = ref.watch(_periodProvider);
    final totalThisMonth = ref.watch(totalThisMonthProvider);
    final categoryMap = ref.watch(expenseByCategoryProvider);

    return Scaffold(
      body: expensesAsync.when(
        data: (all) {
          final filtered = _filterExpenses(all, period);
          return _ExpenseContent(
            allExpenses: all,
            filtered: filtered,
            period: period,
            totalThisMonth: totalThisMonth,
            categoryMap: categoryMap,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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

  List<Expense> _filterExpenses(List<Expense> all, ExpensePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ExpensePeriod.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return all.where((e) => e.date.isAfter(weekAgo)).toList();
      case ExpensePeriod.month:
        return all
            .where((e) => e.date.year == now.year && e.date.month == now.month)
            .toList();
      case ExpensePeriod.all:
        return all;
    }
  }
}

// ─── Content Widget ───────────────────────────────────────────────

class _ExpenseContent extends ConsumerWidget {
  final List<Expense> allExpenses;
  final List<Expense> filtered;
  final ExpensePeriod period;
  final double totalThisMonth;
  final Map<String, double> categoryMap;

  const _ExpenseContent({
    required this.allExpenses,
    required this.filtered,
    required this.period,
    required this.totalThisMonth,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = filtered.fold(0.0, (s, e) => s + e.amount);
    final avgPerDay = _avgPerDay(filtered, period);

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
                _buildPeriodToggle(context, ref),
                const SizedBox(height: 16),
                if (filtered.isNotEmpty) ...[
                  _buildSpendingChart(context, filtered, period),
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

  double _avgPerDay(List<Expense> expenses, ExpensePeriod period) {
    if (expenses.isEmpty) return 0;
    int days;
    switch (period) {
      case ExpensePeriod.week:
        days = 7;
        break;
      case ExpensePeriod.month:
        final now = DateTime.now();
        days = now.day;
        break;
      case ExpensePeriod.all:
        if (expenses.isEmpty) return 0;
        final oldest = expenses.last.date;
        days = DateTime.now().difference(oldest).inDays + 1;
        break;
    }
    return expenses.fold(0.0, (s, e) => s + e.amount) / days;
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
                  Icons.calendar_today_rounded,
                  'This Month: ₹${totalThisMonth.toStringAsFixed(0)}'),
              const SizedBox(width: 12),
              _summaryPill(
                  Icons.trending_up_rounded,
                  'Avg/day: ₹${avgPerDay.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentExpenses.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 13),
          const SizedBox(width: 5),
          Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_periodProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: ExpensePeriod.values.map((p) {
          final selected = p == current;
          final labels = {
            ExpensePeriod.week: 'This Week',
            ExpensePeriod.month: 'This Month',
            ExpensePeriod.all: 'All Time',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(_periodProvider.notifier).state = p,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accentExpenses : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  labels[p]!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpendingChart(
      BuildContext context, List<Expense> expenses, ExpensePeriod period) {
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
                    getTooltipColor: (_) => AppColors.darkSurface,
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
              const Icon(Icons.receipt_long_rounded,
                  size: 48, color: AppColors.textSubtle),
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
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.textSubtle),
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

class _ExpenseModal extends StatefulWidget {
  final FirebaseService service;
  final Expense? expense;
  const _ExpenseModal({required this.service, this.expense});

  @override
  State<_ExpenseModal> createState() => _ExpenseModalState();
}

class _ExpenseModalState extends State<_ExpenseModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late TextEditingController _categoryCtrl;
  late DateTime _date;
  late PaymentMethod _paymentMethod;
  bool _saving = false;

  static const _suggestedCategories = [
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
            children: _suggestedCategories.map((cat) {
              final selected = _categoryCtrl.text == cat;
              return GestureDetector(
                onTap: () => setState(() => _categoryCtrl.text = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentExpenses.withValues(alpha: 0.15)
                        : AppColors.textMuted.withValues(alpha: 0.07),
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
                          : AppColors.textMuted,
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
                      border: Border.all(color: AppColors.glassBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.textMuted),
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
