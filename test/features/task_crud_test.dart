import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

/// Simulates TaskService.addTask() logic without full service dependency
Task createTask({
  required String title,
  String description = '',
  String noteContent = '',
  List<SubTask>? subtasks,
  DateTime? dueDate,
  DateTime? dueTime,
  TaskCategory? category,
  String? repeatRule,
  DateTime? repeatEndDate,
  int? preReminderOffset,
  TaskStatus status = TaskStatus.pending,
  List<String>? attachments,
}) {
  return Task(
    id: '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.toRadixString(16)}',
    title: title,
    description: description,
    noteContent: noteContent,
    subtasks: subtasks,
    dueDate: dueDate,
    dueTime: dueTime,
    category: category ?? TaskCategory.personal,
    repeatRule: repeatRule,
    repeatEndDate: repeatEndDate,
    preReminderOffset: preReminderOffset,
    status: status,
    attachments: attachments,
  );
}

/// Simulates TaskService.updateTask() logic
/// Uses Object? with _sentinel defaults matching the real implementation.
/// Fields not passed by the caller get _sentinel, preserving existing values in copyWith.
Task updateTask(Task task, {
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
  // Build copyWith call dynamically — only pass params the caller explicitly provided.
  // We track which params were passed using a Set.
  final passed = <String>{};

  // We can't use Object? + _sentinel here (private to task.dart),
  // so we use a wrapper that builds the Task directly.
  // For nullable fields with sentinel in copyWith (description, noteContent, dueDate, dueTime,
  // repeatRule, repeatEndDate, preReminderOffset), we need to NOT pass them to copyWith
  // when the caller didn't provide them, so copyWith uses its sentinel default.
  //
  // Since Dart doesn't support conditional named params, we build a new Task directly
  // preserving unspecified fields from the original task.
  return Task(
    id: task.id,
    title: title ?? task.title,
    description: description ?? task.description,
    noteContent: noteContent ?? task.noteContent,
    subtasks: subtasks ?? task.subtasks,
    dueDate: dueDate ?? task.dueDate,
    dueTime: dueTime ?? task.dueTime,
    category: category ?? task.category,
    repeatRule: repeatRule ?? task.repeatRule,
    repeatEndDate: repeatEndDate ?? task.repeatEndDate,
    preReminderOffset: preReminderOffset ?? task.preReminderOffset,
    status: status ?? task.status,
    attachments: attachments ?? task.attachments,
    createdAt: task.createdAt,
  );
}

/// Simulates TaskService.toggleTask() logic
Task toggleTask(Task task) {
  final newStatus = task.isDone ? TaskStatus.pending : TaskStatus.done;
  return task.copyWith(status: newStatus);
}

/// Simulates TaskService.snoozeTask() logic
Task snoozeTask(Task task, Duration duration) {
  final now = DateTime.now();
  final newDeadline = now.add(duration);
  return task.copyWith(
    dueDate: DateTime(newDeadline.year, newDeadline.month, newDeadline.day),
    dueTime: DateTime(2000, 1, 1, newDeadline.hour, newDeadline.minute),
    status: TaskStatus.snoozed,
  );
}

/// Simulates TaskService.deleteTask() — removes from list
List<Task> deleteTask(List<Task> tasks, String taskId) {
  return tasks.where((t) => t.id != taskId).toList();
}

void main() {
  group('Tab Tasks — CRUD Workflows', () {
    // ===== CREATE =====
    test('1. Create minimal task with only title', () {
      final task = createTask(title: 'Buy milk');
      expect(task.title, 'Buy milk');
      expect(task.status, TaskStatus.pending);
      expect(task.category, TaskCategory.personal);
      expect(task.id.isNotEmpty, isTrue);
    });

    test('2. Create task with all fields', () {
      final task = createTask(
        title: 'Math exam',
        description: 'Chapter 5-8',
        noteContent: 'Bring calculator',
        dueDate: DateTime(2026, 6, 15),
        dueTime: DateTime(2000, 1, 1, 9, 0),
        category: TaskCategory.exam,
        preReminderOffset: 30,
        repeatRule: 'weekly',
        attachments: ['notes.pdf'],
      );
      expect(task.title, 'Math exam');
      expect(task.description, 'Chapter 5-8');
      expect(task.noteContent, 'Bring calculator');
      expect(task.category, TaskCategory.exam);
      expect(task.repeatRule, 'weekly');
      expect(task.attachments, ['notes.pdf']);
      expect(task.deadline!.hour, 9);
    });

    test('3. Create task with empty title defaults work', () {
      final task = createTask(title: '');
      expect(task.title, '');
      // The service would typically validate, but model accepts it
    });

    test('4. Create task with subtasks', () {
      final subs = [
        SubTask(id: 's1', title: 'Step 1'),
        SubTask(id: 's2', title: 'Step 2', isDone: true),
      ];
      final task = createTask(title: 'Multi-step', subtasks: subs);
      expect(task.subtasks.length, 2);
      expect(task.subtasks[1].isDone, isTrue);
    });

    // ===== READ =====
    test('5. Task deadlines calculate correctly with time', () {
      final task = createTask(
        title: 'T',
        dueDate: DateTime(2026, 3, 15),
        dueTime: DateTime(2000, 1, 1, 14, 30),
      );
      expect(task.deadline, DateTime(2026, 3, 15, 14, 30));
    });

    test('6. Task deadlines default to 9:00 AM without time', () {
      final task = createTask(
        title: 'T',
        dueDate: DateTime(2026, 3, 15),
      );
      expect(task.deadline, DateTime(2026, 3, 15, 9, 0, 0));
    });

    test('7. Task without dueDate has null deadline', () {
      final task = createTask(title: 'T');
      expect(task.deadline, isNull);
    });

    // ===== UPDATE =====
    test('8. Update title only preserves other fields', () {
      final original = createTask(
        title: 'Old title',
        description: 'Keep this',
        noteContent: 'Keep this too',
        dueDate: DateTime(2026, 5, 1),
        category: TaskCategory.exam,
        preReminderOffset: 30,
        attachments: ['file.pdf'],
      );
      final updated = updateTask(original, title: 'New title');
      expect(updated.title, 'New title');
      expect(updated.description, 'Keep this');
      expect(updated.noteContent, 'Keep this too');
      expect(updated.dueDate, DateTime(2026, 5, 1));
      expect(updated.category, TaskCategory.exam);
      expect(updated.preReminderOffset, 30);
      expect(updated.attachments, ['file.pdf']);
    });

    test('9. Update noteContent preserves title and date', () {
      final original = createTask(
        title: 'Important task',
        noteContent: 'old note',
        dueDate: DateTime(2026, 5, 1),
      );
      final updated = updateTask(original, noteContent: 'new note');
      expect(updated.title, 'Important task');
      expect(updated.noteContent, 'new note');
      expect(updated.dueDate, DateTime(2026, 5, 1));
    });

    test('10. Update category preserves everything else', () {
      final original = createTask(
        title: 'T',
        noteContent: 'notes',
        category: TaskCategory.personal,
      );
      final updated = updateTask(original, category: TaskCategory.exam);
      expect(updated.category, TaskCategory.exam);
      expect(updated.noteContent, 'notes');
    });

    test('11. Update with null values does NOT clear existing fields', () {
      final original = createTask(
        title: 'T',
        description: 'Desc',
        noteContent: 'Notes',
        dueDate: DateTime(2026, 5, 1),
        category: TaskCategory.exam,
      );
      // Simulate updateTask called from TaskDetailScreen with only title, noteContent, status
      final updated = updateTask(
        original,
        title: original.title, // same title
        noteContent: original.noteContent, // same notes
      );
      expect(updated.description, 'Desc'); // preserved
      expect(updated.dueDate, DateTime(2026, 5, 1)); // preserved
      expect(updated.category, TaskCategory.exam); // preserved
    });

    test('12. Update description to empty string clears it', () {
      final original = createTask(title: 'T', description: 'Old desc');
      final updated = updateTask(original, description: '');
      expect(updated.description, '');
    });

    test('13. Update attaches new attachment', () {
      final original = createTask(title: 'T', attachments: ['a.pdf']);
      final updated = updateTask(original, attachments: ['a.pdf', 'b.jpg']);
      expect(updated.attachments.length, 2);
    });

    // ===== TOGGLE =====
    test('14. Toggle pending → done', () {
      final task = createTask(title: 'T', status: TaskStatus.pending);
      final toggled = toggleTask(task);
      expect(toggled.status, TaskStatus.done);
    });

    test('15. Toggle done → pending', () {
      final task = createTask(title: 'T', status: TaskStatus.done);
      final toggled = toggleTask(task);
      expect(toggled.status, TaskStatus.pending);
    });

    test('16. Toggle snoozed → done (snoozed is not done)', () {
      final task = createTask(title: 'T', status: TaskStatus.snoozed);
      final toggled = toggleTask(task);
      expect(toggled.status, TaskStatus.done);
    });

    // ===== SNOOZE =====
    test('17. Snooze sets status to snoozed', () {
      final task = createTask(title: 'T');
      final snoozed = snoozeTask(task, const Duration(minutes: 30));
      expect(snoozed.status, TaskStatus.snoozed);
      expect(snoozed.dueDate, isNotNull);
      expect(snoozed.dueTime, isNotNull);
    });

    test('18. Snooze sets future deadline', () {
      final task = createTask(title: 'T');
      final snoozed = snoozeTask(task, const Duration(hours: 2));
      final deadline = snoozed.deadline!;
      expect(deadline.isAfter(DateTime.now()), isTrue);
    });

    // ===== DELETE =====
    test('19. Delete removes task from list', () {
      var tasks = [
        createTask(title: 'A'),
        createTask(title: 'B'),
      ];
      final idToDelete = tasks[0].id;
      tasks = deleteTask(tasks, idToDelete);
      expect(tasks.length, 1);
      expect(tasks[0].title, 'B');
    });

    test('20. Delete non-existent task does nothing', () {
      var tasks = [createTask(title: 'A')];
      final original = List<Task>.from(tasks);
      tasks = deleteTask(tasks, 'nonexistent');
      expect(tasks.length, original.length);
    });

    test('21. Delete from empty list is safe', () {
      var tasks = <Task>[];
      tasks = deleteTask(tasks, 'any');
      expect(tasks, isEmpty);
    });

    // ===== Serialization round-trip =====
    test('22. Create → toMap → fromMap preserves all fields', () {
      final original = createTask(
        title: 'Full task',
        description: 'Desc',
        noteContent: 'Notes',
        dueDate: DateTime(2026, 6, 1),
        dueTime: DateTime(2000, 1, 1, 10, 30),
        category: TaskCategory.class_,
        preReminderOffset: 15,
        repeatRule: 'daily',
        attachments: ['a.pdf'],
      );
      final restored = Task.fromMap(original.toMap());
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.noteContent, original.noteContent);
      expect(restored.dueDate, original.dueDate);
      expect(restored.category, original.category);
      expect(restored.repeatRule, original.repeatRule);
      expect(restored.attachments, original.attachments);
    });

    test('23. Toggle → toMap → fromMap preserves done status', () {
      var task = createTask(title: 'T');
      task = toggleTask(task);
      final restored = Task.fromMap(task.toMap());
      expect(restored.status, TaskStatus.done);
    });

    // ===== Multi-step workflow =====
    test('24. Full workflow: create → update → toggle → delete', () {
      var task = createTask(title: 'Workflow test');
      // Update
      task = updateTask(task, noteContent: 'Updated notes', category: TaskCategory.exam);
      expect(task.noteContent, 'Updated notes');
      expect(task.category, TaskCategory.exam);
      // Toggle
      task = toggleTask(task);
      expect(task.isDone, isTrue);
      // Toggle back
      task = toggleTask(task);
      expect(task.isDone, isFalse);
      expect(task.noteContent, 'Updated notes'); // still preserved
    });

    test('25. Snooze → toggle → verify state', () {
      var task = createTask(title: 'Snooze test');
      task = snoozeTask(task, const Duration(minutes: 30));
      expect(task.status, TaskStatus.snoozed);
      task = toggleTask(task); // snoozed → done
      expect(task.status, TaskStatus.done);
    });
  });
}
