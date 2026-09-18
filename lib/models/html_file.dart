import 'package:cloud_firestore/cloud_firestore.dart';

class HtmlFile {
  final String id;
  final String name;
  final String content;
  final int sizeBytes;
  final DateTime createdAt;

  HtmlFile({
    required this.id,
    required this.name,
    required this.content,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory HtmlFile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HtmlFile(
      id: doc.id,
      name: data['name'] ?? 'Untitled.html',
      content: data['content'] ?? '',
      sizeBytes: (data['sizeBytes'] ?? 0) as int,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'content': content,
      'sizeBytes': sizeBytes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
