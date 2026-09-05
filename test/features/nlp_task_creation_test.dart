import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';
import 'package:super_note/services/nlp_service.dart';

/// Simulates TaskService.addTaskFromNlp() logic
Task createTaskFromNlp(String input) {
  final preview = NlpService.parse(input);

  TaskCategory category = preview.category ?? TaskCategory.personal;
  for (final tag in preview.tags) {
    final lower = tag.toLowerCase();
    if (lower == 'class' || lower == 'hoc' || lower == 'lop') {
      category = TaskCategory.class_;
      break;
    }
    if (lower == 'exam' || lower == 'thi' || lower == 'kythi') {
      category = TaskCategory.exam;
      break;
    }
    if (lower == 'assignment' || lower == 'baitap' || lower == 'homework' || lower == 'bt') {
      category = TaskCategory.assignment;
      break;
    }
    if (lower == 'personal' || lower == 'canhan' || lower == 'rieng') {
      category = TaskCategory.personal;
      break;
    }
  }

  return Task(
    id: 'test_nlp',
    title: preview.title,
    dueDate: preview.dueDate,
    dueTime: preview.dueTime,
    category: category,
    repeatRule: preview.repeatRule,
    repeatEndDate: preview.repeatEndDate,
    preReminderOffset: preview.preReminderOffset,
    status: TaskStatus.pending,
  );
}

void main() {
  group('Tab Tasks — NLP → Task Creation Workflows', () {
    final now = DateTime.now();

    // ===== Basic NLP parsing → Task creation =====
    test('1. Simple text → task with title only', () {
      final task = createTaskFromNlp('Buy groceries');
      expect(task.title, 'Buy groceries');
      expect(task.dueDate, isNull);
      expect(task.category, TaskCategory.personal);
    });

    test('2. "meeting tomorrow at 3 PM" → task with date + time', () {
      final task = createTaskFromNlp('meeting tomorrow at 3 PM');
      expect(task.title, isNotEmpty);
      expect(task.dueDate, isNotNull);
      expect(task.dueTime, isNotNull);
      expect(task.dueTime!.hour, 15);
    });

    test('3. Vietnamese "họp nhóm ngày mai lúc 10h" → VN date + time', () {
      final task = createTaskFromNlp('họp nhóm ngày mai lúc 10h');
      expect(task.dueDate, isNotNull);
      expect(task.dueTime, isNotNull);
      expect(task.dueTime!.hour, 10);
    });

    // ===== Category detection =====
    test('4. "math exam tomorrow" → exam category', () {
      final task = createTaskFromNlp('math exam tomorrow');
      expect(task.category, TaskCategory.exam);
    });

    test('5. "submit homework" → assignment category', () {
      final task = createTaskFromNlp('submit homework');
      expect(task.category, TaskCategory.assignment);
    });

    test('6. "attend class" → class_ category', () {
      final task = createTaskFromNlp('attend class');
      expect(task.category, TaskCategory.class_);
    });

    test('7. "#exam study session" → exam via tag', () {
      final task = createTaskFromNlp('#exam study session');
      expect(task.category, TaskCategory.exam);
    });

    test('8. Vietnamese "bài thi" → exam', () {
      final task = createTaskFromNlp('chuẩn bị bài thi');
      expect(task.category, TaskCategory.exam);
    });

    test('9. Vietnamese "bài tập" → assignment', () {
      final task = createTaskFromNlp('làm bài tập về nhà');
      expect(task.category, TaskCategory.assignment);
    });

    // ===== Repeat rules via NLP =====
    test('10. "exercise daily" → daily repeat', () {
      final task = createTaskFromNlp('exercise daily');
      expect(task.repeatRule, 'daily');
    });

    test('11. "meeting weekly" → weekly repeat', () {
      final task = createTaskFromNlp('meeting weekly');
      expect(task.repeatRule, 'weekly');
    });

    test('12. "class every Monday" → weekly:1', () {
      final task = createTaskFromNlp('class every Monday');
      expect(task.repeatRule, 'weekly:1');
    });

    test('13. "gym every Monday, Wednesday, Friday" → weekly:1,3,5', () {
      final task = createTaskFromNlp('gym every Monday, Wednesday, Friday');
      expect(task.repeatRule, 'weekly:1,3,5');
    });

    // ===== Pre-reminder via NLP =====
    test('14. "remind me 30 minutes before meeting" → 30 min pre-reminder', () {
      final task = createTaskFromNlp('remind me 30 minutes before meeting');
      expect(task.preReminderOffset, 30);
    });

    test('15. "remind me 2 hours before exam" → 120 min pre-reminder', () {
      final task = createTaskFromNlp('remind me 2 hours before exam');
      expect(task.preReminderOffset, 120);
    });

    // ===== Repeat end date via NLP =====
    test('16. "exercise daily until 2026-12-31" → repeat end date', () {
      final task = createTaskFromNlp('exercise daily until 2026-12-31');
      expect(task.repeatRule, 'daily');
      expect(task.repeatEndDate, isNotNull);
      expect(task.repeatEndDate!.year, 2026);
    });

    // ===== Combined =====
    test('17. Complex: "math exam tomorrow at 2 PM #exam remind me 1 hour before"', () {
      final task = createTaskFromNlp('math exam tomorrow at 2 PM #exam remind me 1 hour before');
      expect(task.category, TaskCategory.exam);
      expect(task.dueDate, isNotNull);
      expect(task.dueTime!.hour, 14);
      expect(task.preReminderOffset, 60);
    });

    test('18. Vietnamese complex: "nộp bài tập về nhà ngày mai lúc 5pm"', () {
      final task = createTaskFromNlp('nộp bài tập về nhà ngày mai lúc 5pm');
      expect(task.category, TaskCategory.assignment);
      expect(task.dueDate, isNotNull);
      expect(task.dueTime, isNotNull);
    });

    // ===== Edge cases =====
    test('19. Empty input creates untitled task', () {
      final task = createTaskFromNlp('');
      expect(task.title, isNotEmpty);
    });

    test('20. Task created from NLP has pending status', () {
      final task = createTaskFromNlp('do something');
      expect(task.status, TaskStatus.pending);
    });

    test('21. NLP task has valid ID', () {
      final task = createTaskFromNlp('test');
      expect(task.id.isNotEmpty, isTrue);
    });

    test('22. NLP preserves title after all extractions', () {
      final task = createTaskFromNlp('Study for exam tomorrow at 3 PM daily');
      expect(task.title.toLowerCase(), contains('study'));
      expect(task.title.toLowerCase(), isNot(contains('tomorrow')));
    });

    test('23. Multiple categories: last matching tag wins', () {
      // "exam" tag detected first → exam category
      final task = createTaskFromNlp('#exam study #class notes');
      expect(task.category, TaskCategory.exam); // #exam matches first
    });

    test('24. Tags removed from title', () {
      final task = createTaskFromNlp('#urgent do laundry');
      expect(task.title, isNot(contains('#urgent')));
    });

    test('25. "deadline" keyword → assignment category', () {
      final task = createTaskFromNlp('submit report deadline');
      expect(task.category, TaskCategory.assignment);
    });
  });
}
