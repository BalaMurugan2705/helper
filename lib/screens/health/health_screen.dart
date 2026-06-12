import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../models/health_habit.dart';
import '../../providers/providers.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(healthProvider);

    final habitCount = habitsAsync.when(
        data: (h) => h.length, loading: () => 0, error: (_, __) => 0);

    return Scaffold(
      body: Column(
        children: [
          AuroraHero(
            accent: AppColors.accentHealth,
            eyebrow: 'WELLNESS · HEALTH',
            title: 'Health',
            subtitle: habitCount > 0
                ? '$habitCount habits tracked'
                : 'Start tracking your habits',
          ),
          Expanded(
            child: habitsAsync.when(
              data: (habits) => _buildContent(context, ref, habits),
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null,
            service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: Text('Add Habit', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.accentHealth,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<HealthHabit> habits) {
    if (habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_outline_rounded,
                  size: 48, color: AppColors.textSubtle),
              const SizedBox(height: 12),
              Text('No habits yet', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text('Track daily habits like water intake, sleep, exercise',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressGrid(context, ref, habits),
          const SizedBox(height: 24),
          if (habits.isNotEmpty) _MonthlyCalendar(habits: habits),
          const SizedBox(height: 24),
          Text('Habits Detail', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ...habits.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HealthHabitCard(habit: h),
              )),
        ],
      ),
    );
  }

  Widget _buildProgressGrid(
      BuildContext context, WidgetRef ref, List<HealthHabit> habits) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 600 ? 4 : 2;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: habits.map((h) => _CircularProgressCard(habit: h)).toList(),
    );
  }

}

// ─── Monthly Calendar Analytics ───────────────────────────────────────────────

class _MonthlyCalendar extends StatelessWidget {
  final List<HealthHabit> habits;

  const _MonthlyCalendar({required this.habits});

  static const _dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _allDoneOnDate(List<HealthHabit> habits, String key) =>
      habits.isNotEmpty &&
      habits.every((h) {
        final val = h.dailyLog[key] ?? 0.0;
        return val >= (h.habitType == HabitType.binary ? 1.0 : h.goal);
      });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;
    final weeks = ((startOffset + daysInMonth) / 7).ceil();

    // Count days (up to and including today) where every habit was done
    int doneCount = 0;
    for (int d = 1; d <= now.day; d++) {
      final date = DateTime(now.year, now.month, d);
      final key = _dateKey(date);
      if (d == now.day) {
        if (habits.isNotEmpty && habits.every((h) => h.isCompleted)) doneCount++;
      } else {
        if (_allDoneOnDate(habits, key)) doneCount++;
      }
    }

    return GlassCard(
      accent: AppColors.accentHealth,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_monthNames[now.month - 1]} ${now.year}',
                  style: AppTextStyles.headlineSmall,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusDone.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$doneCount/${now.day} days',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.statusDone,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Day-of-week header
            Row(
              children: _dayLabels
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSubtle)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Calendar grid
            ...List.generate(weeks, (week) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (wd) {
                  final dayNum = week * 7 + wd - startOffset + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }
                  final date = DateTime(now.year, now.month, dayNum);
                  final isToday = dayNum == now.day;
                  final isFuture = date.isAfter(
                      DateTime(now.year, now.month, now.day));
                  final key = _dateKey(date);

                  Color? bg;
                  if (!isFuture) {
                    int completed;
                    int tracked;
                    if (isToday) {
                      completed = habits.where((h) => h.isCompleted).length;
                      tracked = habits.length;
                    } else {
                      final entries = habits
                          .where((h) => h.dailyLog.containsKey(key))
                          .toList();
                      tracked = entries.length;
                      completed = entries
                          .where((h) {
                            final val = h.dailyLog[key]!;
                            return val >=
                                (h.habitType == HabitType.binary
                                    ? 1.0
                                    : h.goal);
                          })
                          .length;
                    }
                    if (tracked == 0) {
                      bg = null;
                    } else if (completed == tracked) {
                      bg = AppColors.statusDone;
                    } else if (completed > 0) {
                      bg = AppColors.accentHealth.withValues(alpha: 0.55);
                    } else {
                      bg = AppColors.statusOverdue.withValues(alpha: 0.35);
                    }
                  }

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: AppColors.accentHealth, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        '$dayNum',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isFuture || bg == null
                              ? AppColors.textSubtle
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                    color: AppColors.statusDone, label: 'All done'),
                const SizedBox(width: 14),
                _LegendItem(
                    color: AppColors.accentHealth.withValues(alpha: 0.55),
                    label: 'Partial'),
                const SizedBox(width: 14),
                _LegendItem(
                    color: AppColors.statusOverdue.withValues(alpha: 0.35),
                    label: 'Missed'),
              ],
            ),
          ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _CircularProgressCard extends StatelessWidget {
  final HealthHabit habit;
  const _CircularProgressCard({required this.habit});

  IconData _iconFromString(String icon) {
    switch (icon) {
      case 'bedtime':
        return Icons.bedtime_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = habit.progressPercent;
    final color = pct >= 1.0
        ? AppColors.statusDone
        : pct >= 0.7
            ? AppColors.accentHealth
            : AppColors.accentHealth.withValues(alpha: 0.6);

    return GlassCard(
      accent: AppColors.accentHealth,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (ctx, val, _) => CustomPaint(
                painter: _CircularProgressPainter(
                  progress: val,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        habit.habitType == HabitType.binary && habit.isCompleted
                            ? Icons.check_circle_rounded
                            : _iconFromString(habit.icon),
                        color: color,
                        size: habit.habitType == HabitType.binary ? 20 : 18,
                      ),
                      if (habit.habitType == HabitType.measurement)
                        Text(
                          '${(val * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(habit.name,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center),
          Text(
            habit.habitType == HabitType.binary
                ? (habit.isCompleted ? 'Done ✓' : 'Not done')
                : '${habit.todayValue.toStringAsFixed(0)}/${habit.goal.toStringAsFixed(0)} ${habit.unit}',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              Text(
                ' ${habit.streak}d',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusPending,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 6.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress || old.color != color;
}

class HealthHabitCard extends ConsumerWidget {
  final HealthHabit habit;
  const HealthHabitCard({super.key, required this.habit});

  Color _habitStatusColor(HealthHabit h) {
    final pct = h.progressPercent;
    if (pct >= 1.0) return AppColors.statusDone;
    if (pct >= 0.5) return AppColors.accentHealth;
    return AppColors.statusOverdue;
  }

  Widget _habitStatusChip(HealthHabit h) {
    final pct = h.progressPercent;
    if (pct >= 1.0) return const StatusChip.done();
    if (pct >= 0.5) {
      return StatusChip.custom(
          label: '${(pct * 100).toInt()}%', accent: AppColors.accentHealth);
    }
    return const StatusChip.overdue();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;

    return GlassCard(
      accent: _habitStatusColor(habit),
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          GlassTile(
            dotColor: _habitStatusColor(habit),
            title: habit.name,
            subtitle: habit.habitType == HabitType.binary
                ? (habit.isCompleted ? 'Completed today' : 'Not done today')
                : '${habit.todayValue.toStringAsFixed(0)} / ${habit.goal.toStringAsFixed(0)} ${habit.unit}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _habitStatusChip(habit),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: AppColors.textSubtle),
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showAddEditModal(context, null, habit, service: service);
                    }
                    if (v == 'delete') service.deleteHealthHabit(habit.id);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: TweenAnimationBuilder<double>(
              tween:
                  Tween(begin: 0, end: habit.progressPercent.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (ctx, val, _) => LinearProgressIndicator(
                value: val,
                backgroundColor:
                    _habitStatusColor(habit).withValues(alpha: 0.1),
                valueColor:
                    AlwaysStoppedAnimation(_habitStatusColor(habit)),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: habit.habitType == HabitType.binary
                ? _BinaryActionRow(habit: habit, service: service)
                : _MeasurementActionRow(
                    habit: habit, service: service, context: context),
          ),
        ],
      ),
    );
  }
}

class _BinaryActionRow extends StatelessWidget {
  final HealthHabit habit;
  final dynamic service;
  const _BinaryActionRow({required this.habit, required this.service});

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompleted;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(done
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded),
        label: Text(done ? 'Completed Today' : 'Mark as Done'),
        style: ElevatedButton.styleFrom(
          backgroundColor: done
              ? AppColors.statusDone
              : AppColors.statusDone.withValues(alpha: 0.15),
          foregroundColor: done ? Colors.white : AppColors.statusDone,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => service.markHabitDone(habit.id, !done),
      ),
    );
  }
}

class _MeasurementActionRow extends StatelessWidget {
  final HealthHabit habit;
  final dynamic service;
  final BuildContext context;
  const _MeasurementActionRow(
      {required this.habit, required this.service, required this.context});

  void _openValueDialog() {
    final ctrl =
        TextEditingController(text: habit.todayValue.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Enter ${habit.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: habit.unit.isNotEmpty ? 'Value (${habit.unit})' : 'Value',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentHealth,
                foregroundColor: Colors.white),
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) service.setHabitValue(habit.id, v);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogButton(
            label: '-1',
            onTap: () => service.logHabitValue(habit.id, -1.0),
            isDecrease: true),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _openValueDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentHealth.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.accentHealth.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    habit.todayValue.truncateToDouble() == habit.todayValue
                        ? habit.todayValue.toStringAsFixed(0)
                        : habit.todayValue.toStringAsFixed(1),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentHealth),
                  ),
                  if (habit.unit.isNotEmpty)
                    Text(habit.unit, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _LogButton(
            label: '+1',
            onTap: () => service.logHabitValue(habit.id, 1.0)),
        const SizedBox(width: 8),
        _LogButton(
            label: 'Reset',
            onTap: () => service.resetHabitValue(habit.id),
            isReset: true),
      ],
    );
  }
}

class _LogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isReset;
  final bool isDecrease;

  const _LogButton({
    required this.label,
    required this.onTap,
    this.isReset = false,
    this.isDecrease = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isReset) {
      bg = AppColors.statusOverdue.withValues(alpha: 0.15);
      fg = AppColors.statusOverdue;
    } else if (isDecrease) {
      bg = AppColors.textSubtle.withValues(alpha: 0.1);
      fg = AppColors.textSubtle;
    } else {
      bg = AppColors.accentHealth.withValues(alpha: 0.15);
      fg = AppColors.accentHealth;
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef? ref,
    HealthHabit? habit, {dynamic service}) async {
  await showGlassSheet(
    context: context,
    title: habit == null ? 'Add Health Habit' : 'Edit Health Habit',
    content: _HealthHabitModal(habit: habit, service: service),
  );
}

class _HealthHabitModal extends StatefulWidget {
  final HealthHabit? habit;
  final dynamic service;
  const _HealthHabitModal({this.habit, required this.service});

  @override
  State<_HealthHabitModal> createState() => _HealthHabitModalState();
}

class _HealthHabitModalState extends State<_HealthHabitModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _goalCtrl;
  late TextEditingController _unitCtrl;
  String _icon = 'favorite';
  late HabitType _habitType;

  @override
  void initState() {
    super.initState();
    _habitType = widget.habit?.habitType ?? HabitType.measurement;
    _nameCtrl = TextEditingController(text: widget.habit?.name ?? '');
    _goalCtrl = TextEditingController(
        text: widget.habit?.goal.toStringAsFixed(0) ?? '');
    _unitCtrl = TextEditingController(text: widget.habit?.unit ?? '');
    _icon = widget.habit?.icon ?? 'favorite';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      'favorite',
      'bedtime',
      'fitness_center',
      'water_drop',
      'self_improvement'
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit Type', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                label: 'Binary',
                icon: Icons.check_circle_outline,
                description: 'Done / Not done',
                selected: _habitType == HabitType.binary,
                onTap: () => setState(() => _habitType = HabitType.binary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeButton(
                label: 'Measurement',
                icon: Icons.show_chart,
                description: 'Track a value',
                selected: _habitType == HabitType.measurement,
                onTap: () =>
                    setState(() => _habitType = HabitType.measurement),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Habit Name')),
        if (_habitType == HabitType.measurement) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Daily Goal')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Unit (hrs/min/glasses)')),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text('Icon', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: icons.map((ic) {
            final selected = _icon == ic;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _icon = ic),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentHealth.withValues(alpha: 0.2)
                        : AppColors.glassCard,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(color: AppColors.accentHealth)
                        : null,
                  ),
                  child: Icon(
                    _getIconData(ic),
                    color: selected
                        ? AppColors.accentHealth
                        : AppColors.textSubtle,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentHealth,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_nameCtrl.text.isEmpty) return;
              final isBinary = _habitType == HabitType.binary;
              final newHabit = HealthHabit(
                id: widget.habit?.id ?? '',
                name: _nameCtrl.text.trim(),
                goal: isBinary ? 1.0 : (double.tryParse(_goalCtrl.text) ?? 1),
                unit: isBinary ? '' : _unitCtrl.text.trim(),
                todayValue: widget.habit?.todayValue ?? 0,
                streak: widget.habit?.streak ?? 0,
                dailyLog: widget.habit?.dailyLog ?? {},
                icon: _icon,
                habitType: _habitType,
                lastResetDate: widget.habit?.lastResetDate ?? '',
              );
              if (widget.habit == null) {
                await widget.service.addHealthHabit(newHabit);
              } else {
                await widget.service.updateHealthHabit(newHabit);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child:
                Text(widget.habit == null ? 'Add Habit' : 'Update Habit'),
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'bedtime':
        return Icons.bedtime_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentHealth.withValues(alpha: 0.15)
              : AppColors.glassCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accentHealth : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? AppColors.accentHealth
                    : AppColors.textSubtle,
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.accentHealth
                      : AppColors.textPrimary,
                )),
            Text(description,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
