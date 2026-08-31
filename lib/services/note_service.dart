import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class NoteService {
  final StorageService _storage;
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  NoteService(this._storage, this._authService);

  String? get _userId => _authService.userId;

  CollectionReference? get _notesCollection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('notes');
  }

  Future<List<Note>> getAllNotes() async {
    return await _storage.getAllNotes();
  }

  Future<Note> createNote({String title = '', String content = ''}) async {
    final note = Note(
      noteId: _uuid.v4(),
      title: title,
      content: content,
    );

    await _storage.insertNote(note);
    return note;
  }

  Future<void> updateNote(String noteId, {String? title, String? content}) async {
    final note = await _storage.getNoteByNoteId(noteId);
    if (note != null) {
      if (title != null) note.title = title;
      if (content != null) note.content = content;
      await _storage.updateNote(note);
    }
  }

  Future<void> deleteNote(String noteId) async {
    await _storage.deleteNote(noteId);
  }

  Future<void> syncToCloud() async {
    final collection = _notesCollection;
    if (collection == null) return;

    final unsyncedNotes = await _storage.getUnsyncedNotes();

    for (final note in unsyncedNotes) {
      try {
        if (note.syncId != null) {
          await collection.doc(note.syncId).update(note.toMap());
        } else {
          final docRef = await collection.add(note.toMap());
          await _storage.markAsSynced(note.noteId, docRef.id);
        }
      } catch (e) {
        // Skip failed sync, will retry next time
      }
    }
  }

  Future<void> syncFromCloud() async {
    final collection = _notesCollection;
    if (collection == null) return;

    try {
      final snapshot = await collection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['syncId'] = doc.id;

        final note = Note.fromMap(data);
        final localNote = await _storage.getNoteByNoteId(note.noteId);

        if (localNote == null || note.updatedAt.isAfter(localNote.updatedAt)) {
          note.isSynced = true;
          await _storage.insertFromCloud(note);
        }
      }
    } catch (e) {
      // Will retry on next sync
    }
  }

  Future<void> fullSync() async {
    if (_userId == null) return;
    await syncToCloud();
    await syncFromCloud();
  }
}
