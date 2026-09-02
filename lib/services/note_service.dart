import 'package:uuid/uuid.dart';
import '../models/note.dart';
import 'storage_service.dart';

class NoteService {
  final StorageService _storage;
  final _uuid = const Uuid();

  NoteService(this._storage);

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

  Future<void> fullSync() async {
    // No-op on Linux desktop - cloud sync only works on mobile
  }
}
