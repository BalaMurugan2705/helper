import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}

class FoodEntry {
  final String id;
  final String name;
  final MealType mealType;
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final DateTime date;
  final String note;

  FoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.date,
    this.note = '',
  });

  factory FoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodEntry(
      id: doc.id,
      name: data['name'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == data['mealType'],
        orElse: () => MealType.snack,
      ),
      calories: (data['calories'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'mealType': mealType.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  FoodEntry copyWith({
    String? id,
    String? name,
    MealType? mealType,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? date,
    String? note,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
