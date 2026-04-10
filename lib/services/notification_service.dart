import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // ─── Notification IDs ─────────────────────────────────────────
  static const int _dailyTaskId = 0;
  static const int _healthId = 1;
  static const int _breakfastId = 2;
  static const int _lunchId = 3;
  static const int _dinnerId = 4;

  static int taskNotifId(String taskId) =>
      taskId.hashCode.abs() % 900000 + 10000;

  // ─── SharedPrefs keys ─────────────────────────────────────────
  static const _kTaskEnabled = 'notif_task_enabled';
  static const _kTaskHour = 'notif_task_hour';
  static const _kTaskMin = 'notif_task_min';
  static const _kHealthEnabled = 'notif_health_enabled';
  static const _kHealthHour = 'notif_health_hour';
  static const _kHealthMin = 'notif_health_min';
  static const _kBreakfastEnabled = 'notif_breakfast_enabled';
  static const _kBreakfastHour = 'notif_breakfast_hour';
  static const _kBreakfastMin = 'notif_breakfast_min';
  static const _kLunchEnabled = 'notif_lunch_enabled';
  static const _kLunchHour = 'notif_lunch_hour';
  static const _kLunchMin = 'notif_lunch_min';
  static const _kDinnerEnabled = 'notif_dinner_enabled';
  static const _kDinnerHour = 'notif_dinner_hour';
  static const _kDinnerMin = 'notif_dinner_min';

  // ─── Init ──────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ─── Notification details ──────────────────────────────────────

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── Next scheduled TZDateTime ─────────────────────────────────

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ─── Daily Task Digest ─────────────────────────────────────────

  Future<void> scheduleDailyTask(int hour, int minute) async {
    await _plugin.zonedSchedule(
      _dailyTaskId,
      '🏠 Task Reminder',
      'Check your cleaning tasks for today — stay on schedule!',
      _nextInstanceOf(hour, minute),
      _details(
        channelId: 'tasks',
        channelName: 'Task Reminders',
        channelDesc: 'Daily cleaning task digest',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTaskEnabled, true);
    await prefs.setInt(_kTaskHour, hour);
    await prefs.setInt(_kTaskMin, minute);
  }

  Future<void> cancelDailyTask() async {
    await _plugin.cancel(_dailyTaskId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTaskEnabled, false);
  }

  // ─── Health Habit Reminder ─────────────────────────────────────

  Future<void> scheduleHealth(int hour, int minute) async {
    await _plugin.zonedSchedule(
      _healthId,
      '💪 Health Check-in',
      "Time to log your daily habits! Don't break your streak.",
      _nextInstanceOf(hour, minute),
      _details(
        channelId: 'health',
        channelName: 'Health Reminders',
        channelDesc: 'Daily health habit reminder',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHealthEnabled, true);
    await prefs.setInt(_kHealthHour, hour);
    await prefs.setInt(_kHealthMin, minute);
  }

  Future<void> cancelHealth() async {
    await _plugin.cancel(_healthId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHealthEnabled, false);
  }

  // ─── Meal Reminders ───────────────────────────────────────────

  Future<void> scheduleMeal({
    required int id,
    required String meal,
    required String emoji,
    required int hour,
    required int minute,
    required String enabledKey,
    required String hourKey,
    required String minKey,
  }) async {
    await _plugin.zonedSchedule(
      id,
      '$emoji $meal Reminder',
      'Time for $meal! Log what you eat to track your calories.',
      _nextInstanceOf(hour, minute),
      _details(
        channelId: 'meals',
        channelName: 'Meal Reminders',
        channelDesc: 'Meal time reminders for calorie tracking',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, true);
    await prefs.setInt(hourKey, hour);
    await prefs.setInt(minKey, minute);
  }

  Future<void> scheduleBreakfast(int hour, int minute) => scheduleMeal(
        id: _breakfastId,
        meal: 'Breakfast',
        emoji: '🌅',
        hour: hour,
        minute: minute,
        enabledKey: _kBreakfastEnabled,
        hourKey: _kBreakfastHour,
        minKey: _kBreakfastMin,
      );

  Future<void> scheduleLunch(int hour, int minute) => scheduleMeal(
        id: _lunchId,
        meal: 'Lunch',
        emoji: '☀️',
        hour: hour,
        minute: minute,
        enabledKey: _kLunchEnabled,
        hourKey: _kLunchHour,
        minKey: _kLunchMin,
      );

  Future<void> scheduleDinner(int hour, int minute) => scheduleMeal(
        id: _dinnerId,
        meal: 'Dinner',
        emoji: '🌙',
        hour: hour,
        minute: minute,
        enabledKey: _kDinnerEnabled,
        hourKey: _kDinnerHour,
        minKey: _kDinnerMin,
      );

  Future<void> cancelMeal(int id, String enabledKey) async {
    await _plugin.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, false);
  }

  Future<void> cancelBreakfast() =>
      cancelMeal(_breakfastId, _kBreakfastEnabled);
  Future<void> cancelLunch() => cancelMeal(_lunchId, _kLunchEnabled);
  Future<void> cancelDinner() => cancelMeal(_dinnerId, _kDinnerEnabled);

  // ─── Per-Task Reminder ─────────────────────────────────────────

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskName,
    required String room,
    required DateTime when,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      taskNotifId(taskId),
      '🧹 Task Due: $taskName',
      '$room — your scheduled reminder is here!',
      scheduled,
      _details(
        channelId: 'task_alerts',
        channelName: 'Task Alerts',
        channelDesc: 'One-time task reminders',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'task_reminder_$taskId', when.toIso8601String());
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(taskNotifId(taskId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('task_reminder_$taskId');
  }

  Future<DateTime?> getTaskReminderTime(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('task_reminder_$taskId');
    if (stored == null) return null;
    final dt = DateTime.tryParse(stored);
    if (dt != null && dt.isBefore(DateTime.now())) {
      await prefs.remove('task_reminder_$taskId');
      return null;
    }
    return dt;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Load saved settings ───────────────────────────────────────

  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      taskEnabled: prefs.getBool(_kTaskEnabled) ?? false,
      taskHour: prefs.getInt(_kTaskHour) ?? 8,
      taskMin: prefs.getInt(_kTaskMin) ?? 0,
      healthEnabled: prefs.getBool(_kHealthEnabled) ?? false,
      healthHour: prefs.getInt(_kHealthHour) ?? 20,
      healthMin: prefs.getInt(_kHealthMin) ?? 0,
      breakfastEnabled: prefs.getBool(_kBreakfastEnabled) ?? false,
      breakfastHour: prefs.getInt(_kBreakfastHour) ?? 8,
      breakfastMin: prefs.getInt(_kBreakfastMin) ?? 0,
      lunchEnabled: prefs.getBool(_kLunchEnabled) ?? false,
      lunchHour: prefs.getInt(_kLunchHour) ?? 13,
      lunchMin: prefs.getInt(_kLunchMin) ?? 0,
      dinnerEnabled: prefs.getBool(_kDinnerEnabled) ?? false,
      dinnerHour: prefs.getInt(_kDinnerHour) ?? 19,
      dinnerMin: prefs.getInt(_kDinnerMin) ?? 0,
    );
  }
}

// ─── Settings data class ──────────────────────────────────────────

class NotificationSettings {
  final bool taskEnabled;
  final int taskHour, taskMin;
  final bool healthEnabled;
  final int healthHour, healthMin;
  final bool breakfastEnabled;
  final int breakfastHour, breakfastMin;
  final bool lunchEnabled;
  final int lunchHour, lunchMin;
  final bool dinnerEnabled;
  final int dinnerHour, dinnerMin;

  const NotificationSettings({
    required this.taskEnabled,
    required this.taskHour,
    required this.taskMin,
    required this.healthEnabled,
    required this.healthHour,
    required this.healthMin,
    required this.breakfastEnabled,
    required this.breakfastHour,
    required this.breakfastMin,
    required this.lunchEnabled,
    required this.lunchHour,
    required this.lunchMin,
    required this.dinnerEnabled,
    required this.dinnerHour,
    required this.dinnerMin,
  });

  TimeOfDay get taskTime => TimeOfDay(hour: taskHour, minute: taskMin);
  TimeOfDay get healthTime => TimeOfDay(hour: healthHour, minute: healthMin);
  TimeOfDay get breakfastTime =>
      TimeOfDay(hour: breakfastHour, minute: breakfastMin);
  TimeOfDay get lunchTime => TimeOfDay(hour: lunchHour, minute: lunchMin);
  TimeOfDay get dinnerTime =>
      TimeOfDay(hour: dinnerHour, minute: dinnerMin);
}
