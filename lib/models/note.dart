import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Embedding vector used for semantic search. Null until the AI service has
  /// computed it. Persisted as a plain list of doubles in Firestore.
  final List<double>? embedding;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.embedding,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawEmbedding = data['embedding'] as List?;
    return Note(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      embedding: rawEmbedding?.map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (embedding != null) 'embedding': embedding,
    };
  }

  Note copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    List<double>? embedding,
    bool clearEmbedding = false,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      embedding: clearEmbedding ? null : (embedding ?? this.embedding),
    );
  }
}
