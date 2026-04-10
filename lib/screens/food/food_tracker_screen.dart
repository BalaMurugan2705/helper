import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';

class FoodTrackerScreen extends ConsumerWidget {
  const FoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(foodDateProvider);
    final entriesAsync = ref.watch(foodEntriesProvider(selectedDate));
    final goalAsync = ref.watch(calorieGoalProvider);
    final service = ref.watch(firebaseServiceProvider);

    return Scaffold(
      backgroundColor: cs.surface,
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
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () => _showAddFoodModal(context, selectedDate, service),
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text(
            'Food Tracker',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
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
                color: AppTheme.primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _dateLabel(date, now),
                style: GoogleFonts.inter(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isToday ? cs.onSurface.withOpacity(0.2) : null,
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

    final byMeal = <MealType, List<FoodEntry>>{};
    for (final e in entries) {
      byMeal.putIfAbsent(e.mealType, () => []).add(e);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          _CalorieSummaryCard(
            consumed: totalCals,
            goal: goal,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            service: service,
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

// ─── Calorie Summary Card ─────────────────────────────────────────

class _CalorieSummaryCard extends StatelessWidget {
  final double consumed;
  final double goal;
  final double protein;
  final double carbs;
  final double fat;
  final FirebaseService? service;

  const _CalorieSummaryCard({
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final isOver = consumed > goal;
    final remaining = (goal - consumed).clamp(0.0, double.infinity);
    final ringColor = isOver ? Colors.red : AppTheme.primaryPurple;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
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
                        bgColor: cs.onSurface.withOpacity(0.08),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          consumed.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isOver ? Colors.red : cs.onSurface,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
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
                      cs,
                      'Goal',
                      '${goal.toInt()} kcal',
                      onTap: service == null
                          ? null
                          : () => _showGoalEditor(context, service!, goal.toInt()),
                    ),
                    const SizedBox(height: 10),
                    _statRow(
                      cs,
                      isOver ? 'Over by' : 'Remaining',
                      '${isOver ? (consumed - goal).toInt() : remaining.toInt()} kcal',
                      valueColor: isOver ? Colors.red : const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 10),
                    _statRow(
                      cs,
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
              cs: cs,
              label: 'Protein',
              current: protein,
              target: 150,
              color: const Color(0xFFFF5722)),
          const SizedBox(height: 10),
          _MacroBar(
              cs: cs,
              label: 'Carbs',
              current: carbs,
              target: 250,
              color: const Color(0xFFFFC107)),
          const SizedBox(height: 10),
          _MacroBar(
              cs: cs,
              label: 'Fat',
              current: fat,
              target: 65,
              color: const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _statRow(ColorScheme cs, String label, String value,
      {VoidCallback? onTap, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? cs.onSurface,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.edit_outlined,
                    size: 11, color: cs.onSurface.withOpacity(0.35)),
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
        title: Text('Daily Calorie Goal',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Calories (kcal)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                service.setCalorieGoal(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroBar({
    required this.cs,
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
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.onSurface.withOpacity(0.08),
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
            style: GoogleFonts.inter(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.5),
            ),
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
    final cs = Theme.of(context).colorScheme;
    final totalCals = entries.fold(0.0, (s, e) => s + e.calories);
    final color = _mealColor(mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: entries.isEmpty
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => _showAddFoodModal(context, date, service,
                defaultMeal: mealType),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_mealIcon(mealType), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mealType.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (totalCals > 0)
                    Text(
                      '${totalCals.toInt()} kcal',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 20,
                    color: AppTheme.primaryPurple.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          if (entries.isNotEmpty) ...[
            Divider(height: 1, color: cs.onSurface.withOpacity(0.08)),
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
    final cs = Theme.of(context).colorScheme;
    final color = _mealColor(entry.mealType);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Remove entry?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                content: Text('Remove "${entry.name}"?',
                    style: GoogleFonts.inter()),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => service?.deleteFoodEntry(entry.id),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          entry.name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        subtitle: (entry.protein > 0 || entry.carbs > 0 || entry.fat > 0)
            ? Text(
                'P: ${entry.protein.toInt()}g  C: ${entry.carbs.toInt()}g  F: ${entry.fat.toInt()}g',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${entry.calories.toInt()} kcal',
            style: GoogleFonts.inter(
              fontSize: 12,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddFoodModal(
      date: date,
      service: service,
      defaultMeal: defaultMeal,
    ),
  );
}

class _AddFoodModal extends StatefulWidget {
  final DateTime date;
  final FirebaseService service;
  final MealType defaultMeal;

  const _AddFoodModal({
    required this.date,
    required this.service,
    required this.defaultMeal,
  });

  @override
  State<_AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<_AddFoodModal> {
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Food',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
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
                          color: selected ? color : cs.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(mt.label),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMeal = mt),
                  selectedColor: color.withOpacity(0.15),
                  labelStyle: GoogleFonts.inter(
                    color: selected ? color : cs.onSurface.withOpacity(0.6),
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Food name *',
                prefixIcon: const Icon(Icons.restaurant_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calsCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Calories (kcal) *',
                prefixIcon: const Icon(Icons.local_fire_department_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.inter(),
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
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.4)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _submit,
              child: Text(
                'Add Food',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroField(
      TextEditingController ctrl, String label, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$label (g)',
        labelStyle: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 13),
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
