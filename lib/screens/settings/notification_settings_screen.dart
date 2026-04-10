import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
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
    final cs = Theme.of(context).colorScheme;

    if (_settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // ── Permission banner ────────────────────────────────
          if (!_permissionGranted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.orange.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notification permission not granted. Please enable it in app settings.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // ── Task Reminders ───────────────────────────────────
          _SectionHeader(
            icon: Icons.cleaning_services_rounded,
            label: 'Task Reminders',
            color: AppTheme.primaryPurple,
          ),
          _NotifTile(
            icon: Icons.today_rounded,
            title: 'Daily Cleaning Digest',
            subtitle: 'Reminds you of overdue & due-today tasks',
            enabled: _taskEnabled,
            time: _taskTime,
            onToggle: _toggleTask,
            onTimeTap: _changeTaskTime,
            fmtTime: _fmtTime,
          ),
          const SizedBox(height: 20),

          // ── Health Reminders ─────────────────────────────────
          _SectionHeader(
            icon: Icons.favorite_rounded,
            label: 'Health Reminders',
            color: Colors.pink,
          ),
          _NotifTile(
            icon: Icons.self_improvement_rounded,
            title: 'Daily Habit Check-in',
            subtitle: 'Evening prompt to complete your health habits',
            enabled: _healthEnabled,
            time: _healthTime,
            onToggle: _toggleHealth,
            onTimeTap: _changeHealthTime,
            fmtTime: _fmtTime,
          ),
          const SizedBox(height: 20),

          // ── Meal Reminders ───────────────────────────────────
          _SectionHeader(
            icon: Icons.restaurant_menu_rounded,
            label: 'Meal Reminders',
            color: const Color(0xFFFF9800),
          ),
          _NotifTile(
            icon: Icons.free_breakfast_rounded,
            title: 'Breakfast',
            subtitle: 'Log breakfast & start your calorie count',
            enabled: _breakfastEnabled,
            time: _breakfastTime,
            onToggle: _toggleBreakfast,
            onTimeTap: _changeBreakfastTime,
            fmtTime: _fmtTime,
            accentColor: const Color(0xFFFF9800),
          ),
          const SizedBox(height: 8),
          _NotifTile(
            icon: Icons.lunch_dining_rounded,
            title: 'Lunch',
            subtitle: 'Midday reminder to log your meal',
            enabled: _lunchEnabled,
            time: _lunchTime,
            onToggle: _toggleLunch,
            onTimeTap: _changeLunchTime,
            fmtTime: _fmtTime,
            accentColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 8),
          _NotifTile(
            icon: Icons.dinner_dining_rounded,
            title: 'Dinner',
            subtitle: 'Evening meal logging reminder',
            enabled: _dinnerEnabled,
            time: _dinnerTime,
            onToggle: _toggleDinner,
            onTimeTap: _changeDinnerTime,
            fmtTime: _fmtTime,
            accentColor: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 24),

          // ── Cancel all ───────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Cancel All Notifications',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700)),
                  content: Text(
                      'This will cancel all scheduled notifications.',
                      style: GoogleFonts.inter()),
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
                style: GoogleFonts.inter(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;
  final String Function(TimeOfDay) fmtTime;
  final Color accentColor;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTimeTap,
    required this.fmtTime,
    this.accentColor = AppTheme.primaryPurple,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: enabled
            ? accentColor.withOpacity(0.06)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? accentColor.withOpacity(0.3)
              : cs.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.fromLTRB(14, 4, 8, 4),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(enabled ? 0.15 : 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color:
                      accentColor.withOpacity(enabled ? 1.0 : 0.4),
                  size: 20),
            ),
            title: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface
                    .withOpacity(enabled ? 1.0 : 0.5),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.45),
              ),
            ),
            trailing: Switch(
              value: enabled,
              onChanged: onToggle,
              activeColor: accentColor,
            ),
          ),
          if (enabled) ...[
            Divider(
                height: 1,
                color: accentColor.withOpacity(0.15)),
            InkWell(
              onTap: onTimeTap,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 15,
                        color: accentColor.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Text(
                      'Daily at ${fmtTime(time)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_rounded,
                        size: 14,
                        color: accentColor.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
