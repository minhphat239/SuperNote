import 'package:uuid/uuid.dart';
import '../models/note.dart';
import 'storage_service.dart';
import 'firestore_repository.dart';
import 'auth_service.dart';

class NoteService {
  final StorageService _storage;
  final AuthService? _authService;
  final _uuid = const Uuid();
  final FirestoreRepository _firestore = FirestoreRepository();

  NoteService(this._storage, {AuthService? authService}) : _authService = authService;

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

    // Push to cloud immediately
    try {
      if (_firestore.isInitialized && _authService?.isLoggedIn == true && !(_authService?.isLocalGuest ?? true)) {
        await _firestore.syncNotesLocalToCloud([note]);
        await _storage.markAsSynced(note.noteId, note.noteId);
      }
    } catch (_) {}

    return note;
  }

  Future<void> updateNote(String noteId, {String? title, String? content}) async {
    final note = await _storage.getNoteByNoteId(noteId);
    if (note != null) {
      if (title != null) note.title = title;
      if (content != null) note.content = content;
      await _storage.updateNote(note);

      // Push to cloud
      try {
        if (_firestore.isInitialized && _authService?.isLoggedIn == true && !(_authService?.isLocalGuest ?? true)) {
          await _firestore.syncNotesLocalToCloud([note]);
          await _storage.markAsSynced(noteId, noteId);
        }
      } catch (_) {}
    }
  }

  Future<void> deleteNote(String noteId) async {
    await _storage.deleteNote(noteId);

    // Soft-delete in cloud
    try {
      if (_firestore.isInitialized && _authService?.isLoggedIn == true && !(_authService?.isLocalGuest ?? true)) {
        final note = Note(noteId: noteId, isDeleted: true, isSynced: false);
        await _firestore.syncNotesLocalToCloud([note]);
      }
    } catch (_) {}
  }

  Future<void> fullSync() async {
    if (!_firestore.isInitialized || !(_authService?.isLoggedIn == true) || (_authService?.isLocalGuest ?? true)) {
      return;
    }
    try {
      final allLocal = await _storage.getAllNotesIncludingDeleted();
      final merged = await _firestore.syncNotesCloudToLocal(allLocal);

      // Save merged cloud data locally
      for (final note in merged) {
        await _storage.insertFromCloud(note);
      }

      // Remove notes that were deleted from cloud but exist locally
      final mergedIds = merged.map((n) => n.noteId).toSet();
      for (final local in allLocal) {
        if (!mergedIds.contains(local.noteId)) {
          await _storage.deleteNote(local.noteId);
        }
      }
    } catch (e) {
      // Sync failed, will retry
    }
  }
}
