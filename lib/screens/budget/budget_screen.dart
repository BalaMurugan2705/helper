import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../models/budget_category.dart';
import '../../providers/providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);

    return Scaffold(
      body: budgetAsync.when(
        data: (cats) => _buildContent(context, ref, cats),
        loading: () => _loadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null, service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<BudgetCategory> cats) {
    final cs = Theme.of(context).colorScheme;
    final totalBudget = cats.fold(0.0, (s, c) => s + c.budgetAmount);
    final totalSpent = cats.fold(0.0, (s, c) => s + c.spentAmount);
    final overBudget = cats.where((c) => c.isOverBudget).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Tracker',
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 16),
          _buildSummaryCard(context, totalBudget, totalSpent, overBudget),
          const SizedBox(height: 20),
          _buildBarChart(context, cats),
          const SizedBox(height: 20),
          Text('Categories',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 12),
          ...cats.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetCategoryCard(category: c),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalBudget,
      double totalSpent, int overBudget) {
    final pct = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final over = totalSpent > totalBudget;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: over
              ? [const Color(0xFFFF6B6B), const Color(0xFFEE0979)]
              : [AppTheme.primaryPurple, AppTheme.accentTeal],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Budget',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12)),
                  Text('₹${totalBudget.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Spent',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12)),
                  Text('₹${totalSpent.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(1)}% used',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
              if (overBudget > 0)
                Text(
                  '$overBudget over budget',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      BuildContext context, List<BudgetCategory> cats) {
    final cs = Theme.of(context).colorScheme;
    if (cats.isEmpty) return const SizedBox.shrink();

    final maxVal = cats
        .map((c) => [c.budgetAmount, c.spentAmount])
        .expand((e) => e)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget vs Spent',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: cs.onSurface.withOpacity(0.1),
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
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= cats.length) {
                            return const SizedBox.shrink();
                          }
                          final label = cats[idx].category.length > 5
                              ? cats[idx].category.substring(0, 5)
                              : cats[idx].category;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label,
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: cs.onSurface.withOpacity(0.6))),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  barGroups: cats.asMap().entries.map((e) {
                    final i = e.key;
                    final cat = e.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: cat.budgetAmount,
                          color: AppTheme.primaryPurple.withOpacity(0.5),
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: cat.spentAmount,
                          color: cat.isOverBudget
                              ? Colors.red
                              : AppTheme.accentTeal,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      barsSpace: 4,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppTheme.primaryPurple.withOpacity(0.5), label: 'Budget'),
                const SizedBox(width: 16),
                _LegendItem(color: AppTheme.accentTeal, label: 'Spent'),
              ],
            ),
          ],
        ),
      ),
    );
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
                height: 100,
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6), fontSize: 11)),
      ],
    );
  }
}

class BudgetCategoryCard extends ConsumerWidget {
  final BudgetCategory category;
  const BudgetCategoryCard({super.key, required this.category});

  Color get _progressColor {
    final pct = category.percentUsed;
    if (pct > 1.0) return Colors.red;
    if (pct > 0.9) return Colors.orange;
    if (pct > 0.7) return Colors.yellow.shade700;
    return Colors.green;
  }

  IconData _iconFromString(String icon) {
    switch (icon) {
      case 'shopping_basket':
        return Icons.shopping_basket_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    final cs = Theme.of(context).colorScheme;
    final pct = category.percentUsed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_iconFromString(category.icon),
                      color: _progressColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.category,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, color: cs.onSurface)),
                      Text(
                        '₹${category.spentAmount.toStringAsFixed(0)} / ₹${category.budgetAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                            color: cs.onSurface.withOpacity(0.6),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (category.isOverBudget)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'OVER BUDGET',
                      style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: _progressColor,
                    fontSize: 14,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: cs.onSurface.withOpacity(0.5), size: 18),
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showAddEditModal(context, null, category,
                          service: service);
                    } else if (v == 'delete') {
                      service.deleteBudgetCategory(category.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (ctx, val, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val,
                  backgroundColor: _progressColor.withOpacity(0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_progressColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.isOverBudget
                  ? 'Over by ₹${(category.spentAmount - category.budgetAmount).toStringAsFixed(0)}'
                  : 'Remaining: ₹${category.remaining.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  color: category.isOverBudget
                      ? Colors.red
                      : cs.onSurface.withOpacity(0.5),
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef? ref,
    BudgetCategory? cat, {dynamic service}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _BudgetCategoryModal(category: cat, service: service),
  );
}

class _BudgetCategoryModal extends StatefulWidget {
  final BudgetCategory? category;
  final dynamic service;
  const _BudgetCategoryModal({this.category, required this.service});

  @override
  State<_BudgetCategoryModal> createState() => _BudgetCategoryModalState();
}

class _BudgetCategoryModalState extends State<_BudgetCategoryModal> {
  late TextEditingController _categoryCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _spentCtrl;
  String _icon = 'category';

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(text: widget.category?.category ?? '');
    _budgetCtrl = TextEditingController(
        text: widget.category?.budgetAmount.toStringAsFixed(0) ?? '');
    _spentCtrl = TextEditingController(
        text: widget.category?.spentAmount.toStringAsFixed(0) ?? '');
    _icon = widget.category?.icon ?? 'category';
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _budgetCtrl.dispose();
    _spentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
            widget.category == null ? 'Add Budget Category' : 'Edit Budget Category',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category Name')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Budget (₹)')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _spentCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Amount Spent (₹)')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_categoryCtrl.text.isEmpty) return;
                final newCat = BudgetCategory(
                  id: widget.category?.id ?? '',
                  category: _categoryCtrl.text.trim(),
                  budgetAmount: double.tryParse(_budgetCtrl.text) ?? 0,
                  spentAmount: double.tryParse(_spentCtrl.text) ?? 0,
                  icon: _icon,
                  color: '#7C4DFF',
                );
                if (widget.category == null) {
                  await widget.service.addBudgetCategory(newCat);
                } else {
                  await widget.service.updateBudgetCategory(newCat);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(widget.category == null ? 'Add Category' : 'Update Category'),
            ),
          ),
        ],
      ),
    );
  }
}
