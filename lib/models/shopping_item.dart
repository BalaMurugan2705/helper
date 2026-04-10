import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemPriority {
  essential,
  high,
  medium,
  basic;

  String get label {
    switch (this) {
      case ItemPriority.essential:
        return 'Essential';
      case ItemPriority.high:
        return 'High';
      case ItemPriority.medium:
        return 'Medium';
      case ItemPriority.basic:
        return 'Basic';
    }
  }
}

class ShoppingItem {
  final String id;
  final String name;
  final String category;
  final ItemPriority priority;
  final double cost;
  final bool bought;
  final int quantity;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.priority,
    required this.cost,
    required this.bought,
    required this.quantity,
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      priority: ItemPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => ItemPriority.medium,
      ),
      cost: (data['cost'] ?? 0).toDouble(),
      bought: data['bought'] ?? false,
      quantity: data['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'priority': priority.name,
      'cost': cost,
      'bought': bought,
      'quantity': quantity,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? category,
    ItemPriority? priority,
    double? cost,
    bool? bought,
    int? quantity,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      cost: cost ?? this.cost,
      bought: bought ?? this.bought,
      quantity: quantity ?? this.quantity,
    );
  }
}
