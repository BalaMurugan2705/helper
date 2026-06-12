import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/budget_category.dart';
import '../../providers/providers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetWithSpentProvider);

    final totalBudget = budgetAsync.when(
      data: (c) => c.fold(0.0, (s, x) => s + x.budgetAmount),
      loading: () => 0.0, error: (_, __) => 0.0);
    final totalSpent = budgetAsync.when(
      data: (c) => c.fold(0.0, (s, x) => s + x.spentAmount),
      loading: () => 0.0, error: (_, __) => 0.0);
    final pct = totalBudget > 0 ? (totalSpent / totalBudget * 100).toInt() : 0;

    return Scaffold(
      body: Column(
        children: [
          AuroraHero(
            accent: AppColors.accentBudget,
            eyebrow: 'FINANCE · BUDGET',
            title: 'Budget',
            subtitle: totalBudget > 0
                ? '₹${totalSpent.toStringAsFixed(0)} of ₹${totalBudget.toStringAsFixed(0)} used'
                : 'No budget categories yet',
            trailing: totalBudget > 0
                ? StatusChip.custom(
                    label: '$pct%',
                    accent: pct > 100
                        ? AppColors.statusOverdue
                        : pct > 90
                            ? AppColors.statusPending
                            : AppColors.accentBudget,
                  )
                : null,
          ),
          Expanded(
            child: budgetAsync.when(
              data: (cats) => _buildContent(context, cats),
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null,
            service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: Text('Add Category', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.accentBudget,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, List<BudgetCategory> cats) {
    if (cats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: AppColors.textSubtle),
            const SizedBox(height: 12),
            Text('No budget categories', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text('Add categories to start tracking',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(firebaseServiceProvider)
                    ?.seedDefaultBudgetCategories();
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Load Default Categories'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBudget,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    final totalBudget = cats.fold(0.0, (s, c) => s + c.budgetAmount);
    final totalSpent  = cats.fold(0.0, (s, c) => s + c.spentAmount);
    final overBudget  = cats.where((c) => c.isOverBudget).length;
    final over = totalSpent > totalBudget;

    final nextMonth = DateTime(DateTime.now().year, DateTime.now().month + 1);
    final nextLabel =
        '${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][nextMonth.month - 1]} ${nextMonth.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rollover row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final service = ref.read(firebaseServiceProvider);
                  if (service == null) return;
                  await service.rolloverBudgetToNextMonth();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Budget copied to $nextLabel'),
                        backgroundColor: AppColors.accentBudget,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                label: Text('Copy to $nextLabel'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentBudget),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Summary card
          GlassCard(
            accent: AppColors.accentBudget,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _SummaryStatRow(
                        label: 'Total budget',
                        value: '₹${totalBudget.toStringAsFixed(0)}',
                        valueColor: AppColors.accentBudget,
                      ),
                    ),
                    Expanded(
                      child: _SummaryStatRow(
                        label: 'Total spent',
                        value: '₹${totalSpent.toStringAsFixed(0)}',
                        valueColor: over ? AppColors.statusOverdue : AppColors.accentBudget,
                      ),
                    ),
                    Expanded(
                      child: _SummaryStatRow(
                        label: 'Over budget',
                        value: '$overBudget cat.',
                        valueColor: overBudget > 0
                            ? AppColors.statusOverdue
                            : AppColors.statusDone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalBudget > 0
                      ? (totalSpent / totalBudget).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppColors.accentBudget.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                      over ? AppColors.statusOverdue : AppColors.accentBudget),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBarChart(context, cats),
          const SizedBox(height: 24),
          Text('Categories', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ...cats.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetCategoryCard(category: c),
              )),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      BuildContext context, List<BudgetCategory> cats) {
    if (cats.isEmpty) return const SizedBox.shrink();

    final maxVal = cats
        .map((c) => [c.budgetAmount, c.spentAmount])
        .expand((e) => e)
        .reduce((a, b) => a > b ? a : b);

    return GlassCard(
      accent: AppColors.accentBudget,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget vs Spent', style: AppTextStyles.headlineSmall),
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
                          child: Text(label, style: AppTextStyles.bodySmall),
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
                        color: AppColors.accentBudget.withValues(alpha: 0.5),
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: cat.spentAmount,
                        color: cat.isOverBudget
                            ? AppColors.statusOverdue
                            : AppColors.accentBudget,
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
              _LegendItem(
                  color: AppColors.accentBudget.withValues(alpha: 0.5),
                  label: 'Budget'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.accentBudget, label: 'Spent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryStatRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.titleMedium.copyWith(color: valueColor)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class BudgetCategoryCard extends ConsumerWidget {
  final BudgetCategory category;
  const BudgetCategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    final pct = category.percentUsed;

    final Color statusColor = pct > 1.0
        ? AppColors.statusOverdue
        : pct > 0.9
            ? AppColors.statusPending
            : AppColors.statusDone;

    return GlassCard(
      accent: statusColor,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          GlassTile(
            dotColor: statusColor,
            title: category.category,
            subtitle:
                '₹${category.spentAmount.toStringAsFixed(0)} spent of ₹${category.budgetAmount.toStringAsFixed(0)}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip.custom(
                  label: '${(pct * 100).toInt()}%',
                  accent: statusColor,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSubtle, size: 18),
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
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            onTap: () =>
                _showAddEditModal(context, null, category, service: service),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(statusColor),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef? ref,
    BudgetCategory? cat, {dynamic service}) async {
  await showGlassSheet(
    context: context,
    title: cat == null ? 'Add Budget Category' : 'Edit Budget Category',
    content: _BudgetCategoryModal(category: cat, service: service),
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
  String _icon = 'category';

  @override
  void initState() {
    super.initState();
    _categoryCtrl = TextEditingController(text: widget.category?.category ?? '');
    _budgetCtrl = TextEditingController(
        text: widget.category?.budgetAmount.toStringAsFixed(0) ?? '');
    _icon = widget.category?.icon ?? 'category';
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(labelText: 'Category Name')),
        const SizedBox(height: 12),
        TextField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monthly Budget (₹)'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBudget,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_categoryCtrl.text.isEmpty) return;
              final now = DateTime.now();
              final newCat = BudgetCategory(
                id: widget.category?.id ?? '',
                category: _categoryCtrl.text.trim(),
                budgetAmount: double.tryParse(_budgetCtrl.text) ?? 0,
                spentAmount: 0,
                icon: _icon,
                color: '#7C4DFF',
                month: widget.category?.month ?? now.month,
                year: widget.category?.year ?? now.year,
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
    );
  }
}
