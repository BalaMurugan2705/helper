import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
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
        loading: () => _loadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddEditModal(context, ref.read(firebaseServiceProvider)!, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.primaryPurple,
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

  Widget _loadingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF1A1A2E),
              highlightColor: const Color(0xFF252540),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
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
    final cs = Theme.of(context).colorScheme;
    final total = filtered.fold(0.0, (s, e) => s + e.amount);
    final avgPerDay = _avgPerDay(filtered, period);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expense Tracker',
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Expenses',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('₹${total.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(text,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final current = ref.watch(_periodProvider);
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
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
                  color: selected ? AppTheme.primaryPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  labels[p]!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? Colors.white
                        : cs.onSurface.withOpacity(0.6),
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
    final cs = Theme.of(context).colorScheme;

    // Build daily totals for bar chart
    final Map<String, double> dailyTotals = {};
    for (final e in expenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + e.amount;
    }

    final sortedKeys = dailyTotals.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox.shrink();

    final maxY = dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Spending',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
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
                      color: cs.onSurface.withOpacity(0.08),
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
                            child: Text(label,
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: cs.onSurface.withOpacity(0.5))),
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
                            colors: [AppTheme.primaryPurple, AppTheme.accentTeal],
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
                      getTooltipColor: (_) => cs.surface,
                      getTooltipItem: (group, _, rod, __) {
                        return BarTooltipItem(
                          '₹${rod.toY.toStringAsFixed(0)}',
                          GoogleFonts.inter(
                              color: AppTheme.primaryPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, List<Expense> expenses) {
    final cs = Theme.of(context).colorScheme;
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    if (map.isEmpty) return const SizedBox.shrink();

    final total = map.values.fold(0.0, (s, v) => s + v);
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    const colors = [
      Color(0xFF7C4DFF),
      Color(0xFF00BFA5),
      Color(0xFFFF6B6B),
      Color(0xFFFFD200),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFE91E63),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Category',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
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
                            Text(cat.key,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: cs.onSurface)),
                          ],
                        ),
                        Text(
                          '₹${cat.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
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
                          backgroundColor: color.withOpacity(0.12),
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
      ),
    );
  }

  Widget _buildTransactionList(
      BuildContext context, WidgetRef ref, List<Expense> expenses) {
    final cs = Theme.of(context).colorScheme;
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 48, color: cs.onSurface.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text('No expenses yet',
                  style: GoogleFonts.inter(
                      color: cs.onSurface.withOpacity(0.4), fontSize: 15)),
              const SizedBox(height: 4),
              Text('Tap + to add your first expense',
                  style: GoogleFonts.inter(
                      color: cs.onSurface.withOpacity(0.3), fontSize: 12)),
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
        Text('Transactions',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
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
                    Text(group.key,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.5))),
                    Text('₹${dayTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.5))),
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

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.upi:
        return Icons.qr_code_rounded;
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.netBanking:
        return Icons.account_balance_rounded;
      case PaymentMethod.other:
        return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_paymentIcon(expense.paymentMethod),
              color: AppTheme.primaryPurple, size: 20),
        ),
        title: Text(expense.title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: cs.onSurface)),
        subtitle: Text(
          expense.category +
              (expense.note.isNotEmpty ? ' • ${expense.note}' : ''),
          style: GoogleFonts.inter(
              color: cs.onSurface.withOpacity(0.5), fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: cs.onSurface),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: cs.onSurface.withOpacity(0.4)),
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) =>
        _ExpenseModal(service: service, expense: expense),
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
    final cs = Theme.of(context).colorScheme;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.expense == null ? 'Add Expense' : 'Edit Expense',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 16),
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
                          ? AppTheme.primaryPurple.withOpacity(0.15)
                          : cs.onSurface.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryPurple
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: selected
                            ? AppTheme.primaryPurple
                            : cs.onSurface.withOpacity(0.6),
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
            // Date & payment method row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: cs.onSurface.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16, color: cs.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Text(
                            '${_date.day} ${months[_date.month - 1]} ${_date.year}',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: cs.onSurface),
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
            Text('Payment Method',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.5))),
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
                  label: Text(labels[m]!,
                      style: GoogleFonts.inter(fontSize: 12)),
                  selected: selected,
                  selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
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
                  backgroundColor: AppTheme.primaryPurple,
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
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
