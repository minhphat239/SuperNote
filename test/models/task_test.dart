import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

void main() {
  group('Task Model', () {
    // ===== Constructor & Defaults =====
    test('1. Default constructor creates task with required fields', () {
      final task = Task(id: '1', title: 'Test');
      expect(task.id, '1');
      expect(task.title, 'Test');
      expect(task.description, '');
      expect(task.noteContent, '');
      expect(task.status, TaskStatus.pending);
      expect(task.category, TaskCategory.personal);
      expect(task.subtasks, isEmpty);
      expect(task.attachments, isEmpty);
      expect(task.dueDate, isNull);
      expect(task.dueTime, isNull);
      expect(task.repeatRule, isNull);
      expect(task.repeatEndDate, isNull);
      expect(task.preReminderOffset, isNull);
    });

    test('2. Constructor sets createdAt and updatedAt to now when null', () {
      final before = DateTime.now();
      final task = Task(id: '1', title: 'T');
      final after = DateTime.now();
      expect(task.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(task.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(task.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });

    test('3. Constructor accepts explicit createdAt and updatedAt', () {
      final date = DateTime(2025, 1, 15, 10, 30);
      final task = Task(id: '1', title: 'T', createdAt: date, updatedAt: date);
      expect(task.createdAt, date);
      expect(task.updatedAt, date);
    });

    test('4. Constructor accepts subtasks and attachments', () {
      final subs = [SubTask(id: 's1', title: 'Sub1')];
      final atts = ['file.pdf'];
      final task = Task(id: '1', title: 'T', subtasks: subs, attachments: atts);
      expect(task.subtasks, hasLength(1));
      expect(task.attachments, ['file.pdf']);
    });

    // ===== Getters =====
    test('5. hasNote returns true when noteContent is non-empty', () {
      final task = Task(id: '1', title: 'T', noteContent: 'Some note');
      expect(task.hasNote, isTrue);
    });

    test('6. hasNote returns false when noteContent is empty or whitespace', () {
      expect(Task(id: '1', title: 'T', noteContent: '').hasNote, isFalse);
      expect(Task(id: '1', title: 'T', noteContent: '   ').hasNote, isFalse);
    });

    test('7. hasAttachments returns true when attachments list is non-empty', () {
      final task = Task(id: '1', title: 'T', attachments: ['a.txt']);
      expect(task.hasAttachments, isTrue);
    });

    test('8. hasAttachments returns false when empty', () {
      expect(Task(id: '1', title: 'T').hasAttachments, isFalse);
    });

    test('9. isDone returns true when status is done', () {
      final task = Task(id: '1', title: 'T', status: TaskStatus.done);
      expect(task.isDone, isTrue);
    });

    test('10. isDone returns false when status is pending or snoozed', () {
      expect(Task(id: '1', title: 'T', status: TaskStatus.pending).isDone, isFalse);
      expect(Task(id: '1', title: 'T', status: TaskStatus.snoozed).isDone, isFalse);
    });

    // ===== Deadline getter =====
    test('11. deadline returns null when dueDate is null', () {
      final task = Task(id: '1', title: 'T');
      expect(task.deadline, isNull);
    });

    test('12. deadline returns 9:00 AM default when dueDate set but no dueTime', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15));
      final dl = task.deadline!;
      expect(dl.year, 2026);
      expect(dl.month, 3);
      expect(dl.day, 15);
      expect(dl.hour, 9);
      expect(dl.minute, 0);
    });

    test('13. deadline combines dueDate and dueTime when both set', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 3, 15),
        dueTime: DateTime(2000, 1, 1, 14, 30),
      );
      final dl = task.deadline!;
      expect(dl.hour, 14);
      expect(dl.minute, 30);
    });

    // ===== isOverdue getter =====
    test('14. isOverdue returns false when deadline is null', () {
      final task = Task(id: '1', title: 'T');
      expect(task.isOverdue, isFalse);
    });

    test('15. isOverdue returns false when task is done', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2020, 1, 1),
        status: TaskStatus.done,
      );
      expect(task.isOverdue, isFalse);
    });

    test('16. isOverdue returns true when deadline is in the past and not done', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2020, 1, 1),
        dueTime: DateTime(2000, 1, 1, 8, 0),
        status: TaskStatus.pending,
      );
      expect(task.isOverdue, isTrue);
    });

    // ===== toMap / fromMap serialization =====
    test('17. toMap produces correct JSON map', () {
      final task = Task(
        id: '1', title: 'Test',
        description: 'Desc', noteContent: 'Note',
        category: TaskCategory.exam,
        status: TaskStatus.pending,
        dueDate: DateTime(2026, 6, 1),
        dueTime: DateTime(2000, 1, 1, 10, 0),
        preReminderOffset: 30,
        repeatRule: 'daily',
        attachments: ['a.pdf'],
      );
      final m = task.toMap();
      expect(m['id'], '1');
      expect(m['title'], 'Test');
      expect(m['description'], 'Desc');
      expect(m['noteContent'], 'Note');
      expect(m['category'], 'exam');
      expect(m['status'], 'pending');
      expect(m['dueDate'], isNotNull);
      expect(m['dueTime'], isNotNull);
      expect(m['preReminderOffset'], 30);
      expect(m['repeatRule'], 'daily');
      expect(m['attachments'], ['a.pdf']);
    });

    test('18. fromMap recreates task from toMap output', () {
      final original = Task(
        id: '42', title: 'Hello',
        description: 'D', noteContent: 'N',
        category: TaskCategory.class_,
        status: TaskStatus.snoozed,
        dueDate: DateTime(2026, 8, 10),
        dueTime: DateTime(2000, 1, 1, 15, 45),
        preReminderOffset: 15,
        repeatRule: 'weekly',
        repeatEndDate: DateTime(2026, 12, 31),
        attachments: ['b.pdf', 'c.jpg'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        subtasks: [SubTask(id: 's1', title: 'Sub', isDone: true)],
      );
      final m = original.toMap();
      final restored = Task.fromMap(m);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.noteContent, original.noteContent);
      expect(restored.category, original.category);
      expect(restored.status, original.status);
      expect(restored.dueDate, original.dueDate);
      expect(restored.dueTime, original.dueTime);
      expect(restored.preReminderOffset, original.preReminderOffset);
      expect(restored.repeatRule, original.repeatRule);
      expect(restored.repeatEndDate, original.repeatEndDate);
      expect(restored.attachments, original.attachments);
      expect(restored.subtasks.length, 1);
      expect(restored.subtasks[0].title, 'Sub');
    });

    test('19. fromMap handles missing/null fields gracefully', () {
      final m = <String, dynamic>{'id': '1', 'title': 'X'};
      final task = Task.fromMap(m);
      expect(task.description, '');
      expect(task.noteContent, '');
      expect(task.category, TaskCategory.personal);
      expect(task.status, TaskStatus.pending);
      expect(task.dueDate, isNull);
      expect(task.dueTime, isNull);
      expect(task.subtasks, isEmpty);
      expect(task.attachments, isEmpty);
    });

    test('20. fromMap handles invalid category/status with fallback', () {
      final m = {
        'id': '1', 'title': 'T',
        'category': 'invalid_cat',
        'status': 'invalid_status',
      };
      final task = Task.fromMap(m);
      expect(task.category, TaskCategory.personal);
      expect(task.status, TaskStatus.pending);
    });
  });

  group('SubTask Model', () {
    test('SubTask toMap/fromMap round-trip', () {
      final sub = SubTask(id: 's1', title: 'Do laundry', isDone: true);
      final m = sub.toMap();
      final restored = SubTask.fromMap(m);
      expect(restored.id, 's1');
      expect(restored.title, 'Do laundry');
      expect(restored.isDone, isTrue);
    });

    test('SubTask defaults isDone to false', () {
      final sub = SubTask(id: 's2', title: 'X');
      expect(sub.isDone, isFalse);
    });
  });

  group('Task copyWith', () {
    test('copyWith preserves unmodified fields', () {
      final task = Task(
        id: '1', title: 'T', description: 'D', noteContent: 'N',
        category: TaskCategory.exam,
        dueDate: DateTime(2026, 5, 1),
        dueTime: DateTime(2000, 1, 1, 8, 0),
        status: TaskStatus.pending,
        preReminderOffset: 10,
        attachments: ['a.pdf'],
      );
      final copy = task.copyWith(title: 'New Title');
      expect(copy.title, 'New Title');
      expect(copy.description, 'D');
      expect(copy.noteContent, 'N');
      expect(copy.category, TaskCategory.exam);
      expect(copy.dueDate, DateTime(2026, 5, 1));
      expect(copy.status, TaskStatus.pending);
      expect(copy.attachments, ['a.pdf']);
    });

    test('copyWith changes status', () {
      final task = Task(id: '1', title: 'T');
      final done = task.copyWith(status: TaskStatus.done);
      expect(done.status, TaskStatus.done);
    });

    test('copyWith sets description to null (clear)', () {
      final task = Task(id: '1', title: 'T', description: 'Old');
      final copy = task.copyWith(description: null);
      // Sentinel pattern: null means "no change", keeps old value
      expect(copy.description, 'Old');
    });

    test('copyWith sets dueDate to null (clear)', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 1, 1));
      final copy = task.copyWith(dueDate: null);
      expect(copy.dueDate, isNull);
    });

    test('copyWith updates updatedAt', () {
      final old = DateTime(2020, 1, 1);
      final task = Task(id: '1', title: 'T', updatedAt: old);
      final copy = task.copyWith(title: 'X');
      expect(copy.updatedAt.isAfter(old), isTrue);
    });

    test('copyWith does not change id or createdAt', () {
      final task = Task(id: '1', title: 'T', createdAt: DateTime(2020, 1, 1));
      final copy = task.copyWith(title: 'Y');
      expect(copy.id, '1');
      expect(copy.createdAt, task.createdAt);
    });
  });

  group('TaskCategory', () {
    test('TaskCategory has correct labels', () {
      expect(TaskCategory.class_.label, 'Class');
      expect(TaskCategory.exam.label, 'Exam');
      expect(TaskCategory.assignment.label, 'Assignment');
      expect(TaskCategory.personal.label, 'Personal');
    });

    test('TaskCategory has correct colors', () {
      expect(TaskCategory.class_.color.value, 0xFF00F5FF);
      expect(TaskCategory.exam.color.value, 0xFFFF007F);
      expect(TaskCategory.assignment.color.value, 0xFFFF8C42);
      expect(TaskCategory.personal.color.value, 0xFF00FF66);
    });
  });
}
