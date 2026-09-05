import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/note.dart';

void main() {
  group('Note Model', () {
    // ===== Constructor & Defaults =====
    test('1. Default constructor creates note with required noteId', () {
      final note = Note(noteId: 'n1');
      expect(note.noteId, 'n1');
      expect(note.title, '');
      expect(note.content, '');
      expect(note.isDeleted, isFalse);
      expect(note.syncId, isNull);
      expect(note.syncVersion, 0);
      expect(note.isSynced, isFalse);
    });

    test('2. Constructor sets createdAt and updatedAt to now when null', () {
      final before = DateTime.now();
      final note = Note(noteId: 'n1');
      final after = DateTime.now();
      expect(note.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(note.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(note.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });

    test('3. Constructor accepts explicit dates and sync fields', () {
      final date = DateTime(2026, 3, 15);
      final note = Note(
        noteId: 'n1', title: 'T', content: 'C',
        createdAt: date, updatedAt: date,
        isDeleted: true, syncId: 'sync-1', syncVersion: 5, isSynced: true,
      );
      expect(note.createdAt, date);
      expect(note.updatedAt, date);
      expect(note.isDeleted, isTrue);
      expect(note.syncId, 'sync-1');
      expect(note.syncVersion, 5);
      expect(note.isSynced, isTrue);
    });

    // ===== toMap / fromMap =====
    test('4. toMap produces correct JSON map', () {
      final note = Note(
        noteId: 'n1', title: 'Title', content: 'Content',
        isDeleted: false, syncId: 's1', syncVersion: 3, isSynced: true,
      );
      final m = note.toMap();
      expect(m['noteId'], 'n1');
      expect(m['title'], 'Title');
      expect(m['content'], 'Content');
      expect(m['isDeleted'], false);
      expect(m['syncId'], 's1');
      expect(m['syncVersion'], 3);
      expect(m['isSynced'], true);
      expect(m['createdAt'], isNotNull);
      expect(m['updatedAt'], isNotNull);
    });

    test('5. fromMap recreates note from toMap output', () {
      final original = Note(
        noteId: 'n1', title: 'Title', content: 'Content',
        createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 2),
        isDeleted: true, syncId: 's1', syncVersion: 5, isSynced: true,
      );
      final m = original.toMap();
      final restored = Note.fromMap(m);
      expect(restored.noteId, original.noteId);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.isDeleted, original.isDeleted);
      expect(restored.syncId, original.syncId);
      expect(restored.syncVersion, original.syncVersion);
      expect(restored.isSynced, original.isSynced);
    });

    test('6. fromMap handles missing fields with defaults', () {
      final m = <String, dynamic>{};
      final note = Note.fromMap(m);
      expect(note.noteId, '');
      expect(note.title, '');
      expect(note.content, '');
      expect(note.isDeleted, false);
      expect(note.syncId, isNull);
      expect(note.syncVersion, 0);
      expect(note.isSynced, false);
    });

    // ===== JSON round-trip =====
    test('7. toJson/fromJson round-trip', () {
      final note = Note(
        noteId: 'n1', title: 'Test', content: 'Hello',
        syncId: 's1', syncVersion: 2,
      );
      final json = note.toJson();
      final restored = Note.fromJson(json);
      expect(restored.noteId, note.noteId);
      expect(restored.title, note.title);
      expect(restored.content, note.content);
      expect(restored.syncId, note.syncId);
      expect(restored.syncVersion, note.syncVersion);
    });

    test('8. toJson returns valid JSON string', () {
      final note = Note(noteId: 'n1', title: 'T', content: 'C');
      final json = note.toJson();
      expect(json, isNotEmpty);
      expect(json.startsWith('{'), isTrue);
      expect(json.endsWith('}'), isTrue);
    });

    // ===== Mutation =====
    test('9. Note fields are mutable', () {
      final note = Note(noteId: 'n1');
      note.title = 'New Title';
      note.content = 'New Content';
      note.isDeleted = true;
      note.syncVersion = 10;
      note.isSynced = true;
      note.syncId = 'sync-x';
      expect(note.title, 'New Title');
      expect(note.content, 'New Content');
      expect(note.isDeleted, isTrue);
      expect(note.syncVersion, 10);
      expect(note.isSynced, isTrue);
      expect(note.syncId, 'sync-x');
    });

    test('10. updatedAt is mutable', () {
      final note = Note(noteId: 'n1');
      final newDate = DateTime(2030, 6, 15);
      note.updatedAt = newDate;
      expect(note.updatedAt, newDate);
    });

    // ===== Edge cases =====
    test('11. fromMap with null createdAt uses DateTime.now()', () {
      final m = <String, dynamic>{'noteId': 'n1'};
      final note = Note.fromMap(m);
      final now = DateTime.now();
      expect(note.createdAt.difference(now).inSeconds, 0);
    });

    test('12. fromMap with null updatedAt uses DateTime.now()', () {
      final m = <String, dynamic>{'noteId': 'n1'};
      final note = Note.fromMap(m);
      final now = DateTime.now();
      expect(note.updatedAt.difference(now).inSeconds, 0);
    });

    test('13. Note supports unicode content', () {
      final note = Note(noteId: 'n1', title: 'Tiếng Việt', content: 'Xin chào thế giới 🌍');
      final m = note.toMap();
      final restored = Note.fromMap(m);
      expect(restored.title, 'Tiếng Việt');
      expect(restored.content, 'Xin chào thế giới 🌍');
    });

    test('14. Note handles long content', () {
      final longContent = 'A' * 10000;
      final note = Note(noteId: 'n1', content: longContent);
      final m = note.toMap();
      final restored = Note.fromMap(m);
      expect(restored.content.length, 10000);
    });

    test('15. Note handles special characters in JSON', () {
      final note = Note(noteId: 'n1', title: r'Quote "back\slash" /slash');
      final json = note.toJson();
      final restored = Note.fromJson(json);
      expect(restored.title, r'Quote "back\slash" /slash');
    });

    test('16. Multiple notes can be serialized independently', () {
      final notes = [
        Note(noteId: 'n1', title: 'First'),
        Note(noteId: 'n2', title: 'Second'),
        Note(noteId: 'n3', title: 'Third'),
      ];
      final maps = notes.map((n) => n.toMap()).toList();
      final restored = maps.map((m) => Note.fromMap(m)).toList();
      expect(restored[0].title, 'First');
      expect(restored[1].title, 'Second');
      expect(restored[2].title, 'Third');
    });

    test('17. Note with default sync values in fromMap', () {
      final m = {'noteId': 'n1', 'title': 'T'};
      final note = Note.fromMap(m);
      expect(note.syncVersion, 0);
      expect(note.isSynced, false);
      expect(note.isDeleted, false);
    });

    test('18. createdAt/updatedAt parse ISO 8601 from map', () {
      final m = {
        'noteId': 'n1',
        'createdAt': '2026-05-20T10:30:00.000',
        'updatedAt': '2026-05-21T14:00:00.000',
      };
      final note = Note.fromMap(m);
      expect(note.createdAt.year, 2026);
      expect(note.createdAt.month, 5);
      expect(note.createdAt.day, 20);
      expect(note.updatedAt.year, 2026);
      expect(note.updatedAt.day, 21);
    });

    test('19. fromMap handles isDeleted false', () {
      final m = {'noteId': 'n1', 'isDeleted': false};
      final note = Note.fromMap(m);
      expect(note.isDeleted, false);
    });

    test('20. Empty noteId is valid', () {
      final note = Note(noteId: '');
      expect(note.noteId, '');
      final m = note.toMap();
      final restored = Note.fromMap(m);
      expect(restored.noteId, '');
    });
  });
}
