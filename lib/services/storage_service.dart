import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import 'auth_service.dart';

class StorageService {
  static const String _prefix = 'notes_';
  final AuthService? _authService;
  SharedPreferences? _prefs;
  String? _currentUserId;

  StorageService({this._authService});

  String get _notesKey => '$_prefix${_currentUserId ?? "guest"}';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _authService?.userId;
  }

  /// Reload notes when user changes (login/logout)
  Future<void> reloadForUser(String? userId) async {
    // Migrate guest notes to user notes on login
    if (userId != null && _prefs != null) {
      final guestData = _prefs!.getString('notes_guest');
      if (guestData != null && guestData.isNotEmpty) {
        final userKey = 'notes_$userId';
        final userData = _prefs!.getString(userKey);
        if (userData == null || userData.isEmpty) {
          // No existing user notes → just copy guest data
          await _prefs!.setString(userKey, guestData);
        } else {
          // Merge guest notes into user notes
          try {
            final guestList = (jsonDecode(guestData) as List).whereType<Map>().map((e) => Note.fromMap(Map<String, dynamic>.from(e))).toList();
            final userList = (jsonDecode(userData) as List).whereType<Map>().map((e) => Note.fromMap(Map<String, dynamic>.from(e))).toList();
            final existingIds = userList.map((n) => n.noteId).toSet();
            final newNotes = guestList.where((n) => !existingIds.contains(n.noteId)).toList();
            if (newNotes.isNotEmpty) {
              final merged = [...userList, ...newNotes];
              await _prefs!.setString(userKey, jsonEncode(merged.map((e) => e.toMap()).toList()));
            }
          } catch (_) {}
        }
        // Clean up guest data
        await _prefs!.remove('notes_guest');
      }
    }
    _currentUserId = userId;
  }

  Future<List<Note>> getAllNotes() async {
    if (_prefs == null) return [];
    final jsonString = _prefs!.getString(_notesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final notes = jsonList.map((e) => Note.fromMap(e)).toList();

      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes.where((n) => !n.isDeleted).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Note>> getAllNotesIncludingDeleted() async {
    return await _getAllIncludingDeleted();
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
    if (_prefs == null) return [];
    final jsonString = _prefs!.getString(_notesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Note.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<Note> notes) async {
    if (_prefs == null) return;
    final jsonList = notes.map((e) => e.toMap()).toList();
    await _prefs!.setString(_notesKey, jsonEncode(jsonList));
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
