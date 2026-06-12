import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCategory {
  final String id;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final String icon;
  final String color;
  final int month;
  final int year;

  BudgetCategory({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.icon,
    required this.color,
    required this.month,
    required this.year,
  });

  double get percentUsed =>
      budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 2.0) : 0.0;

  double get remaining => budgetAmount - spentAmount;

  bool get isOverBudget => spentAmount > budgetAmount;

  factory BudgetCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    return BudgetCategory(
      id: doc.id,
      category: data['category'] ?? '',
      budgetAmount: (data['budgetAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      icon: data['icon'] ?? 'category',
      color: data['color'] ?? '#7C4DFF',
      month: (data['month'] as int?) ?? now.month,
      year: (data['year'] as int?) ?? now.year,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'icon': icon,
      'color': color,
      'month': month,
      'year': year,
    };
  }

  BudgetCategory copyWith({
    String? id,
    String? category,
    double? budgetAmount,
    double? spentAmount,
    String? icon,
    String? color,
    int? month,
    int? year,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
