import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/aurora_hero.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_tile.dart';
import '../../services/notification_service.dart'
    hide NotificationSettings;
import '../../services/notification_service.dart' show NotificationSettings;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _svc = NotificationService.instance;
  NotificationSettings? _settings;
  bool _permissionGranted = false;

  // Local mutable state mirrors
  late bool _taskEnabled;
  late TimeOfDay _taskTime;
  late bool _healthEnabled;
  late TimeOfDay _healthTime;
  late bool _breakfastEnabled;
  late TimeOfDay _breakfastTime;
  late bool _lunchEnabled;
  late TimeOfDay _lunchTime;
  late bool _dinnerEnabled;
  late TimeOfDay _dinnerTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _svc.loadSettings();
    final granted = await _svc.requestPermission();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _permissionGranted = granted;
      _taskEnabled = s.taskEnabled;
      _taskTime = s.taskTime;
      _healthEnabled = s.healthEnabled;
      _healthTime = s.healthTime;
      _breakfastEnabled = s.breakfastEnabled;
      _breakfastTime = s.breakfastTime;
      _lunchEnabled = s.lunchEnabled;
      _lunchTime = s.lunchTime;
      _dinnerEnabled = s.dinnerEnabled;
      _dinnerTime = s.dinnerTime;
    });
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
  }

  Future<void> _toggleTask(bool val) async {
    setState(() => _taskEnabled = val);
    if (val) {
      await _svc.scheduleDailyTask(_taskTime.hour, _taskTime.minute);
    } else {
      await _svc.cancelDailyTask();
    }
  }

  Future<void> _changeTaskTime() async {
    final t = await _pickTime(_taskTime);
    if (t == null) return;
    setState(() => _taskTime = t);
    if (_taskEnabled) {
      await _svc.scheduleDailyTask(t.hour, t.minute);
    }
  }

  Future<void> _toggleHealth(bool val) async {
    setState(() => _healthEnabled = val);
    if (val) {
      await _svc.scheduleHealth(_healthTime.hour, _healthTime.minute);
    } else {
      await _svc.cancelHealth();
    }
  }

  Future<void> _changeHealthTime() async {
    final t = await _pickTime(_healthTime);
    if (t == null) return;
    setState(() => _healthTime = t);
    if (_healthEnabled) {
      await _svc.scheduleHealth(t.hour, t.minute);
    }
  }

  Future<void> _toggleBreakfast(bool val) async {
    setState(() => _breakfastEnabled = val);
    if (val) {
      await _svc.scheduleBreakfast(
          _breakfastTime.hour, _breakfastTime.minute);
    } else {
      await _svc.cancelBreakfast();
    }
  }

  Future<void> _changeBreakfastTime() async {
    final t = await _pickTime(_breakfastTime);
    if (t == null) return;
    setState(() => _breakfastTime = t);
    if (_breakfastEnabled) {
      await _svc.scheduleBreakfast(t.hour, t.minute);
    }
  }

  Future<void> _toggleLunch(bool val) async {
    setState(() => _lunchEnabled = val);
    if (val) {
      await _svc.scheduleLunch(_lunchTime.hour, _lunchTime.minute);
    } else {
      await _svc.cancelLunch();
    }
  }

  Future<void> _changeLunchTime() async {
    final t = await _pickTime(_lunchTime);
    if (t == null) return;
    setState(() => _lunchTime = t);
    if (_lunchEnabled) {
      await _svc.scheduleLunch(t.hour, t.minute);
    }
  }

  Future<void> _toggleDinner(bool val) async {
    setState(() => _dinnerEnabled = val);
    if (val) {
      await _svc.scheduleDinner(_dinnerTime.hour, _dinnerTime.minute);
    } else {
      await _svc.cancelDinner();
    }
  }

  Future<void> _changeDinnerTime() async {
    final t = await _pickTime(_dinnerTime);
    if (t == null) return;
    setState(() => _dinnerTime = t);
    if (_dinnerEnabled) {
      await _svc.scheduleDinner(t.hour, t.minute);
    }
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
        children: [
          // ── Aurora Header ────────────────────────────────────
          AuroraHero(
            accent: AppColors.accentDashboard,
            eyebrow: 'SETTINGS',
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Permission banner ──────────────────────────
                if (!_permissionGranted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Notification permission not granted. Please enable it in app settings.',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Task Reminders ─────────────────────────────
                Text('Task Reminders',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      GlassTile(
                        dotColor: AppColors.accentDashboard,
                        title: 'Daily Cleaning Digest',
                        subtitle: 'Reminds you of overdue & due-today tasks',
                        trailing: Switch(
                          value: _taskEnabled,
                          onChanged: _toggleTask,
                          activeThumbColor: AppColors.accentDashboard,
                        ),
                      ),
                      if (_taskEnabled)
                        _TimeRow(
                          accent: AppColors.accentDashboard,
                          label: 'Daily at ${_fmtTime(_taskTime)}',
                          onTap: _changeTaskTime,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Health Reminders ───────────────────────────
                Text('Health Reminders',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      GlassTile(
                        dotColor: AppColors.accentDashboard,
                        title: 'Daily Habit Check-in',
                        subtitle:
                            'Evening prompt to complete your health habits',
                        trailing: Switch(
                          value: _healthEnabled,
                          onChanged: _toggleHealth,
                          activeThumbColor: AppColors.accentDashboard,
                        ),
                      ),
                      if (_healthEnabled)
                        _TimeRow(
                          accent: AppColors.accentDashboard,
                          label: 'Daily at ${_fmtTime(_healthTime)}',
                          onTap: _changeHealthTime,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Meal Reminders ─────────────────────────────
                Text('Meal Reminders',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      GlassTile(
                        dotColor: AppColors.accentDashboard,
                        title: 'Breakfast',
                        subtitle: 'Log breakfast & start your calorie count',
                        trailing: Switch(
                          value: _breakfastEnabled,
                          onChanged: _toggleBreakfast,
                          activeThumbColor: AppColors.accentDashboard,
                        ),
                      ),
                      if (_breakfastEnabled)
                        _TimeRow(
                          accent: AppColors.accentDashboard,
                          label: 'Daily at ${_fmtTime(_breakfastTime)}',
                          onTap: _changeBreakfastTime,
                        ),
                      GlassTile(
                        dotColor: AppColors.accentDashboard,
                        title: 'Lunch',
                        subtitle: 'Midday reminder to log your meal',
                        trailing: Switch(
                          value: _lunchEnabled,
                          onChanged: _toggleLunch,
                          activeThumbColor: AppColors.accentDashboard,
                        ),
                      ),
                      if (_lunchEnabled)
                        _TimeRow(
                          accent: AppColors.accentDashboard,
                          label: 'Daily at ${_fmtTime(_lunchTime)}',
                          onTap: _changeLunchTime,
                        ),
                      GlassTile(
                        dotColor: AppColors.accentDashboard,
                        title: 'Dinner',
                        subtitle: 'Evening meal logging reminder',
                        trailing: Switch(
                          value: _dinnerEnabled,
                          onChanged: _toggleDinner,
                          activeThumbColor: AppColors.accentDashboard,
                        ),
                      ),
                      if (_dinnerEnabled)
                        _TimeRow(
                          accent: AppColors.accentDashboard,
                          label: 'Daily at ${_fmtTime(_dinnerTime)}',
                          onTap: _changeDinnerTime,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Cancel all ─────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Cancel All Notifications',
                            style: AppTextStyles.headlineSmall),
                        content: Text(
                            'This will cancel all scheduled notifications.',
                            style: AppTextStyles.bodyMedium),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Confirm',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _svc.cancelAll();
                      await _load();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                              content:
                                  Text('All notifications cancelled.')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_off_rounded,
                      color: Colors.red),
                  label: Text('Cancel All Notifications',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Time row ─────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final Color accent;
  final String label;
  final VoidCallback onTap;

  const _TimeRow({
    required this.accent,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 15, color: accent.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_rounded,
                size: 14, color: accent.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
