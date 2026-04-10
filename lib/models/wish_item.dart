import 'package:cloud_firestore/cloud_firestore.dart';

enum WishCategory { buy, travel, experience, food, beauty, home, other }

enum WishStatus { pending, achieved }

class WishItem {
  final String id;
  final String title;
  final String description;
  final WishCategory category;
  final double estimatedCost;
  final int quantity;
  final WishStatus status;
  final DateTime addedDate;
  final String note;

  WishItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedCost,
    this.quantity = 1,
    required this.status,
    required this.addedDate,
    required this.note,
  });

  double get totalCost => estimatedCost * quantity;

  String get categoryLabel {
    switch (category) {
      case WishCategory.buy:
        return 'Buy';
      case WishCategory.travel:
        return 'Travel';
      case WishCategory.experience:
        return 'Experience';
      case WishCategory.food:
        return 'Food';
      case WishCategory.beauty:
        return 'Beauty';
      case WishCategory.home:
        return 'Home';
      case WishCategory.other:
        return 'Other';
    }
  }

  factory WishItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WishItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: WishCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => WishCategory.other,
      ),
      estimatedCost: (data['estimatedCost'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1) as int,
      status: WishStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WishStatus.pending,
      ),
      addedDate: data['addedDate'] != null
          ? (data['addedDate'] as Timestamp).toDate()
          : DateTime.now(),
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'estimatedCost': estimatedCost,
      'quantity': quantity,
      'status': status.name,
      'addedDate': Timestamp.fromDate(addedDate),
      'note': note,
    };
  }

  WishItem copyWith({
    String? id,
    String? title,
    String? description,
    WishCategory? category,
    double? estimatedCost,
    int? quantity,
    WishStatus? status,
    DateTime? addedDate,
    String? note,
  }) {
    return WishItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      addedDate: addedDate ?? this.addedDate,
      note: note ?? this.note,
    );
  }
}
