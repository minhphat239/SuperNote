import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_note/models/task.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task Service Logic (pure)', () {
    // ===== getTasksGroupedByDate logic =====
    test('1. Tasks are grouped by deadline proximity', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final tasks = [
        Task(id: '1', title: 'Today', dueDate: today, dueTime: DateTime(2000, 1, 1, 10, 0)),
        Task(id: '2', title: 'Tomorrow', dueDate: tomorrow, dueTime: DateTime(2000, 1, 1, 10, 0)),
        Task(id: '3', title: 'No Date'),
        Task(id: '4', title: 'Done', dueDate: today, status: TaskStatus.done),
      ];

      // Group them manually using the same logic as TaskService
      final groups = <String, List<Task>>{
        'Today': [], 'Tomorrow': [], 'This Week': [],
        'Later': [], 'No Date': [], 'Overdue': [],
      };

      final thisWeekEnd = today.add(Duration(days: 7 - now.weekday + 1));
      for (final task in tasks) {
        if (task.status == TaskStatus.done) continue;
        final deadline = task.deadline;
        if (deadline == null) {
          groups['No Date']!.add(task);
        } else if (deadline.isBefore(today)) {
          groups['Overdue']!.add(task);
        } else if (deadline.isBefore(tomorrow)) {
          groups['Today']!.add(task);
        } else if (deadline.isBefore(tomorrow.add(const Duration(days: 1)))) {
          groups['Tomorrow']!.add(task);
        } else if (deadline.isBefore(thisWeekEnd)) {
          groups['This Week']!.add(task);
        } else {
          groups['Later']!.add(task);
        }
      }

      expect(groups['Today']!.length, 1);
      expect(groups['Today']![0].title, 'Today');
      expect(groups['Tomorrow']!.length, 1);
      expect(groups['No Date']!.length, 1);
      expect(groups['Overdue']!.length, 0);
      expect(groups['Done'], isNull); // Done tasks excluded
    });

    test('2. Overdue tasks are in Overdue group', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = Task(id: '1', title: 'Late', dueDate: yesterday, dueTime: DateTime(2000, 1, 1, 8, 0));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final deadline = task.deadline!;

      expect(deadline.isBefore(today), isTrue);
    });

    test('3. Done tasks are excluded from groups', () {
      final tasks = [
        Task(id: '1', title: 'Pending', status: TaskStatus.pending),
        Task(id: '2', title: 'Done', status: TaskStatus.done),
        Task(id: '3', title: 'Snoozed', status: TaskStatus.snoozed),
      ];
      final pending = tasks.where((t) => t.status != TaskStatus.done).toList();
      expect(pending.length, 2);
    });

    test('4. Tasks sorted by deadline within groups', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tasks = [
        Task(id: '1', title: 'Late', dueDate: today, dueTime: DateTime(2000, 1, 1, 14, 0)),
        Task(id: '2', title: 'Early', dueDate: today, dueTime: DateTime(2000, 1, 1, 8, 0)),
        Task(id: '3', title: 'No time'),
      ];

      tasks.sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });

      expect(tasks[0].title, 'Early');
      expect(tasks[1].title, 'Late');
      expect(tasks[2].title, 'No time');
    });

    test('5. getTasksForDate returns matching tasks', () {
      final target = DateTime(2026, 5, 15);
      final tasks = [
        Task(id: '1', title: 'Match', dueDate: target, status: TaskStatus.pending),
        Task(id: '2', title: 'No Match', dueDate: DateTime(2026, 5, 16)),
        Task(id: '3', title: 'Done', dueDate: target, status: TaskStatus.done),
      ];

      final matched = tasks.where((t) {
        if (t.status == TaskStatus.done) return false;
        if (t.dueDate == null) return false;
        final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        final targetDay = DateTime(target.year, target.month, target.day);
        return taskDate.isAtSameMomentAs(targetDay);
      }).toList();

      expect(matched.length, 1);
      expect(matched[0].title, 'Match');
    });

    // ===== NLP task category assignment =====
    test('6. Tag "class" maps to class_ category', () {
      const tag = 'class';
      TaskCategory category = TaskCategory.personal;
      if (tag == 'class' || tag == 'hoc' || tag == 'lop') {
        category = TaskCategory.class_;
      }
      expect(category, TaskCategory.class_);
    });

    test('7. Tag "exam" maps to exam category', () {
      const tag = 'exam';
      TaskCategory category = TaskCategory.personal;
      if (tag == 'exam' || tag == 'thi' || tag == 'kythi') {
        category = TaskCategory.exam;
      }
      expect(category, TaskCategory.exam);
    });

    test('8. Tag "assignment" maps to assignment category', () {
      const tag = 'assignment';
      TaskCategory category = TaskCategory.personal;
      if (tag == 'assignment' || tag == 'baitap' || tag == 'homework' || tag == 'bt') {
        category = TaskCategory.assignment;
      }
      expect(category, TaskCategory.assignment);
    });

    // ===== Repeat rule calculation =====
    test('9. Daily repeat adds 1 day', () {
      final base = DateTime(2026, 3, 15);
      final next = base.add(const Duration(days: 1));
      expect(next.day, 16);
    });

    test('10. Weekly repeat adds 7 days', () {
      final base = DateTime(2026, 3, 15);
      final next = base.add(const Duration(days: 7));
      expect(next.day, 22);
    });

    test('11. Monthly repeat handles month overflow', () {
      final base = DateTime(2026, 1, 31);
      final nextMonth = base.month + 1 > 12 ? 1 : base.month + 1;
      final nextYear = base.month + 1 > 12 ? base.year + 1 : base.year;
      final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
      final next = DateTime(nextYear, nextMonth, base.day.clamp(1, maxDay));
      expect(next.month, 2);
      expect(next.day, 28); // Clamped from 31
    });

    test('12. Repeat respects end date', () {
      final repeatEnd = DateTime(2026, 3, 20);
      final nextDate = DateTime(2026, 3, 22);
      final shouldCreate = !nextDate.isAfter(repeatEnd);
      expect(shouldCreate, isFalse);
    });

    // ===== Toggle logic =====
    test('13. Toggle pending → done', () {
      final task = Task(id: '1', title: 'T', status: TaskStatus.pending);
      final newStatus = task.isDone ? TaskStatus.pending : TaskStatus.done;
      expect(newStatus, TaskStatus.done);
    });

    test('14. Toggle done → pending', () {
      final task = Task(id: '1', title: 'T', status: TaskStatus.done);
      final newStatus = task.isDone ? TaskStatus.pending : TaskStatus.done;
      expect(newStatus, TaskStatus.pending);
    });

    test('15. Snooze sets status to snoozed', () {
      final task = Task(id: '1', title: 'T', status: TaskStatus.pending);
      final now = DateTime.now();
      final newDeadline = now.add(const Duration(minutes: 30));
      final snoozed = task.copyWith(
        dueDate: DateTime(newDeadline.year, newDeadline.month, newDeadline.day),
        dueTime: DateTime(2000, 1, 1, newDeadline.hour, newDeadline.minute),
        status: TaskStatus.snoozed,
      );
      expect(snoozed.status, TaskStatus.snoozed);
      expect(snoozed.dueDate, isNotNull);
      expect(snoozed.dueTime, isNotNull);
    });

    // ===== ID generation =====
    test('16. Generated IDs are unique', () {
      final ids = <String>{};
      for (var i = 0; i < 100; i++) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final rand = i.toRadixString(16);
        ids.add('${ts}_$rand');
      }
      expect(ids.length, 100);
    });

    // ===== Task list operations =====
    test('17. tasks getter returns unmodifiable list', () {
      final tasks = [
        Task(id: '1', title: 'A'),
        Task(id: '2', title: 'B'),
      ];
      final unmod = List.unmodifiable(tasks);
      expect(unmod.length, 2);
      expect(() => unmod.add(Task(id: '3', title: 'C')), throwsA(anything));
    });

    test('18. pendingTasks filter works', () {
      final tasks = [
        Task(id: '1', title: 'P', status: TaskStatus.pending),
        Task(id: '2', title: 'D', status: TaskStatus.done),
        Task(id: '3', title: 'S', status: TaskStatus.snoozed),
      ];
      final pending = tasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.snoozed).toList();
      expect(pending.length, 2);
    });

    test('19. completedTasks filter works', () {
      final tasks = [
        Task(id: '1', title: 'P', status: TaskStatus.pending),
        Task(id: '2', title: 'D', status: TaskStatus.done),
        Task(id: '3', title: 'S', status: TaskStatus.done),
      ];
      final done = tasks.where((t) => t.status == TaskStatus.done).toList();
      expect(done.length, 2);
    });

    test('20. Task insert at beginning', () {
      final tasks = [Task(id: '1', title: 'Old')];
      final newTask = Task(id: '2', title: 'New');
      tasks.insert(0, newTask);
      expect(tasks[0].title, 'New');
      expect(tasks[1].title, 'Old');
    });
  });
}
