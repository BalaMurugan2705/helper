import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutType { rest, strength, cardio, both }

// Calories/protein are intentionally not stored here — the Daily Monitor
// rolls those up live from Food Tracker entries instead of duplicating them.
class DailyLog {
  final String id; // 'yyyy-MM-dd', also the Firestore doc id
  final DateTime date;
  final double? weightKg;
  final double? waistCm;
  final int? steps;
  final double? waterL;
  final double? sleepHours;
  final WorkoutType workoutType;
  final int? energyLevel; // 1-5
  final String? photoUrl; // Cloudinary URL

  DailyLog({
    required this.id,
    required this.date,
    this.weightKg,
    this.waistCm,
    this.steps,
    this.waterL,
    this.sleepHours,
    this.workoutType = WorkoutType.rest,
    this.energyLevel,
    this.photoUrl,
  });

  static String keyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory DailyLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyLog(
      id: doc.id,
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      waistCm: (data['waistCm'] as num?)?.toDouble(),
      steps: (data['steps'] as num?)?.toInt(),
      waterL: (data['waterL'] as num?)?.toDouble(),
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      workoutType: WorkoutType.values.firstWhere(
        (e) => e.name == data['workoutType'],
        orElse: () => WorkoutType.rest,
      ),
      energyLevel: (data['energyLevel'] as num?)?.toInt(),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'weightKg': weightKg,
      'waistCm': waistCm,
      'steps': steps,
      'waterL': waterL,
      'sleepHours': sleepHours,
      'workoutType': workoutType.name,
      'energyLevel': energyLevel,
      'photoUrl': photoUrl,
    };
  }
}
