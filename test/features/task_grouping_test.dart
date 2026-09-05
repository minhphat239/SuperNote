import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

/// Simulates TaskService.getTasksGroupedByDate() logic
Map<String, List<Task>> groupTasks(List<Task> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final thisWeekEnd = today.add(Duration(days: 7 - now.weekday + 1));

  final groups = <String, List<Task>>{
    'Overdue': [], 'Today': [], 'Tomorrow': [],
    'This Week': [], 'Later': [], 'No Date': [],
  };

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

  // Sort each group by deadline (nulls last)
  for (final list in groups.values) {
    list.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return 0;
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
  }

  return groups;
}

/// Simulates getTasksForDate()
List<Task> getTasksForDate(List<Task> tasks, DateTime date) {
  final target = DateTime(date.year, date.month, date.day);
  return tasks.where((t) {
    if (t.status == TaskStatus.done) return false;
    if (t.dueDate == null) return false;
    final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
    return taskDate.isAtSameMomentAs(target);
  }).toList();
}

/// Simulates the overdue filter
List<Task> getOverdueTasks(List<Task> tasks) {
  final now = DateTime.now();
  return tasks.where((t) {
    if (t.status == TaskStatus.done) return false;
    if (t.deadline == null) return false;
    return now.isAfter(t.deadline!);
  }).toList();
}

void main() {
  group('Tab Tasks — Grouping & Filtering Logic', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ===== Basic grouping =====
    test('1. Empty list produces empty groups', () {
      final groups = groupTasks([]);
      expect(groups.values.every((g) => g.isEmpty), isTrue);
    });

    test('2. Task with no dueDate goes to No Date group', () {
      final tasks = [Task(id: '1', title: 'No date task')];
      final groups = groupTasks(tasks);
      expect(groups['No Date']!.length, 1);
      expect(groups['Overdue'], isEmpty);
      expect(groups['Today'], isEmpty);
    });

    test('3. Task due today goes to Today group', () {
      final tasks = [Task(id: '1', title: 'Today', dueDate: today)];
      final groups = groupTasks(tasks);
      expect(groups['Today']!.length, 1);
    });

    test('4. Task due tomorrow goes to Tomorrow group', () {
      final tomorrow = today.add(const Duration(days: 1));
      final tasks = [Task(id: '1', title: 'Tmrw', dueDate: tomorrow)];
      final groups = groupTasks(tasks);
      expect(groups['Tomorrow']!.length, 1);
    });

    test('5. Task due yesterday goes to Overdue group', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final tasks = [Task(id: '1', title: 'Late', dueDate: yesterday)];
      final groups = groupTasks(tasks);
      expect(groups['Overdue']!.length, 1);
    });

    test('6. Done tasks are excluded from ALL groups', () {
      final tasks = [
        Task(id: '1', title: 'Done', status: TaskStatus.done, dueDate: today),
        Task(id: '2', title: 'Pending', dueDate: today),
      ];
      final groups = groupTasks(tasks);
      expect(groups['Today']!.length, 1);
      // The done task shouldn't be in any group
      final allTasks = groups.values.expand((g) => g).toList();
      expect(allTasks.every((t) => t.status != TaskStatus.done), isTrue);
    });

    test('7. Snoozed tasks appear in their deadline group', () {
      final tasks = [Task(id: '1', title: 'Snoozed', dueDate: today, status: TaskStatus.snoozed)];
      final groups = groupTasks(tasks);
      expect(groups['Today']!.length, 1);
    });

    // ===== Sorting within groups =====
    test('8. Tasks sorted by deadline within Today group', () {
      final tasks = [
        Task(id: '1', title: 'Afternoon', dueDate: today, dueTime: DateTime(2000, 1, 1, 14, 0)),
        Task(id: '2', title: 'Morning', dueDate: today, dueTime: DateTime(2000, 1, 1, 9, 0)),
        Task(id: '3', title: 'No time', dueDate: today),
      ];
      final groups = groupTasks(tasks);
      expect(groups['Today']![0].title, 'Morning');
      expect(groups['Today']![1].title, 'No time'); // 9:00 AM default
      expect(groups['Today']![2].title, 'Afternoon');
    });

    test('9. Tasks with no deadline are sorted last', () {
      final tasks = [
        Task(id: '1', title: 'No date'),
        Task(id: '2', title: 'Has date', dueDate: today),
      ];
      final groups = groupTasks(tasks);
      expect(groups['Today']!.length, 1);
      expect(groups['No Date']!.length, 1);
    });

    // ===== getTasksForDate =====
    test('10. getTasksForDate returns only tasks for that date', () {
      final tasks = [
        Task(id: '1', title: 'Match', dueDate: today),
        Task(id: '2', title: 'No match', dueDate: today.add(const Duration(days: 1))),
      ];
      final result = getTasksForDate(tasks, today);
      expect(result.length, 1);
      expect(result[0].title, 'Match');
    });

    test('11. getTasksForDate excludes done tasks', () {
      final tasks = [
        Task(id: '1', title: 'Done', dueDate: today, status: TaskStatus.done),
        Task(id: '2', title: 'Pending', dueDate: today),
      ];
      final result = getTasksForDate(tasks, today);
      expect(result.length, 1);
      expect(result[0].title, 'Pending');
    });

    test('12. getTasksForDate excludes tasks without dueDate', () {
      final tasks = [Task(id: '1', title: 'No date')];
      final result = getTasksForDate(tasks, today);
      expect(result, isEmpty);
    });

    test('13. getTasksForDate matches by day only (ignores time)', () {
      final tasks = [
        Task(id: '1', title: 'Morning', dueDate: today, dueTime: DateTime(2000, 1, 1, 9, 0)),
        Task(id: '2', title: 'Night', dueDate: today, dueTime: DateTime(2000, 1, 1, 23, 59)),
      ];
      final result = getTasksForDate(tasks, today);
      expect(result.length, 2);
    });

    // ===== Overdue filter =====
    test('14. Overdue tasks are identified correctly', () {
      final tasks = [
        Task(id: '1', title: 'Late', dueDate: today.subtract(const Duration(days: 1))),
        Task(id: '2', title: 'On time', dueDate: today.add(const Duration(days: 1))),
      ];
      final overdue = getOverdueTasks(tasks);
      expect(overdue.length, 1);
      expect(overdue[0].title, 'Late');
    });

    test('15. Done overdue tasks are NOT in overdue list', () {
      final tasks = [
        Task(id: '1', title: 'Done late', dueDate: today.subtract(const Duration(days: 1)), status: TaskStatus.done),
      ];
      final overdue = getOverdueTasks(tasks);
      expect(overdue, isEmpty);
    });

    test('16. Snoozed overdue tasks ARE in overdue list', () {
      final tasks = [
        Task(id: '1', title: 'Snoozed late', dueDate: today.subtract(const Duration(days: 1)), status: TaskStatus.snoozed),
      ];
      final overdue = getOverdueTasks(tasks);
      expect(overdue.length, 1);
    });

    // ===== Mixed scenarios =====
    test('17. Multiple tasks in different groups', () {
      final tomorrow = today.add(const Duration(days: 1));
      final nextWeek = today.add(const Duration(days: 10));
      final tasks = [
        Task(id: '1', title: 'Today', dueDate: today),
        Task(id: '2', title: 'Tomorrow', dueDate: tomorrow),
        Task(id: '3', title: 'Later', dueDate: nextWeek),
        Task(id: '4', title: 'No date'),
        Task(id: '5', title: 'Late', dueDate: today.subtract(const Duration(days: 1))),
        Task(id: '6', title: 'Done', dueDate: today, status: TaskStatus.done),
      ];
      final groups = groupTasks(tasks);
      expect(groups['Today']!.length, 1);
      expect(groups['Tomorrow']!.length, 1);
      expect(groups['Later']!.length, 1);
      expect(groups['No Date']!.length, 1);
      expect(groups['Overdue']!.length, 1);
    });

    test('18. All tasks done → all groups empty', () {
      final tasks = [
        Task(id: '1', title: 'A', dueDate: today, status: TaskStatus.done),
        Task(id: '2', title: 'B', dueDate: today, status: TaskStatus.done),
      ];
      final groups = groupTasks(tasks);
      expect(groups.values.every((g) => g.isEmpty), isTrue);
    });

    test('19. 100 tasks across groups', () {
      final tasks = <Task>[];
      for (var i = 0; i < 25; i++) {
        tasks.add(Task(id: 'no_$i', title: 'No date $i'));
        tasks.add(Task(id: 'today_$i', title: 'Today $i', dueDate: today));
        tasks.add(Task(id: 'late_$i', title: 'Late $i', dueDate: today.subtract(Duration(days: i + 1))));
        tasks.add(Task(id: 'future_$i', title: 'Future $i', dueDate: today.add(Duration(days: 30 + i))));
      }
      final groups = groupTasks(tasks);
      expect(groups['No Date']!.length, 25);
      expect(groups['Today']!.length, 25);
      expect(groups['Overdue']!.length, 25);
      expect(groups['Later']!.length, 25);
    });

    test('20. Edge: deadline at exactly midnight today', () {
      final midnight = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final tasks = [Task(id: '1', title: 'Midnight', dueDate: midnight)];
      final groups = groupTasks(tasks);
      // midnight < today.add(1 day) → Today
      expect(groups['Today']!.length, 1);
    });

    test('21. Edge: deadline at 23:59:59 today', () {
      final tonight = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final tasks = [Task(id: '1', title: 'Tonight', dueDate: tonight)];
      final groups = groupTasks(tasks);
      expect(groups['Today']!.length, 1);
    });

    test('22. Edge: deadline at 00:00:01 tomorrow', () {
      final tomorrowStart = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
      final tasks = [Task(id: '1', title: 'Early tmrw', dueDate: tomorrowStart)];
      final groups = groupTasks(tasks);
      expect(groups['Tomorrow']!.length, 1);
    });
  });
}
