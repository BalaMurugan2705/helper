import 'package:cloud_firestore/cloud_firestore.dart';

class HealthHabit {
  final String id;
  final String name;
  final double goal;
  final String unit;
  final double todayValue;
  final int streak;
  final List<double> weeklyData;
  final String icon;

  HealthHabit({
    required this.id,
    required this.name,
    required this.goal,
    required this.unit,
    required this.todayValue,
    required this.streak,
    required this.weeklyData,
    required this.icon,
  });

  double get progressPercent =>
      goal > 0 ? (todayValue / goal).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => todayValue >= goal;

  factory HealthHabit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawWeekly = data['weeklyData'] as List<dynamic>? ?? [];
    return HealthHabit(
      id: doc.id,
      name: data['name'] ?? '',
      goal: (data['goal'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      todayValue: (data['todayValue'] ?? 0).toDouble(),
      streak: data['streak'] ?? 0,
      weeklyData: rawWeekly.map((e) => (e as num).toDouble()).toList(),
      icon: data['icon'] ?? 'favorite',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'goal': goal,
      'unit': unit,
      'todayValue': todayValue,
      'streak': streak,
      'weeklyData': weeklyData,
      'icon': icon,
    };
  }

  HealthHabit copyWith({
    String? id,
    String? name,
    double? goal,
    String? unit,
    double? todayValue,
    int? streak,
    List<double>? weeklyData,
    String? icon,
  }) {
    return HealthHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      unit: unit ?? this.unit,
      todayValue: todayValue ?? this.todayValue,
      streak: streak ?? this.streak,
      weeklyData: weeklyData ?? this.weeklyData,
      icon: icon ?? this.icon,
    );
  }
}
