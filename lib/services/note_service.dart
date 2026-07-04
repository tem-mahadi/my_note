import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _notesRef => _db.collection('notes');

  /// Creates a new note in Firestore
  Future<void> createNote(String title, String description) async {
    final now = DateTime.now();
    final note = Note(
      id: '',
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    await _notesRef.add(note.toFirestore());
  }

  /// Returns a real-time stream of all notes, ordered by creation date (newest first)
  Stream<List<Note>> streamNotes() {
    return _notesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    });
  }

  /// Updates an existing note's title and description
  Future<void> updateNote(
      String id, String title, String description) async {
    await _notesRef.doc(id).update({
      'title': title,
      'description': description,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Deletes a note by its document ID
  Future<void> deleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }
}
