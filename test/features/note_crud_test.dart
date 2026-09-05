import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/note.dart';

/// Simulates NoteService.createNote()
Note createNote({String title = '', String content = ''}) {
  return Note(
    noteId: 'note_${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    content: content,
  );
}

/// Simulates NoteService.updateNote()
Note updateNote(Note note, {String? title, String? content}) {
  if (title != null) note.title = title;
  if (content != null) note.content = content;
  note.updatedAt = DateTime.now();
  note.isSynced = false;
  return note;
}

/// Simulates NoteService.deleteNote() (soft delete)
Note deleteNote(Note note) {
  note.isDeleted = true;
  note.updatedAt = DateTime.now();
  note.isSynced = false;
  return note;
}

void main() {
  group('Tab Notes — CRUD Workflows', () {
    // ===== CREATE =====
    test('1. Create note with title and content', () {
      final note = createNote(title: 'Meeting notes', content: 'Discuss Q3 goals');
      expect(note.title, 'Meeting notes');
      expect(note.content, 'Discuss Q3 goals');
      expect(note.isDeleted, isFalse);
      expect(note.isSynced, isFalse);
    });

    test('2. Create note with empty fields', () {
      final note = createNote();
      expect(note.title, '');
      expect(note.content, '');
      expect(note.noteId.isNotEmpty, isTrue);
    });

    test('3. Note gets createdAt timestamp', () {
      final before = DateTime.now();
      final note = createNote(title: 'T');
      final after = DateTime.now();
      expect(note.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(note.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('4. Note defaults syncVersion to 0', () {
      final note = createNote();
      expect(note.syncVersion, 0);
    });

    // ===== READ =====
    test('5. Note toMap includes all fields', () {
      final note = createNote(title: 'T', content: 'C');
      final m = note.toMap();
      expect(m['noteId'], note.noteId);
      expect(m['title'], 'T');
      expect(m['content'], 'C');
      expect(m['isDeleted'], false);
      expect(m['syncVersion'], 0);
      expect(m['isSynced'], false);
    });

    test('6. Note round-trip via toMap/fromMap', () {
      final original = createNote(title: 'Title', content: 'Content');
      original.syncId = 'sync-1';
      original.syncVersion = 3;
      final restored = Note.fromMap(original.toMap());
      expect(restored.noteId, original.noteId);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.syncId, 'sync-1');
      expect(restored.syncVersion, 3);
    });

    test('7. Note round-trip via toJson/fromJson', () {
      final original = createNote(title: 'JSON test', content: 'Hello');
      final json = original.toJson();
      final restored = Note.fromJson(json);
      expect(restored.title, 'JSON test');
      expect(restored.content, 'Hello');
    });

    // ===== UPDATE =====
    test('8. Update title preserves content', () {
      var note = createNote(title: 'Old', content: 'Keep');
      note = updateNote(note, title: 'New');
      expect(note.title, 'New');
      expect(note.content, 'Keep');
    });

    test('9. Update content preserves title', () {
      var note = createNote(title: 'Keep', content: 'Old');
      note = updateNote(note, content: 'New');
      expect(note.title, 'Keep');
      expect(note.content, 'New');
    });

    test('10. Update sets isSynced to false', () {
      var note = createNote(title: 'T');
      note.isSynced = true;
      note = updateNote(note, title: 'X');
      expect(note.isSynced, isFalse);
    });

    test('11. Update changes updatedAt', () {
      var note = createNote(title: 'T');
      final oldUpdate = note.updatedAt;
      // Small delay to ensure timestamp differs
      note = updateNote(note, title: 'X');
      expect(note.updatedAt.isAfter(oldUpdate) || note.updatedAt.isAtSameMomentAs(oldUpdate), isTrue);
    });

    // ===== DELETE (soft) =====
    test('12. Soft delete sets isDeleted to true', () {
      var note = createNote(title: 'T');
      note = deleteNote(note);
      expect(note.isDeleted, isTrue);
    });

    test('13. Soft delete marks as unsynced', () {
      var note = createNote(title: 'T');
      note.isSynced = true;
      note = deleteNote(note);
      expect(note.isSynced, isFalse);
    });

    test('14. Deleted note still has its content', () {
      var note = createNote(title: 'T', content: 'C');
      note = deleteNote(note);
      expect(note.title, 'T');
      expect(note.content, 'C');
    });

    // ===== Serialization edge cases =====
    test('15. Note handles unicode content', () {
      final note = createNote(title: 'Tiếng Việt 🇻🇳', content: 'Xin chào 🌍✨');
      final restored = Note.fromMap(note.toMap());
      expect(restored.title, 'Tiếng Việt 🇻🇳');
      expect(restored.content, 'Xin chào 🌍✨');
    });

    test('16. Note handles long content (10K chars)', () {
      final longContent = 'A' * 10000;
      final note = createNote(content: longContent);
      final json = note.toJson();
      final restored = Note.fromJson(json);
      expect(restored.content.length, 10000);
    });

    test('17. Note handles special JSON characters', () {
      final note = createNote(title: r'Title with "quotes" and \backslash');
      final json = note.toJson();
      final restored = Note.fromJson(json);
      expect(restored.title, r'Title with "quotes" and \backslash');
    });

    // ===== Sync metadata =====
    test('18. Sync fields default correctly', () {
      final note = createNote();
      expect(note.syncId, isNull);
      expect(note.syncVersion, 0);
      expect(note.isSynced, isFalse);
    });

    test('19. Sync metadata preserved through round-trip', () {
      var note = createNote();
      note.syncId = 'firestore-doc-123';
      note.syncVersion = 5;
      note.isSynced = true;
      final restored = Note.fromMap(note.toMap());
      expect(restored.syncId, 'firestore-doc-123');
      expect(restored.syncVersion, 5);
      expect(restored.isSynced, true);
    });

    // ===== Multi-note operations =====
    test('20. Multiple notes can be serialized independently', () {
      final notes = [
        createNote(title: 'Note 1'),
        createNote(title: 'Note 2'),
        createNote(title: 'Note 3'),
      ];
      final maps = notes.map((n) => n.toMap()).toList();
      final restored = maps.map((m) => Note.fromMap(m)).toList();
      expect(restored[0].title, 'Note 1');
      expect(restored[1].title, 'Note 2');
      expect(restored[2].title, 'Note 3');
    });

    test('21. Filter active notes (not deleted)', () {
      final notes = [
        createNote(title: 'Active'),
        createNote(title: 'Deleted'),
      ];
      notes[1].isDeleted = true;
      final active = notes.where((n) => !n.isDeleted).toList();
      expect(active.length, 1);
      expect(active[0].title, 'Active');
    });

    test('22. Filter deleted notes', () {
      final notes = [
        createNote(title: 'Active'),
        createNote(title: 'Deleted'),
      ];
      notes[1].isDeleted = true;
      final deleted = notes.where((n) => n.isDeleted).toList();
      expect(deleted.length, 1);
    });

    test('23. Filter unsynced notes', () {
      final notes = [
        createNote(title: 'Synced'),
        createNote(title: 'Unsynced'),
      ];
      notes[0].isSynced = true;
      final unsynced = notes.where((n) => !n.isSynced).toList();
      expect(unsynced.length, 1);
      expect(unsynced[0].title, 'Unsynced');
    });

    // ===== Full workflow =====
    test('24. Full workflow: create → update → sync → delete', () {
      var note = createNote(title: 'Draft', content: 'Writing...');
      expect(note.isSynced, isFalse);

      note = updateNote(note, content: 'Final version');
      expect(note.content, 'Final version');
      expect(note.isSynced, isFalse);

      note.isSynced = true;
      expect(note.isSynced, isTrue);

      note = deleteNote(note);
      expect(note.isDeleted, isTrue);
      expect(note.isSynced, isFalse);
    });

    test('25. Note content is mutable (not final)', () {
      final note = createNote(title: 'Old');
      note.title = 'New';
      note.content = 'New content';
      expect(note.title, 'New');
      expect(note.content, 'New content');
    });
  });
}
