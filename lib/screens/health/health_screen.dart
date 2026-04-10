import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../models/health_habit.dart';
import '../../providers/providers.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(healthProvider);

    return Scaffold(
      body: habitsAsync.when(
        data: (habits) => _buildContent(context, ref, habits),
        loading: () => _loadingView(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context, ref, null, service: ref.read(firebaseServiceProvider)!),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<HealthHabit> habits) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Habits',
              style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 16),
          _buildProgressGrid(context, ref, habits),
          const SizedBox(height: 20),
          if (habits.isNotEmpty) _buildWeeklyChart(context, habits),
          const SizedBox(height: 20),
          Text('Habits Detail',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
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

  Widget _buildWeeklyChart(BuildContext context, List<HealthHabit> habits) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.accentTeal,
      Colors.orange,
      Colors.pink,
      Colors.blue,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Trends',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
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
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(days[i],
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: cs.onSurface.withOpacity(0.6)));
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  lineBarsData: habits.asMap().entries.map((e) {
                    final i = e.key;
                    final habit = e.value;
                    final color = colors[i % colors.length];
                    final normalizedData = habit.weeklyData
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                              entry.key.toDouble(),
                              habit.goal > 0
                                  ? (entry.value / habit.goal * 100)
                                      .clamp(0, 100)
                                  : 0,
                            ))
                        .toList();
                    return LineChartBarData(
                      spots: normalizedData,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, pct, bar, idx) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: color,
                          strokeWidth: 0,
                          strokeColor: Colors.transparent,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.08),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: habits.asMap().entries.map((e) {
                final color = colors[e.key % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(e.value.name,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: cs.onSurface.withOpacity(0.7))),
                  ],
                );
              }).toList(),
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
          4,
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
    final cs = Theme.of(context).colorScheme;
    final pct = habit.progressPercent;
    final color = pct >= 1.0
        ? Colors.green
        : pct >= 0.7
            ? AppTheme.accentTeal
            : AppTheme.primaryPurple;

    return Card(
      child: Padding(
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
                    backgroundColor: color.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconFromString(habit.icon), color: color, size: 18),
                        Text(
                          '${(val * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(habit.name,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: cs.onSurface),
                textAlign: TextAlign.center),
            Text(
              '${habit.todayValue.toStringAsFixed(0)}/${habit.goal.toStringAsFixed(0)} ${habit.unit}',
              style: GoogleFonts.inter(
                  fontSize: 10, color: cs.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                Text(
                  ' ${habit.streak}d',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
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
    final strokeWidth = 6.0;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    final cs = Theme.of(context).colorScheme;
    final pct = habit.progressPercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFromString(habit.icon),
                      color: AppTheme.primaryPurple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, color: cs.onSurface)),
                      Text(
                        '${habit.todayValue.toStringAsFixed(0)} / ${habit.goal.toStringAsFixed(0)} ${habit.unit}',
                        style: GoogleFonts.inter(
                            color: cs.onSurface.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    Text(
                      ' ${habit.streak} days',
                      style: GoogleFonts.inter(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: cs.onSurface.withOpacity(0.5), size: 18),
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showAddEditModal(context, null, habit, service: service);
                    } else if (v == 'delete') {
                      service.deleteHealthHabit(habit.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (ctx, val, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct >= 1.0
                        ? Colors.green
                        : pct >= 0.7
                            ? AppTheme.accentTeal
                            : AppTheme.primaryPurple,
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LogButton(
                  label: '+1',
                  onTap: () => service.logHabitValue(habit.id, 1),
                ),
                _LogButton(
                  label: '+5',
                  onTap: () => service.logHabitValue(habit.id, 5),
                ),
                _LogButton(
                  label: 'Reset',
                  onTap: () => service.resetHabitValue(habit.id),
                  isReset: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isReset;

  const _LogButton({
    required this.label,
    required this.onTap,
    this.isReset = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isReset
            ? Colors.red.withOpacity(0.15)
            : AppTheme.primaryPurple.withOpacity(0.15),
        foregroundColor: isReset ? Colors.red : AppTheme.primaryPurple,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Text(label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

Future<void> _showAddEditModal(BuildContext context, WidgetRef? ref,
    HealthHabit? habit, {dynamic service}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _HealthHabitModal(habit: habit, service: service),
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

  @override
  void initState() {
    super.initState();
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
    final cs = Theme.of(context).colorScheme;
    final icons = ['favorite', 'bedtime', 'fitness_center', 'water_drop', 'self_improvement'];
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
            widget.habit == null ? 'Add Health Habit' : 'Edit Health Habit',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Habit Name')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Daily Goal')),
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
          const SizedBox(height: 12),
          Text('Icon', style: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.7))),
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
                          ? AppTheme.primaryPurple.withOpacity(0.2)
                          : cs.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: AppTheme.primaryPurple)
                          : null,
                    ),
                    child: Icon(
                      _getIconData(ic),
                      color: selected ? AppTheme.primaryPurple : cs.onSurface.withOpacity(0.5),
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
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (_nameCtrl.text.isEmpty) return;
                final newHabit = HealthHabit(
                  id: widget.habit?.id ?? '',
                  name: _nameCtrl.text.trim(),
                  goal: double.tryParse(_goalCtrl.text) ?? 0,
                  unit: _unitCtrl.text.trim(),
                  todayValue: widget.habit?.todayValue ?? 0,
                  streak: widget.habit?.streak ?? 0,
                  weeklyData: widget.habit?.weeklyData ??
                      List.filled(7, 0.0),
                  icon: _icon,
                );
                if (widget.habit == null) {
                  await widget.service.addHealthHabit(newHabit);
                } else {
                  await widget.service.updateHealthHabit(newHabit);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(widget.habit == null ? 'Add Habit' : 'Update Habit'),
            ),
          ),
        ],
      ),
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
