import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/food_entry.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';

class FoodTrackerScreen extends ConsumerWidget {
  const FoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(foodDateProvider);
    final entriesAsync = ref.watch(foodEntriesProvider(selectedDate));
    final goalAsync = ref.watch(calorieGoalProvider);
    final service = ref.watch(firebaseServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DateNav(date: selectedDate),
            Expanded(
              child: entriesAsync.when(
                data: (entries) => _FoodContent(
                  entries: entries,
                  goalAsync: goalAsync,
                  service: service,
                  date: selectedDate,
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: AppTextStyles.bodyMedium),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentFood,
        onPressed: () => _showAddFoodModal(context, selectedDate, service),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
    );
  }
}

// ─── Date Navigation ──────────────────────────────────────────────

class _DateNav extends ConsumerWidget {
  final DateTime date;
  const _DateNav({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text(
            'Food Tracker',
            style: AppTextStyles.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: context.appColors.textMuted),
            onPressed: () => ref.read(foodDateProvider.notifier).state =
                date.subtract(const Duration(days: 1)),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(foodDateProvider.notifier).state =
                    DateTime(picked.year, picked.month, picked.day);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentFood.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accentFood.withValues(alpha: 0.25)),
              ),
              child: Text(
                _dateLabel(date, now),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accentFood,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isToday
                  ? context.appColors.textSubtle
                  : context.appColors.textMuted,
            ),
            onPressed: isToday
                ? null
                : () => ref.read(foodDateProvider.notifier).state =
                    date.add(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d, DateTime now) {
    if (_isSameDay(d, now)) return 'Today';
    if (_isSameDay(d, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Main Content ─────────────────────────────────────────────────

class _FoodContent extends StatelessWidget {
  final List<FoodEntry> entries;
  final AsyncValue<int> goalAsync;
  final FirebaseService? service;
  final DateTime date;

  const _FoodContent({
    required this.entries,
    required this.goalAsync,
    required this.service,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final goal = goalAsync.when(
        data: (g) => g.toDouble(), loading: () => 2000.0, error: (_, __) => 2000.0);

    final totalCals = entries.fold(0.0, (s, e) => s + e.calories);
    final totalProtein = entries.fold(0.0, (s, e) => s + e.protein);
    final totalCarbs = entries.fold(0.0, (s, e) => s + e.carbs);
    final totalFat = entries.fold(0.0, (s, e) => s + e.fat);

    final remaining = (goal - totalCals).clamp(0.0, double.infinity);
    final subtitle = totalCals > 0
        ? '${totalCals.toInt()} kcal consumed · ${remaining.toInt()} remaining'
        : 'Goal: ${goal.toInt()} kcal';

    final byMeal = <MealType, List<FoodEntry>>{};
    for (final e in entries) {
      byMeal.putIfAbsent(e.mealType, () => []).add(e);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          AuroraHero(
            accent: AppColors.accentFood,
            eyebrow: 'WELLNESS · FOOD',
            title: 'Food Tracker',
            subtitle: subtitle,
          ),
          const SizedBox(height: 16),
          GlassCard(
            accent: AppColors.accentFood,
            padding: const EdgeInsets.all(20),
            child: _CalorieSummaryContent(
              consumed: totalCals,
              goal: goal,
              protein: totalProtein,
              carbs: totalCarbs,
              fat: totalFat,
              service: service,
            ),
          ),
          const SizedBox(height: 16),
          ...MealType.values.map(
            (mt) => _MealSection(
              mealType: mt,
              entries: byMeal[mt] ?? [],
              service: service,
              date: date,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calorie Summary Content ──────────────────────────────────────

class _CalorieSummaryContent extends StatelessWidget {
  final double consumed;
  final double goal;
  final double protein;
  final double carbs;
  final double fat;
  final FirebaseService? service;

  const _CalorieSummaryContent({
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final isOver = consumed > goal;
    final remaining = (goal - consumed).clamp(0.0, double.infinity);
    final ringColor = isOver ? AppColors.statusOverdue : AppColors.accentFood;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Calorie ring
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _CalorieRingPainter(
                      progress: progress,
                      ringColor: ringColor,
                      bgColor: context.appColors.glassBorder,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        consumed.toInt().toString(),
                        style: AppTextStyles.statDisplay.copyWith(
                          fontSize: 22,
                          color: isOver
                              ? AppColors.statusOverdue
                              : context.appColors.textPrimary,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statRow(
                    context,
                    'Goal',
                    '${goal.toInt()} kcal',
                    onTap: service == null
                        ? null
                        : () => _showGoalEditor(context, service!, goal.toInt()),
                  ),
                  const SizedBox(height: 10),
                  _statRow(
                    context,
                    isOver ? 'Over by' : 'Remaining',
                    '${isOver ? (consumed - goal).toInt() : remaining.toInt()} kcal',
                    valueColor: isOver
                        ? AppColors.statusOverdue
                        : AppColors.statusDone,
                  ),
                  const SizedBox(height: 10),
                  _statRow(
                    context,
                    'Consumed',
                    '${(progress * 100).toInt()}%',
                    valueColor: ringColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MacroBar(
            label: 'Protein',
            current: protein,
            target: 150,
            color: const Color(0xFFFF5722)),
        const SizedBox(height: 10),
        _MacroBar(
            label: 'Carbs',
            current: carbs,
            target: 250,
            color: const Color(0xFFFFC107)),
        const SizedBox(height: 10),
        _MacroBar(
            label: 'Fat',
            current: fat,
            target: 65,
            color: const Color(0xFF2196F3)),
      ],
    );
  }

  Widget _statRow(BuildContext context, String label, String value,
      {VoidCallback? onTap, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? context.appColors.textPrimary,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.edit_outlined,
                    size: 11, color: context.appColors.textSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showGoalEditor(BuildContext context, FirebaseService service, int current) {
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Daily Calorie Goal', style: AppTextStyles.headlineSmall),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: AppTextStyles.bodyMedium.copyWith(color: null),
          decoration: InputDecoration(
            labelText: 'Calories (kcal)',
            labelStyle: AppTextStyles.bodySmall,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTextStyles.bodyMedium)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentFood,
                foregroundColor: Colors.black),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                service.setCalorieGoal(val);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.appColors.glassBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            '${current.toInt()}g / ${target.toInt()}g',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── Meal Section ─────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final MealType mealType;
  final List<FoodEntry> entries;
  final FirebaseService? service;
  final DateTime date;

  const _MealSection({
    required this.mealType,
    required this.entries,
    required this.service,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final totalCals = entries.fold(0.0, (s, e) => s + e.calories);
    final color = _mealColor(mealType);

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        children: [
          InkWell(
            borderRadius: entries.isEmpty
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => _showAddFoodModal(context, date, service,
                defaultMeal: mealType),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_mealIcon(mealType), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mealType.label,
                    style: AppTextStyles.titleMedium,
                  ),
                  const Spacer(),
                  if (totalCals > 0)
                    Text(
                      '${totalCals.toInt()} kcal',
                      style: AppTextStyles.bodySmall,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 20,
                    color: AppColors.accentFood.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          if (entries.isNotEmpty) ...[
            Divider(height: 1, color: context.appColors.glassBorder),
            ...entries.asMap().entries.map((mapEntry) {
              final isLast = mapEntry.key == entries.length - 1;
              return _FoodTile(
                entry: mapEntry.value,
                service: service,
                isLast: isLast,
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Food Tile ────────────────────────────────────────────────────

class _FoodTile extends StatelessWidget {
  final FoodEntry entry;
  final FirebaseService? service;
  final bool isLast;

  const _FoodTile({
    required this.entry,
    required this.service,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = _mealColor(entry.mealType);

    final macroSubtitle = (entry.protein > 0 || entry.carbs > 0 || entry.fat > 0)
        ? 'P: ${entry.protein.toInt()}g  C: ${entry.carbs.toInt()}g  F: ${entry.fat.toInt()}g'
        : null;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.statusOverdue.withValues(alpha: 0.12),
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.statusOverdue),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text('Remove entry?', style: AppTextStyles.headlineSmall),
                content: Text('Remove "${entry.name}"?',
                    style: AppTextStyles.bodyMedium),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', style: AppTextStyles.bodyMedium)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Remove',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.statusOverdue)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => service?.deleteFoodEntry(entry.id),
      child: GlassTile(
        dotColor: AppColors.accentFood,
        title: entry.name,
        subtitle: macroSubtitle,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${entry.calories.toInt()} kcal',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add Food Modal ───────────────────────────────────────────────

void _showAddFoodModal(
  BuildContext context,
  DateTime date,
  FirebaseService? service, {
  MealType defaultMeal = MealType.breakfast,
}) {
  if (service == null) return;
  showGlassSheet(
    context: context,
    title: 'Add Food Entry',
    content: _AddFoodForm(
      date: date,
      service: service,
      defaultMeal: defaultMeal,
    ),
  );
}

class _AddFoodForm extends StatefulWidget {
  final DateTime date;
  final FirebaseService service;
  final MealType defaultMeal;

  const _AddFoodForm({
    required this.date,
    required this.service,
    required this.defaultMeal,
  });

  @override
  State<_AddFoodForm> createState() => _AddFoodFormState();
}

class _AddFoodFormState extends State<_AddFoodForm> {
  final _nameCtrl = TextEditingController();
  final _calsCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  late MealType _selectedMeal;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.defaultMeal;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calsCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meal type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MealType.values.map((mt) {
              final selected = _selectedMeal == mt;
              final color = _mealColor(mt);
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_mealIcon(mt),
                        size: 14,
                        color: selected
                            ? color
                            : context.appColors.textSubtle),
                    const SizedBox(width: 4),
                    Text(mt.label),
                  ],
                ),
                selected: selected,
                onSelected: (_) => setState(() => _selectedMeal = mt),
                selectedColor: color.withValues(alpha: 0.15),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: selected ? color : context.appColors.textMuted,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.bodyMedium.copyWith(color: null),
            decoration: InputDecoration(
              labelText: 'Food name *',
              labelStyle: AppTextStyles.bodySmall,
              prefixIcon: const Icon(Icons.restaurant_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calsCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyMedium.copyWith(color: null),
            decoration: InputDecoration(
              labelText: 'Calories (kcal) *',
              labelStyle: AppTextStyles.bodySmall,
              prefixIcon: const Icon(Icons.local_fire_department_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _macroField(
                      _proteinCtrl, 'Protein', const Color(0xFFFF5722))),
              const SizedBox(width: 8),
              Expanded(
                  child: _macroField(
                      _carbsCtrl, 'Carbs', const Color(0xFFFFC107))),
              const SizedBox(width: 8),
              Expanded(
                  child: _macroField(
                      _fatCtrl, 'Fat', const Color(0xFF2196F3))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Macros are optional',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentFood,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _submit,
            child: Text(
              'Add Food',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _macroField(
      TextEditingController ctrl, String label, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.bodySmall.copyWith(color: null),
      decoration: InputDecoration(
        labelText: '$label (g)',
        labelStyle: AppTextStyles.bodySmall.copyWith(
            color: color.withValues(alpha: 0.8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cals = double.tryParse(_calsCtrl.text.trim());
    if (name.isEmpty || cals == null || cals <= 0) return;

    final now = DateTime.now();
    final entryDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      now.hour,
      now.minute,
    );

    widget.service.addFoodEntry(FoodEntry(
      id: '',
      name: name,
      mealType: _selectedMeal,
      calories: cals,
      protein: double.tryParse(_proteinCtrl.text.trim()) ?? 0,
      carbs: double.tryParse(_carbsCtrl.text.trim()) ?? 0,
      fat: double.tryParse(_fatCtrl.text.trim()) ?? 0,
      date: entryDate,
    ));
    Navigator.pop(context);
  }
}

// ─── Calorie Ring Painter ─────────────────────────────────────────

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgColor;

  const _CalorieRingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

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
  bool shouldRepaint(_CalorieRingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}

// ─── Shared Helpers ───────────────────────────────────────────────

IconData _mealIcon(MealType mt) {
  switch (mt) {
    case MealType.breakfast:
      return Icons.free_breakfast_rounded;
    case MealType.lunch:
      return Icons.lunch_dining_rounded;
    case MealType.dinner:
      return Icons.dinner_dining_rounded;
    case MealType.snack:
      return Icons.cookie_rounded;
  }
}

Color _mealColor(MealType mt) {
  switch (mt) {
    case MealType.breakfast:
      return const Color(0xFFFF9800);
    case MealType.lunch:
      return const Color(0xFF4CAF50);
    case MealType.dinner:
      return const Color(0xFF2196F3);
    case MealType.snack:
      return const Color(0xFF9C27B0);
  }
}
