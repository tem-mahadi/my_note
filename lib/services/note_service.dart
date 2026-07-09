import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';
import '../service/user_data.dart';

/// CRUD for notes in Firestore.
///
/// Every user's notes live in their own subcollection:
///   `/users/{userId}/notes/{noteId}`
///
/// This guarantees users can never read or write each other's notes, even
/// if the Firestore security rules are left permissive for development.
///
/// [userId] defaults to the mobile number from [UserData] (the bdapps
/// subscriber id). Callers can override it for tests; passing `null` is
/// allowed and disables persistence — all writes become no-ops and all
/// streams emit an empty list, which is the safest behaviour when a user
/// is not logged in.
class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Optional override for the user id; primarily used in tests.
  final String? Function()? _userIdOverride;

  NoteService({String? Function()? userIdOverride})
    : _userIdOverride = userIdOverride;
  // ignore: prefer_initializing_formals

  /// Returns the current user's id, or `null` when there is no active
  /// session. Callers should treat `null` as "no persistence" — writes
  /// become no-ops and streams emit an empty list.
  String? get _userId {
    final override = _userIdOverride;
    if (override != null) return override();
    if (UserData.userNumber.isEmpty) return null;
    return UserData.userNumber;
  }

  /// Reference to the current user's notes subcollection. Throws a
  /// [StateError] if there is no active user — callers should always gate
  /// on [_userId] first so they can short-circuit to a no-op.
  CollectionReference get _notesRef {
    final uid = _userId;
    if (uid == null) {
      throw StateError(
        'NoteService: no active user. Guard calls with `_userId != null`.',
      );
    }
    return _db.collection('users').doc(uid).collection('notes');
  }

  // ── Writes ─────────────────────────────────────────────────────

  /// Creates a new note in the current user's subcollection.
  /// Returns the new document id, or `null` if there is no active user.
  Future<String?> createNote(String title, String description) async {
    if (_userId == null) return null;
    final now = DateTime.now();
    final note = Note(
      id: '',
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    final ref = await _notesRef.add(note.toFirestore());
    return ref.id;
  }

  /// Updates an existing note's title and description.
  /// No-op if there is no active user or the note is missing.
  Future<void> updateNote(String id, String title, String description) async {
    if (_userId == null) return;
    await _notesRef.doc(id).update({
      'title': title,
      'description': description,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Persists a freshly computed embedding for [id]. Called after a note's
  /// content changes so the next semantic search picks it up.
  Future<void> updateEmbedding(String id, List<double> embedding) async {
    if (_userId == null) return;
    await _notesRef.doc(id).update({'embedding': embedding});
  }

  /// Deletes a note by its document ID.
  Future<void> deleteNote(String id) async {
    if (_userId == null) return;
    await _notesRef.doc(id).delete();
  }

  // ── Reads ──────────────────────────────────────────────────────

  /// Real-time stream of the current user's notes (newest first).
  /// Emits an empty list when there is no active user.
  Stream<List<Note>> streamNotes() {
    if (_userId == null) return Stream.value(const []);
    return _notesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Note.fromFirestore).toList());
  }

  /// One-shot fetch of every note for the current user. Useful for
  /// semantic search so we can score a query against the full corpus
  /// in memory.
  Future<List<Note>> fetchAllNotes() async {
    if (_userId == null) return const [];
    final snap = await _notesRef.orderBy('createdAt', descending: true).get();
    return snap.docs.map(Note.fromFirestore).toList();
  }
}
