import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitType { binary, measurement }

class HealthHabit {
  final String id;
  final String name;
  final double goal;
  final String unit;
  final double todayValue;
  final int streak;
  final Map<String, double> dailyLog; // 'YYYY-MM-DD' → value logged that day
  final String icon;
  final HabitType habitType;
  final String lastResetDate;

  HealthHabit({
    required this.id,
    required this.name,
    required this.goal,
    required this.unit,
    required this.todayValue,
    required this.streak,
    required this.dailyLog,
    required this.icon,
    this.habitType = HabitType.measurement,
    this.lastResetDate = '',
  });

  double get progressPercent {
    if (habitType == HabitType.binary) return todayValue >= 1 ? 1.0 : 0.0;
    return goal > 0 ? (todayValue / goal).clamp(0.0, 1.0) : 0.0;
  }

  bool get isCompleted =>
      habitType == HabitType.binary ? todayValue >= 1 : todayValue >= goal;

  bool completedOnDate(String dateKey) {
    if (dateKey == lastResetDate) return isCompleted;
    final val = dailyLog[dateKey] ?? 0.0;
    return val >= (habitType == HabitType.binary ? 1.0 : goal);
  }

  factory HealthHabit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final typeStr = data['habitType'] as String? ?? 'measurement';
    final rawLog = data['dailyLog'] as Map<String, dynamic>? ?? {};
    return HealthHabit(
      id: doc.id,
      name: data['name'] ?? '',
      goal: (data['goal'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      todayValue: (data['todayValue'] ?? 0).toDouble(),
      streak: data['streak'] ?? 0,
      dailyLog: rawLog.map((k, v) => MapEntry(k, (v as num).toDouble())),
      icon: data['icon'] ?? 'favorite',
      habitType: typeStr == 'binary' ? HabitType.binary : HabitType.measurement,
      lastResetDate: data['lastResetDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'goal': goal,
      'unit': unit,
      'todayValue': todayValue,
      'streak': streak,
      'dailyLog': dailyLog,
      'icon': icon,
      'habitType': habitType == HabitType.binary ? 'binary' : 'measurement',
      'lastResetDate': lastResetDate,
    };
  }

  HealthHabit copyWith({
    String? id,
    String? name,
    double? goal,
    String? unit,
    double? todayValue,
    int? streak,
    Map<String, double>? dailyLog,
    String? icon,
    HabitType? habitType,
    String? lastResetDate,
  }) {
    return HealthHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      unit: unit ?? this.unit,
      todayValue: todayValue ?? this.todayValue,
      streak: streak ?? this.streak,
      dailyLog: dailyLog ?? this.dailyLog,
      icon: icon ?? this.icon,
      habitType: habitType ?? this.habitType,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
