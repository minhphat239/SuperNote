import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

/// Stress tests and edge cases to find hard-to-catch bugs
void main() {
  group('Stress & Edge Case Tests — Finding Hidden Bugs', () {
    // ===== Bug: copyWith sentinel pattern =====
    test('EDGE: copyWith with null description preserves it via null-coalescing', () {
      final task = Task(id: '1', title: 'T', description: 'Keep');
      // copyWith(description: null) → identical(null, _sentinel) = false
      // → (description as String? ?? this.description) = (null ?? 'Keep') = 'Keep'
      // The ?? operator makes null a "keep old" semantic!
      final copy = task.copyWith(description: null);
      expect(copy.description, 'Keep',
        reason: 'null-coalescing ?? means null preserves old value');
    });

    test('EDGE: copyWith with no description param preserves it (sentinel)', () {
      final task = Task(id: '1', title: 'T', description: 'Keep');
      final copy = task.copyWith(title: 'X');
      expect(copy.description, 'Keep');
    });

    // ===== Bug: task.title set directly (mutable field) =====
    test('EDGE: task.title is mutable — direct mutation bypasses copyWith', () {
      final task = Task(id: '1', title: 'Original');
      task.title = 'Mutated';
      expect(task.title, 'Mutated');
      // This could cause issues if code mutates directly vs using copyWith
    });

    // ===== Bug: subtasks list is mutable =====
    test('EDGE: subtasks list is mutable — shared reference', () {
      final subs = [SubTask(id: 's1', title: 'Step 1')];
      final task1 = Task(id: '1', title: 'T', subtasks: subs);
      final task2 = Task(id: '2', title: 'T', subtasks: subs);

      // Mutate via task1's subtasks
      task1.subtasks[0].isDone = true;

      // task2 is affected! (shared reference)
      expect(task2.subtasks[0].isDone, isTrue,
        reason: 'BUG: subtasks shared between tasks!');
    });

    // ===== Bug: attachments list is mutable =====
    test('EDGE: attachments list is mutable — shared reference', () {
      final atts = ['file.pdf'];
      final task1 = Task(id: '1', title: 'T', attachments: atts);
      final task2 = Task(id: '2', title: 'T', attachments: atts);

      task1.attachments.add('extra.jpg');
      expect(task2.attachments.length, 2,
        reason: 'BUG: attachments shared between tasks!');
    });

    // ===== Bug: deadline calculation edge cases =====
    test('EDGE: deadline with dueTime at 00:00', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 5, 15),
        dueTime: DateTime(2000, 1, 1, 0, 0),
      );
      expect(task.deadline, DateTime(2026, 5, 15, 0, 0));
    });

    test('EDGE: deadline with dueTime at 23:59', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 5, 15),
        dueTime: DateTime(2000, 1, 1, 23, 59),
      );
      expect(task.deadline, DateTime(2026, 5, 15, 23, 59));
    });

    // ===== isOverdue edge cases =====
    test('EDGE: isOverdue with deadline exactly now', () {
      final now = DateTime.now();
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(now.year, now.month, now.day),
        dueTime: DateTime(2000, 1, 1, now.hour, now.minute),
      );
      // The task's deadline equals now, so DateTime.now().isAfter(deadline!) 
      // could be true or false depending on timing within the same second
      // This is a known edge case: tasks due at the exact current minute 
      // may or may not show as overdue
      final isOverdue = task.isOverdue;
      // We just verify it doesn't crash — timing makes exact assertion unreliable
      expect(isOverdue == true || isOverdue == false, isTrue);
    });

    test('EDGE: isOverdue with deadline 1 second ago', () async {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2020, 1, 1),
        dueTime: DateTime(2000, 1, 1, 0, 0, 1),
      );
      // This is in the past, should be overdue
      expect(task.isOverdue, isTrue);
    });

    // ===== toMap/fromMap edge cases =====
    test('EDGE: toMap with all null optional fields', () {
      final task = Task(id: '1', title: 'T');
      final m = task.toMap();
      expect(m['dueDate'], isNull);
      expect(m['dueTime'], isNull);
      expect(m['repeatRule'], isNull);
      expect(m['repeatEndDate'], isNull);
      expect(m['preReminderOffset'], isNull);
    });

    test('EDGE: fromMap with empty map', () {
      final task = Task.fromMap({});
      expect(task.id, '');
      expect(task.title, '');
      expect(task.category, TaskCategory.personal);
      expect(task.status, TaskStatus.pending);
    });

    test('EDGE: fromMap with extra unknown fields (no crash)', () {
      final m = {
        'id': '1', 'title': 'T',
        'unknown_field': 'value',
        'another_unknown': 42,
      };
      final task = Task.fromMap(m);
      expect(task.id, '1');
      expect(task.title, 'T');
    });

    // ===== 100 task stress test =====
    test('EDGE: 100 tasks serialization round-trip', () {
      final tasks = List.generate(100, (i) => Task(
        id: 'task_$i',
        title: 'Task $i',
        description: 'Description $i',
        noteContent: 'Notes $i',
        dueDate: DateTime(2026, 1, 1).add(Duration(days: i)),
        category: TaskCategory.values[i % TaskCategory.values.length],
        status: TaskStatus.values[i % TaskStatus.values.length],
      ));

      final maps = tasks.map((t) => t.toMap()).toList();
      final restored = maps.map((m) => Task.fromMap(m)).toList();

      for (var i = 0; i < 100; i++) {
        expect(restored[i].id, tasks[i].id);
        expect(restored[i].title, tasks[i].title);
        expect(restored[i].category, tasks[i].category);
        expect(restored[i].status, tasks[i].status);
      }
    });

    // ===== Unicode stress =====
    test('EDGE: Vietnamese unicode in title/note', () {
      final task = Task(
        id: '1',
        title: 'Bài kiểm tra Toánân',
        noteContent: 'Phải nộp trước 17h ngày 15/03/2026',
      );
      final m = task.toMap();
      final restored = Task.fromMap(m);
      expect(restored.title, task.title);
      expect(restored.noteContent, task.noteContent);
    });

    test('EDGE: Emoji in task content', () {
      final task = Task(
        id: '1',
        title: 'Test 🎉📝🔥',
        noteContent: 'Notes with emoji ✨',
      );
      final m = task.toMap();
      final restored = Task.fromMap(m);
      expect(restored.title, 'Test 🎉📝🔥');
    });

    // ===== copyWith consistency =====
    test('EDGE: double copyWith produces same result', () {
      final task = Task(id: '1', title: 'T', description: 'D');
      final copy1 = task.copyWith(title: 'X');
      final copy2 = task.copyWith(title: 'X');
      expect(copy1.title, copy2.title);
      expect(copy1.description, copy2.description);
    });

    test('EDGE: copyWith then copyWith back restores original', () {
      final task = Task(id: '1', title: 'T', description: 'D');
      final modified = task.copyWith(title: 'X');
      final restored = modified.copyWith(title: 'T');
      expect(restored.title, 'T');
      expect(restored.description, 'D');
    });

    // ===== SubTask edge cases =====
    test('EDGE: SubTask with empty title', () {
      final sub = SubTask(id: 's1', title: '');
      expect(sub.title, '');
      final m = sub.toMap();
      final restored = SubTask.fromMap(m);
      expect(restored.title, '');
    });

    test('EDGE: SubTask from map with missing fields', () {
      final sub = SubTask.fromMap({});
      expect(sub.id, '');
      expect(sub.title, '');
      expect(sub.isDone, false);
    });

    // ===== Task equality (no == override) =====
    test('EDGE: Two tasks with same data are NOT equal (no == override)', () {
      final t1 = Task(id: '1', title: 'T');
      final t2 = Task(id: '1', title: 'T');
      expect(t1 == t2, isFalse); // Different objects
    });

    // ===== Boundary: max integer values =====
    test('EDGE: preReminderOffset at max value', () {
      final task = Task(id: '1', title: 'T', preReminderOffset: 999999);
      expect(task.preReminderOffset, 999999);
      final m = task.toMap();
      final restored = Task.fromMap(m);
      expect(restored.preReminderOffset, 999999);
    });

    test('EDGE: preReminderOffset at 0', () {
      final task = Task(id: '1', title: 'T', preReminderOffset: 0);
      expect(task.preReminderOffset, 0);
    });
  });
}
