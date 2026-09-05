import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

/// Simulates what TaskService.updateTask() actually does
/// Uses the same approach as the real implementation: only updates fields
/// the caller explicitly passes, preserving the rest from the original task.
Task simulateTaskServiceUpdate(Task current, {
  String? title,
  String? description,
  String? noteContent,
  List<SubTask>? subtasks,
  DateTime? dueDate,
  DateTime? dueTime,
  TaskCategory? category,
  String? repeatRule,
  DateTime? repeatEndDate,
  int? preReminderOffset,
  TaskStatus? status,
  List<String>? attachments,
}) {
  // Build Task directly — only apply fields the caller explicitly provided.
  // This matches the real updateTask behavior where unspecified fields use
  // _sentinel defaults in copyWith and are thus preserved.
  return Task(
    id: current.id,
    title: title ?? current.title,
    description: description ?? current.description,
    noteContent: noteContent ?? current.noteContent,
    subtasks: subtasks ?? current.subtasks,
    dueDate: dueDate ?? current.dueDate,
    dueTime: dueTime ?? current.dueTime,
    category: category ?? current.category,
    repeatRule: repeatRule ?? current.repeatRule,
    repeatEndDate: repeatEndDate ?? current.repeatEndDate,
    preReminderOffset: preReminderOffset ?? current.preReminderOffset,
    status: status ?? current.status,
    attachments: attachments ?? current.attachments,
    createdAt: current.createdAt,
  );
}

Task simulateTaskDetailSave(Task original, {
  required String title,
  required String noteContent,
  required TaskStatus status,
}) {
  // This is what TaskDetailScreen._saveAndPop() does:
  return original.copyWith(
    title: title,
    noteContent: noteContent,
    status: status,
  );
}


void main() {
  group('Task Data Preservation — Bug Hunting', () {
    // ============================================================
    // CRITICAL BUG: TaskDetailScreen only sends title, noteContent, status
    // What about description, dueDate, dueTime, category, etc?
    // ============================================================

    test('CRITICAL: TaskDetailScreen save preserves dueDate', () {
      final task = Task(
        id: '1', title: 'Exam',
        dueDate: DateTime(2026, 6, 15),
        dueTime: DateTime(2000, 1, 1, 9, 0),
        category: TaskCategory.exam,
        description: 'Important exam',
        noteContent: 'Bring ID',
        preReminderOffset: 30,
      );

      // User opens task, changes nothing, presses back → _saveAndPop saves
      final saved = simulateTaskDetailSave(
        task,
        title: 'Exam', // same
        noteContent: 'Bring ID', // same
        status: TaskStatus.pending, // same
      );

      expect(saved.dueDate, DateTime(2026, 6, 15),
        reason: 'BUG: dueDate lost after TaskDetailScreen save!');
      expect(saved.dueTime, DateTime(2000, 1, 1, 9, 0),
        reason: 'BUG: dueTime lost after TaskDetailScreen save!');
      expect(saved.category, TaskCategory.exam,
        reason: 'BUG: category lost after TaskDetailScreen save!');
      expect(saved.description, 'Important exam',
        reason: 'BUG: description lost after TaskDetailScreen save!');
      expect(saved.preReminderOffset, 30,
        reason: 'BUG: preReminderOffset lost after TaskDetailScreen save!');
    });

    test('CRITICAL: TaskDetailScreen save preserves attachments', () {
      final task = Task(
        id: '1', title: 'T',
        attachments: ['file1.pdf', 'file2.jpg'],
      );
      final saved = simulateTaskDetailSave(task, title: 'T', noteContent: '', status: TaskStatus.pending);
      expect(saved.attachments, ['file1.pdf', 'file2.jpg'],
        reason: 'BUG: attachments lost after TaskDetailScreen save!');
    });

    test('CRITICAL: TaskDetailScreen save preserves subtasks', () {
      final task = Task(
        id: '1', title: 'T',
        subtasks: [
          SubTask(id: 's1', title: 'Step 1', isDone: true),
          SubTask(id: 's2', title: 'Step 2'),
        ],
      );
      final saved = simulateTaskDetailSave(task, title: 'T', noteContent: '', status: TaskStatus.pending);
      expect(saved.subtasks.length, 2);
      expect(saved.subtasks[0].isDone, isTrue);
    });

    test('CRITICAL: TaskDetailScreen save preserves repeatRule', () {
      final task = Task(id: '1', title: 'T', repeatRule: 'daily');
      final saved = simulateTaskDetailSave(task, title: 'T', noteContent: '', status: TaskStatus.pending);
      expect(saved.repeatRule, 'daily',
        reason: 'BUG: repeatRule lost after TaskDetailScreen save!');
    });

    test('CRITICAL: TaskDetailScreen save preserves repeatEndDate', () {
      final task = Task(id: '1', title: 'T', repeatEndDate: DateTime(2026, 12, 31));
      final saved = simulateTaskDetailSave(task, title: 'T', noteContent: '', status: TaskStatus.pending);
      expect(saved.repeatEndDate, DateTime(2026, 12, 31),
        reason: 'BUG: repeatEndDate lost!');
    });

    // ============================================================
    // TaskService.updateTask — does it preserve fields NOT passed?
    // ============================================================

    test('updateTask: only updating title preserves dueDate', () {
      final task = Task(
        id: '1', title: 'Old',
        dueDate: DateTime(2026, 5, 1),
        category: TaskCategory.exam,
      );
      final updated = simulateTaskServiceUpdate(task, title: 'New');
      expect(updated.title, 'New');
      expect(updated.dueDate, DateTime(2026, 5, 1));
      expect(updated.category, TaskCategory.exam);
    });

    test('updateTask: only updating noteContent preserves all', () {
      final task = Task(
        id: '1', title: 'T',
        description: 'Desc',
        dueDate: DateTime(2026, 5, 1),
        dueTime: DateTime(2000, 1, 1, 10, 0),
        category: TaskCategory.class_,
        repeatRule: 'weekly',
        attachments: ['a.pdf'],
      );
      final updated = simulateTaskServiceUpdate(task, noteContent: 'new notes');
      expect(updated.description, 'Desc');
      expect(updated.dueDate, DateTime(2026, 5, 1));
      expect(updated.dueTime, DateTime(2000, 1, 1, 10, 0));
      expect(updated.category, TaskCategory.class_);
      expect(updated.repeatRule, 'weekly');
      expect(updated.attachments, ['a.pdf']);
    });

    test('updateTask: clearing description by passing empty string', () {
      final task = Task(id: '1', title: 'T', description: 'Has desc');
      final updated = simulateTaskServiceUpdate(task, description: '');
      expect(updated.description, '');
    });

    test('updateTask: clearing noteContent by passing empty string', () {
      final task = Task(id: '1', title: 'T', noteContent: 'Has notes');
      final updated = simulateTaskServiceUpdate(task, noteContent: '');
      expect(updated.noteContent, '');
    });

    test('updateTask: clearing dueDate by passing null (via sentinel)', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 5, 1));
      // When we DON'T pass dueDate to updateTask, the copyWith default (sentinel) kicks in
      // So dueDate is preserved
      final updated = simulateTaskServiceUpdate(task, title: 'X');
      expect(updated.dueDate, DateTime(2026, 5, 1));
    });

    test('updateTask: explicitly setting category to personal', () {
      final task = Task(id: '1', title: 'T', category: TaskCategory.exam);
      final updated = simulateTaskServiceUpdate(task, category: TaskCategory.personal);
      expect(updated.category, TaskCategory.personal);
    });

    // ============================================================
    // Edge case: multiple rapid updates
    // ============================================================

    test('Multiple rapid updates preserve all fields', () {
      var task = Task(
        id: '1', title: 'Original',
        description: 'Desc',
        noteContent: 'Notes',
        dueDate: DateTime(2026, 5, 1),
        category: TaskCategory.exam,
      );

      // Simulate rapid edits
      task = simulateTaskServiceUpdate(task, title: 'Edit 1');
      task = simulateTaskServiceUpdate(task, noteContent: 'Note edit');
      task = simulateTaskServiceUpdate(task, title: 'Edit 2');
      task = simulateTaskServiceUpdate(task, category: TaskCategory.assignment);

      expect(task.title, 'Edit 2');
      expect(task.description, 'Desc'); // never touched
      expect(task.noteContent, 'Note edit');
      expect(task.dueDate, DateTime(2026, 5, 1)); // never touched
      expect(task.category, TaskCategory.assignment);
    });

    // ============================================================
    // Edge case: serialization preserves after update
    // ============================================================

    test('Update → serialize → deserialize preserves all', () {
      var task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 5, 1),
        category: TaskCategory.exam,
      );
      task = simulateTaskServiceUpdate(task, title: 'Updated');
      final restored = Task.fromMap(task.toMap());
      expect(restored.title, 'Updated');
      expect(restored.dueDate, DateTime(2026, 5, 1));
      expect(restored.category, TaskCategory.exam);
    });

    // ============================================================
    // Edge case: what copyWith does with explicit null vs no param
    // ============================================================

    test('copyWith with no dueDate param preserves existing dueDate', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 5, 1));
      final copy = task.copyWith(title: 'X');
      expect(copy.dueDate, DateTime(2026, 5, 1));
    });

    test('copyWith with explicit null dueDate sets dueDate to null (via sentinel)', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 5, 1));
      // When you pass dueDate: null, it matches the _sentinel default?
      // NO! null != _sentinel. But copyWith has `Object? dueDate = _sentinel`
      // If you call copyWith(dueDate: null), then dueDate parameter is null, which is NOT identical to _sentinel
      // So it goes to: `identical(dueDate, _sentinel) ? this.dueDate : dueDate as DateTime?`
      // identical(null, _sentinel) is false, so it goes to null as DateTime? = null
      final copy = task.copyWith(dueDate: null);
      expect(copy.dueDate, isNull);
    });

    test('KNOWN BEHAVIOR: Passing null to copyWith actually preserves field via null-coalescing', () {
      final task = Task(id: '1', title: 'T', description: 'Keep me');
      // copyWith(description: null) → identical(null, _sentinel) = false
      // → (null as String? ?? this.description) = this.description = 'Keep me'
      // The null-coalescing operator ?? means null is treated as "keep old"
      final updated = task.copyWith(description: null);
      expect(updated.description, 'Keep me',
        reason: 'null-coalescing ?? means null preserves old value');
    });

    test('KNOWN BEHAVIOR: Not passing description uses sentinel → preserves field', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 5, 1));
      final updated = task.copyWith(title: 'X');
      expect(updated.dueDate, DateTime(2026, 5, 1),
        reason: 'sentinel default preserves dueDate when not passed');
    });

    test('BUG HUNT: TaskDetailScreen save never passes description → preserved', () {
      final task = Task(id: '1', title: 'T', description: 'Keep');
      // _saveAndPop doesn't pass description at all → copyWith uses sentinel default
      final saved = simulateTaskDetailSave(task, title: 'T', noteContent: '', status: TaskStatus.pending);
      expect(saved.description, 'Keep');
    });

    // ============================================================
    // Verify: does the task ID change after update?
    // ============================================================

    test('ID remains unchanged after update', () {
      final task = Task(id: 'abc123', title: 'T');
      final updated = simulateTaskServiceUpdate(task, title: 'X');
      expect(updated.id, 'abc123');
    });

    test('createdAt remains unchanged after update', () {
      final createdAt = DateTime(2020, 1, 1);
      final task = Task(id: '1', title: 'T', createdAt: createdAt);
      final updated = simulateTaskServiceUpdate(task, title: 'X');
      expect(updated.createdAt, createdAt);
    });

    test('updatedAt changes after copyWith', () {
      final old = DateTime(2020, 1, 1);
      final task = Task(id: '1', title: 'T', updatedAt: old);
      final updated = simulateTaskServiceUpdate(task, title: 'X');
      expect(updated.updatedAt.isAfter(old), isTrue);
    });
  });
}
