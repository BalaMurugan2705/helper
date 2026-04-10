import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskFrequency {
  daily,
  every3Days,
  weekly,
  biweekly,
  monthly,
  every2Months,
  every3Months,
  every4Months,
  every5Months;

  int get days {
    switch (this) {
      case TaskFrequency.daily:
        return 1;
      case TaskFrequency.every3Days:
        return 3;
      case TaskFrequency.weekly:
        return 7;
      case TaskFrequency.biweekly:
        return 14;
      case TaskFrequency.monthly:
        return 30;
      case TaskFrequency.every2Months:
        return 60;
      case TaskFrequency.every3Months:
        return 90;
      case TaskFrequency.every4Months:
        return 120;
      case TaskFrequency.every5Months:
        return 150;
    }
  }

  String get label {
    switch (this) {
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.every3Days:
        return 'Every 3 Days';
      case TaskFrequency.weekly:
        return 'Weekly';
      case TaskFrequency.biweekly:
        return 'Every 2 Weeks';
      case TaskFrequency.monthly:
        return 'Monthly';
      case TaskFrequency.every2Months:
        return 'Every 2 Months';
      case TaskFrequency.every3Months:
        return 'Every 3 Months';
      case TaskFrequency.every4Months:
        return 'Every 4 Months';
      case TaskFrequency.every5Months:
        return 'Every 5 Months';
    }
  }

  String get shortLabel {
    switch (this) {
      case TaskFrequency.daily:
        return 'DAILY';
      case TaskFrequency.every3Days:
        return '3-DAY';
      case TaskFrequency.weekly:
        return 'WEEKLY';
      case TaskFrequency.biweekly:
        return '2-WEEK';
      case TaskFrequency.monthly:
        return 'MONTHLY';
      case TaskFrequency.every2Months:
        return '2-MONTH';
      case TaskFrequency.every3Months:
        return '3-MONTH';
      case TaskFrequency.every4Months:
        return '4-MONTH';
      case TaskFrequency.every5Months:
        return '5-MONTH';
    }
  }
}

enum TaskStatus { pending, done }

class CleaningTask {
  final String id;
  final String name;
  final String room;
  final TaskFrequency frequency;
  final DateTime lastDoneDate;
  final TaskStatus status;
  final String color;

  CleaningTask({
    required this.id,
    required this.name,
    required this.room,
    required this.frequency,
    required this.lastDoneDate,
    required this.status,
    required this.color,
  });

  int get frequencyDays => frequency.days;

  DateTime get nextDueDate => lastDoneDate.add(Duration(days: frequencyDays));

  int get daysOverdue {
    final today = DateTime.now();
    final due = nextDueDate;
    if (today.isAfter(due)) {
      return today.difference(due).inDays;
    }
    return 0;
  }

  int get daysUntilDue {
    final today = DateTime.now();
    final due = nextDueDate;
    if (due.isAfter(today)) {
      return due.difference(today).inDays;
    }
    return 0;
  }

  bool get isOverdue => daysOverdue > 0;
  bool get isDueToday {
    final today = DateTime.now();
    final due = nextDueDate;
    return due.year == today.year &&
        due.month == today.month &&
        due.day == today.day;
  }

  factory CleaningTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CleaningTask(
      id: doc.id,
      name: data['name'] ?? '',
      room: data['room'] ?? '',
      frequency: TaskFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => TaskFrequency.weekly,
      ),
      lastDoneDate: (data['lastDoneDate'] as Timestamp).toDate(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      color: data['color'] ?? '#7C4DFF',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'room': room,
      'frequency': frequency.name,
      'lastDoneDate': Timestamp.fromDate(lastDoneDate),
      'status': status.name,
      'color': color,
    };
  }

  CleaningTask copyWith({
    String? id,
    String? name,
    String? room,
    TaskFrequency? frequency,
    DateTime? lastDoneDate,
    TaskStatus? status,
    String? color,
  }) {
    return CleaningTask(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      frequency: frequency ?? this.frequency,
      lastDoneDate: lastDoneDate ?? this.lastDoneDate,
      status: status ?? this.status,
      color: color ?? this.color,
    );
  }
}
