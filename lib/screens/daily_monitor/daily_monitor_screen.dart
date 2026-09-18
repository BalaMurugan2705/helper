import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/daily_log.dart';
import '../../models/food_entry.dart';
import '../../providers/providers.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firebase_service.dart';

// ─── Range filter provider ─────────────────────────────────────────

final _monitorRangeDaysProvider = StateProvider<int>((ref) => 7);

// ─── Screen ─────────────────────────────────────────────────────────

class DailyMonitorScreen extends ConsumerWidget {
  const DailyMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dailyLogsProvider);
    final rangeDays = ref.watch(_monitorRangeDaysProvider);
    final foodEntriesAsync = ref.watch(foodEntriesForMonitorProvider(rangeDays));
    final foodEntries = foodEntriesAsync.valueOrNull ?? [];

    final todayKey = DailyLog.keyFor(DateTime.now());
    final todayLog = logsAsync.when(
      data: (logs) => logs.where((l) => l.id == todayKey).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );
    final todayFoodEntries =
        foodEntries.where((e) => DailyLog.keyFor(e.date) == todayKey).toList();
    final todayCalories = todayFoodEntries.isEmpty
        ? null
        : todayFoodEntries.fold(0.0, (s, e) => s + e.calories);
    final todayProtein = todayFoodEntries.isEmpty
        ? null
        : todayFoodEntries.fold(0.0, (s, e) => s + e.protein);

    return Scaffold(
      body: Column(
        children: [
          AuroraHero(
            accent: AppColors.accentMonitor,
            eyebrow: 'HOME · DAILY MONITOR',
            title: 'Daily Monitor',
            subtitle: todayLog == null
                ? 'No entry logged today'
                : 'Today\'s entry saved',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [7, 30, 90]
                    .map((d) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _RangeChip(
                            label: '${d}d',
                            selected: rangeDays == d,
                            onTap: () => ref
                                .read(_monitorRangeDaysProvider.notifier)
                                .state = d,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                final sortedAsc = [...logs]
                  ..sort((a, b) => a.date.compareTo(b.date));
                final cutoff =
                    DateTime.now().subtract(Duration(days: rangeDays - 1));
                final inRange = sortedAsc
                    .where((l) => !l.date.isBefore(
                        DateTime(cutoff.year, cutoff.month, cutoff.day)))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    _TodayCard(
                      log: todayLog,
                      todayCalories: todayCalories,
                      todayProtein: todayProtein,
                    ),
                    const SizedBox(height: 16),
                    _ProgressPhotoStrip(
                      logs: inRange.where((l) => l.photoUrl != null).toList(),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Weight',
                      unit: 'kg',
                      color: AppColors.accentMonitor,
                      points: inRange
                          .where((l) => l.weightKg != null)
                          .map((l) => MapEntry(l.date, l.weightKg!))
                          .toList(),
                      secondaryLabel: '7-day avg',
                      secondaryColor: AppColors.accentAdvisor,
                      secondaryPoints: _rollingAverage(sortedAsc, 7),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      title: 'Waist',
                      unit: 'cm',
                      color: AppColors.accentPcos,
                      points: inRange
                          .where((l) => l.waistCm != null)
                          .map((l) => MapEntry(l.date, l.waistCm!))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      title: 'Steps',
                      unit: '',
                      color: AppColors.accentShopping,
                      points: inRange
                          .where((l) => l.steps != null)
                          .map((l) => MapEntry(l.date, l.steps!.toDouble()))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    if (foodEntriesAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          accent: AppColors.statusOverdue,
                          child: Text(
                            'Food Tracker sync error: ${foodEntriesAsync.error}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.statusOverdue),
                          ),
                        ),
                      ),
                    _ChartCard(
                      title: 'Calories',
                      unit: 'from Food Tracker',
                      color: AppColors.accentExpenses,
                      points: _dailyTotals(foodEntries, (e) => e.calories),
                      secondaryLabel: 'Protein (g)',
                      secondaryColor: AppColors.accentHealth,
                      secondaryPoints:
                          _dailyTotals(foodEntries, (e) => e.protein),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      title: 'Water',
                      unit: 'L',
                      color: AppColors.accentAdvisor,
                      points: inRange
                          .where((l) => l.waterL != null)
                          .map((l) => MapEntry(l.date, l.waterL!))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      title: 'Sleep',
                      unit: 'hrs',
                      color: AppColors.accentWishlist,
                      points: inRange
                          .where((l) => l.sleepHours != null)
                          .map((l) => MapEntry(l.date, l.sleepHours!))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _ChartCard(
                      title: 'Energy',
                      unit: '/5',
                      color: AppColors.accentFood,
                      points: inRange
                          .where((l) => l.energyLevel != null)
                          .map((l) =>
                              MapEntry(l.date, l.energyLevel!.toDouble()))
                          .toList(),
                      maxY: 5,
                    ),
                    const SizedBox(height: 20),
                    Text('Recent Entries', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 10),
                    if (logs.isEmpty)
                      _emptyState()
                    else
                      ...logs.take(14).map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LogRow(log: l),
                          )),
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final service = ref.read(firebaseServiceProvider);
          if (service != null) {
            _showLogForm(context, service, todayLog);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Today'),
        backgroundColor: AppColors.accentMonitor,
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('No entries yet — tap "Log Today" to start',
            style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Sums [selector] across all Food Tracker entries on the same day, one
/// point per day that has at least one entry.
List<MapEntry<DateTime, double>> _dailyTotals(
    List<FoodEntry> entries, double Function(FoodEntry) selector) {
  final totals = <String, double>{};
  final dateForKey = <String, DateTime>{};
  for (final e in entries) {
    final key = DailyLog.keyFor(e.date);
    totals[key] = (totals[key] ?? 0) + selector(e);
    dateForKey[key] = DateTime(e.date.year, e.date.month, e.date.day);
  }
  final result = totals.entries
      .map((kv) => MapEntry(dateForKey[kv.key]!, kv.value))
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return result;
}

/// For each log with a weight reading, averages all weight readings within
/// the trailing [windowDays] calendar days (inclusive).
List<MapEntry<DateTime, double>> _rollingAverage(
    List<DailyLog> ascLogs, int windowDays) {
  final withWeight =
      ascLogs.where((l) => l.weightKg != null).toList();
  final result = <MapEntry<DateTime, double>>[];
  for (final log in withWeight) {
    final windowStart = log.date.subtract(Duration(days: windowDays - 1));
    final windowValues = withWeight
        .where((l) => !l.date.isBefore(windowStart) && !l.date.isAfter(log.date))
        .map((l) => l.weightKg!)
        .toList();
    final avg = windowValues.reduce((a, b) => a + b) / windowValues.length;
    result.add(MapEntry(log.date, avg));
  }
  return result;
}

// ─── Range chip ─────────────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.accentMonitor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? color : color.withValues(alpha: 0.7),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Today card ─────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final DailyLog? log;
  final double? todayCalories;
  final double? todayProtein;
  const _TodayCard({required this.log, this.todayCalories, this.todayProtein});

  @override
  Widget build(BuildContext context) {
    final hasAnything = log != null || todayCalories != null;
    if (!hasAnything) {
      return GlassCard(
        accent: AppColors.accentMonitor,
        child: Row(
          children: [
            Icon(Icons.today_rounded, color: AppColors.accentMonitor),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No entry for today yet',
                  style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      );
    }
    return GlassCard(
      accent: AppColors.accentMonitor,
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          if (log?.weightKg != null) _stat('Weight', '${log!.weightKg} kg'),
          if (log?.steps != null) _stat('Steps', '${log!.steps}'),
          if (todayCalories != null)
            _stat('Calories', todayCalories!.toStringAsFixed(0)),
          if (todayProtein != null)
            _stat('Protein', '${todayProtein!.toStringAsFixed(0)}g'),
          if (log?.waterL != null) _stat('Water', '${log!.waterL}L'),
          if (log?.sleepHours != null) _stat('Sleep', '${log!.sleepHours}h'),
          if (log?.energyLevel != null) _stat('Energy', '${log!.energyLevel}/5'),
          if (log != null)
            StatusChip.custom(
              label: _workoutLabel(log!.workoutType),
              accent: AppColors.accentMonitor,
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        Text(value, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

String _workoutLabel(WorkoutType type) {
  switch (type) {
    case WorkoutType.rest:
      return 'Rest';
    case WorkoutType.strength:
      return 'Strength';
    case WorkoutType.cardio:
      return 'Cardio';
    case WorkoutType.both:
      return 'Strength + Cardio';
  }
}

IconData _workoutIcon(WorkoutType type) {
  switch (type) {
    case WorkoutType.rest:
      return Icons.bed_rounded;
    case WorkoutType.strength:
      return Icons.fitness_center_rounded;
    case WorkoutType.cardio:
      return Icons.directions_run_rounded;
    case WorkoutType.both:
      return Icons.sports_gymnastics_rounded;
  }
}

// ─── Progress photo strip ───────────────────────────────────────────

class _ProgressPhotoStrip extends StatelessWidget {
  final List<DailyLog> logs;
  const _ProgressPhotoStrip({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress Photos', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final log = sorted[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _PhotoViewerScreen(logs: sorted, initialIndex: i)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    log.photoUrl!,
                    width: 76,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, ___) {
                      debugPrint('Progress photo load failed for ${log.id}: $error');
                      return Container(
                        width: 76,
                        height: 96,
                        padding: const EdgeInsets.all(4),
                        color: AppColors.accentMonitor.withValues(alpha: 0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_rounded, size: 20),
                            const SizedBox(height: 2),
                            Text('$error',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelSmall.copyWith(fontSize: 7)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoViewerScreen extends StatefulWidget {
  final List<DailyLog> logs;
  final int initialIndex;
  const _PhotoViewerScreen({required this.logs, required this.initialIndex});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.logs[_index].id),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.logs.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => Center(
          child: InteractiveViewer(
            child: Image.network(widget.logs[i].photoUrl!),
          ),
        ),
      ),
    );
  }
}

// ─── Chart card ─────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final List<MapEntry<DateTime, double>> points;
  final String? secondaryLabel;
  final Color? secondaryColor;
  final List<MapEntry<DateTime, double>>? secondaryPoints;
  final double? maxY;

  const _ChartCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.points,
    this.secondaryLabel,
    this.secondaryColor,
    this.secondaryPoints,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return GlassCard(
        accent: color,
        child: Row(
          children: [
            Expanded(
              child: Text('$title — no data in this range',
                  style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      );
    }

    final allDates = [
      ...points.map((p) => p.key),
      ...?secondaryPoints?.map((p) => p.key),
    ]..sort();
    final start = allDates.first;
    double xFor(DateTime d) => d.difference(start).inDays.toDouble();

    final spots = points.map((p) => FlSpot(xFor(p.key), p.value)).toList();
    final secondarySpots =
        secondaryPoints?.map((p) => FlSpot(xFor(p.key), p.value)).toList();

    return GlassCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text('($unit)', style: AppTextStyles.labelSmall),
              ],
              const Spacer(),
              _Dot(color: color),
              const SizedBox(width: 4),
              Text(title, style: AppTextStyles.labelSmall),
              if (secondaryLabel != null) ...[
                const SizedBox(width: 10),
                _Dot(color: secondaryColor!),
                const SizedBox(width: 4),
                Text(secondaryLabel!, style: AppTextStyles.labelSmall),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(LineChartData(
              minY: maxY != null ? 0 : null,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: color.withValues(alpha: 0.08), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => touched
                      .map((s) => LineTooltipItem(
                            s.y.toStringAsFixed(1),
                            const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: color,
                  barWidth: 2.5,
                  dotData: FlDotData(show: spots.length <= 14),
                  belowBarData: BarAreaData(
                      show: true, color: color.withValues(alpha: 0.08)),
                ),
                if (secondarySpots != null)
                  LineChartBarData(
                    spots: secondarySpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: secondaryColor,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Recent entry row ───────────────────────────────────────────────

class _LogRow extends ConsumerWidget {
  final DailyLog log;
  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firebaseServiceProvider)!;
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.statusOverdue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.statusOverdue, size: 24),
      ),
      onDismissed: (_) => service.deleteDailyLog(log.id),
      child: GestureDetector(
        onTap: () => _showLogForm(context, service, log),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(_workoutIcon(log.workoutType),
                  size: 18, color: AppColors.accentMonitor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(log.id, style: AppTextStyles.bodyMedium),
              ),
              if (log.weightKg != null)
                Text('${log.weightKg} kg', style: AppTextStyles.bodySmall),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Log form ───────────────────────────────────────────────────────

void _showLogForm(
    BuildContext context, FirebaseService service, DailyLog? existing) {
  showGlassSheet(
    context: context,
    title: existing == null || existing.id == DailyLog.keyFor(DateTime.now())
        ? 'Log Today'
        : 'Edit Entry — ${existing.id}',
    content: _LogFormContent(service: service, existing: existing),
  );
}

class _LogFormContent extends StatefulWidget {
  final FirebaseService service;
  final DailyLog? existing;
  const _LogFormContent({required this.service, this.existing});

  @override
  State<_LogFormContent> createState() => _LogFormContentState();
}

class _LogFormContentState extends State<_LogFormContent> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _waistCtrl;
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _waterCtrl;
  late final TextEditingController _sleepCtrl;
  late WorkoutType _workoutType;
  late int? _energyLevel;
  bool _saving = false;

  Uint8List? _pickedPhotoBytes;
  bool _removeExistingPhoto = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _weightCtrl = TextEditingController(text: e?.weightKg?.toString() ?? '');
    _waistCtrl = TextEditingController(text: e?.waistCm?.toString() ?? '');
    _stepsCtrl = TextEditingController(text: e?.steps?.toString() ?? '');
    _waterCtrl = TextEditingController(text: e?.waterL?.toString() ?? '');
    _sleepCtrl = TextEditingController(text: e?.sleepHours?.toString() ?? '');
    _workoutType = e?.workoutType ?? WorkoutType.rest;
    _energyLevel = e?.energyLevel;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedPhotoBytes = bytes;
      _removeExistingPhoto = false;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _stepsCtrl.dispose();
    _waterCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final date = widget.existing?.date ?? DateTime.now();
    final id = widget.existing?.id ?? DailyLog.keyFor(date);

    String? photoUrl = widget.existing?.photoUrl;
    if (_pickedPhotoBytes != null) {
      try {
        photoUrl =
            await CloudinaryService().uploadImage(_pickedPhotoBytes!, '$id.jpg');
      } catch (e) {
        setState(() => _saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
        }
        return;
      }
    } else if (_removeExistingPhoto) {
      photoUrl = null;
    }

    final log = DailyLog(
      id: id,
      date: date,
      weightKg: double.tryParse(_weightCtrl.text),
      waistCm: double.tryParse(_waistCtrl.text),
      steps: int.tryParse(_stepsCtrl.text),
      waterL: double.tryParse(_waterCtrl.text),
      sleepHours: double.tryParse(_sleepCtrl.text),
      workoutType: _workoutType,
      energyLevel: _energyLevel,
      photoUrl: photoUrl,
    );
    await widget.service.saveDailyLog(log);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _waistCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Waist (cm)',
                    prefixIcon: Icon(Icons.straighten_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stepsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Steps',
                    prefixIcon: Icon(Icons.directions_walk_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sleepCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Sleep (hrs)',
                    prefixIcon: Icon(Icons.bedtime_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Calories & protein are pulled from Food Tracker automatically.',
              style: AppTextStyles.labelSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _waterCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Water (L)',
              prefixIcon: Icon(Icons.water_drop_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          Text('Progress Photo', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _pickedPhotoBytes != null
                    ? Image.memory(_pickedPhotoBytes!,
                        width: 64, height: 64, fit: BoxFit.cover)
                    : (widget.existing?.photoUrl != null && !_removeExistingPhoto)
                        ? Image.network(widget.existing!.photoUrl!,
                            width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, error, ___) {
                              debugPrint('Progress photo load failed: $error');
                              return Container(
                                width: 64,
                                height: 64,
                                color: AppColors.statusOverdue.withValues(alpha: 0.1),
                                child: const Icon(Icons.broken_image_rounded,
                                    color: AppColors.statusOverdue),
                              );
                            })
                        : Container(
                            width: 64,
                            height: 64,
                            color: AppColors.accentMonitor.withValues(alpha: 0.1),
                            child: Icon(Icons.photo_camera_rounded,
                                color: AppColors.accentMonitor),
                          ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                color: AppColors.accentMonitor,
                tooltip: 'Camera',
              ),
              IconButton(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                color: AppColors.accentMonitor,
                tooltip: 'Gallery',
              ),
              if (_pickedPhotoBytes != null ||
                  (widget.existing?.photoUrl != null && !_removeExistingPhoto))
                IconButton(
                  onPressed: () => setState(() {
                    _pickedPhotoBytes = null;
                    _removeExistingPhoto = true;
                  }),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.statusOverdue,
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Workout', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkoutType.values.map((t) {
              final selected = _workoutType == t;
              return GestureDetector(
                onTap: () => setState(() => _workoutType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentMonitor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentMonitor
                          : AppColors.accentMonitor.withValues(alpha: 0.3),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_workoutIcon(t),
                          size: 13,
                          color: selected
                              ? AppColors.accentMonitor
                              : AppColors.accentMonitor.withValues(alpha: 0.6)),
                      const SizedBox(width: 5),
                      Text(
                        _workoutLabel(t),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected
                              ? AppColors.accentMonitor
                              : AppColors.accentMonitor.withValues(alpha: 0.7),
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Energy Level', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(5, (i) {
              final level = i + 1;
              final selected = _energyLevel == level;
              return GestureDetector(
                onTap: () => setState(
                    () => _energyLevel = selected ? null : level),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentMonitor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentMonitor
                          : AppColors.accentMonitor.withValues(alpha: 0.3),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '$level',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: selected
                          ? AppColors.accentMonitor
                          : AppColors.accentMonitor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentMonitor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Save Entry',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
