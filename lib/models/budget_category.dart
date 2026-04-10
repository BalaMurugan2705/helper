import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCategory {
  final String id;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final String icon;
  final String color;

  BudgetCategory({
    required this.id,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.icon,
    required this.color,
  });

  double get percentUsed =>
      budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 2.0) : 0.0;

  double get remaining => budgetAmount - spentAmount;

  bool get isOverBudget => spentAmount > budgetAmount;

  factory BudgetCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetCategory(
      id: doc.id,
      category: data['category'] ?? '',
      budgetAmount: (data['budgetAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      icon: data['icon'] ?? 'category',
      color: data['color'] ?? '#7C4DFF',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'icon': icon,
      'color': color,
    };
  }

  BudgetCategory copyWith({
    String? id,
    String? category,
    double? budgetAmount,
    double? spentAmount,
    String? icon,
    String? color,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
