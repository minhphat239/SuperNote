import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import 'auth_service.dart';

class StorageService {
  static const String _prefix = 'notes_';
  final AuthService? _authService;
  late SharedPreferences _prefs;
  String? _currentUserId;

  StorageService({AuthService? authService}) : _authService = authService;

  String get _notesKey => '$_prefix${_currentUserId ?? "guest"}';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _authService?.userId;
  }

  /// Reload notes when user changes (login/logout)
  Future<void> reloadForUser(String? userId) async {
    _currentUserId = userId;
  }

  Future<List<Note>> getAllNotes() async {
    final jsonString = _prefs.getString(_notesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final notes = jsonList.map((e) => Note.fromMap(e)).toList();

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes.where((n) => !n.isDeleted).toList();
  }

  Future<List<Note>> getUnsyncedNotes() async {
    final all = await _getAllIncludingDeleted();
    return all.where((n) => !n.isSynced && !n.isDeleted).toList();
  }

  Future<Note?> getNoteByNoteId(String noteId) async {
    final all = await _getAllIncludingDeleted();
    try {
      return all.firstWhere((n) => n.noteId == noteId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Note>> _getAllIncludingDeleted() async {
    final jsonString = _prefs.getString(_notesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Note.fromMap(e)).toList();
  }

  Future<void> _saveAll(List<Note> notes) async {
    final jsonList = notes.map((e) => e.toMap()).toList();
    await _prefs.setString(_notesKey, jsonEncode(jsonList));
  }

  Future<void> insertNote(Note note) async {
    final all = await _getAllIncludingDeleted();
    all.add(note);
    await _saveAll(all);
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    note.isSynced = false;
    note.syncVersion++;
    final all = await _getAllIncludingDeleted();
    final index = all.indexWhere((n) => n.noteId == note.noteId);
    if (index != -1) {
      all[index] = note;
      await _saveAll(all);
    }
  }

  Future<void> deleteNote(String noteId) async {
    final note = await getNoteByNoteId(noteId);
    if (note != null) {
      note.isDeleted = true;
      note.isSynced = false;
      note.updatedAt = DateTime.now();
      final all = await _getAllIncludingDeleted();
      final index = all.indexWhere((n) => n.noteId == noteId);
      if (index != -1) {
        all[index] = note;
        await _saveAll(all);
      }
    }
  }

  Future<void> markAsSynced(String noteId, String syncId) async {
    final all = await _getAllIncludingDeleted();
    final index = all.indexWhere((n) => n.noteId == noteId);
    if (index != -1) {
      all[index].isSynced = true;
      all[index].syncId = syncId;
      await _saveAll(all);
    }
  }

  Future<void> insertFromCloud(Note note) async {
    final all = await _getAllIncludingDeleted();
    final index = all.indexWhere((n) => n.noteId == note.noteId);
    if (index != -1) {
      all[index] = note;
    } else {
      all.add(note);
    }
    await _saveAll(all);
  }
}
