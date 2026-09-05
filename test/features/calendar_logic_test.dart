import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

/// Simulates calendar date logic from CalendarScreen
class CalendarHelper {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  static bool isPast(DateTime date) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayMidnight);
  }

  static bool isFuture(DateTime date) {
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return date.isAfter(endOfToday);
  }

  /// Get days in month
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get weekday of first day of month (1=Mon, 7=Sun)
  static int firstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday;
  }

  /// Get tasks for a specific date
  static List<Task> getTasksForDate(List<Task> tasks, DateTime date) {
    return tasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      if (t.dueDate == null) return false;
      return isSameDay(t.dueDate!, date);
    }).toList();
  }

  /// Count tasks with dots for calendar
  static int getTaskCountForDate(List<Task> tasks, DateTime date) {
    return getTasksForDate(tasks, date).length;
  }

  /// Get upcoming tasks (next N days)
  static List<Task> getUpcomingTasks(List<Task> tasks, {int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endRange = today.add(Duration(days: days));

    return tasks.where((t) {
      if (t.status == TaskStatus.done) return false;
      if (t.dueDate == null) return false;
      final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return !taskDate.isBefore(today) && taskDate.isBefore(endRange);
    }).toList();
  }

  /// Group tasks by time slot (Morning/Afternoon/Evening)
  static Map<String, List<Task>> groupByTimeSlot(List<Task> tasks) {
    final groups = <String, List<Task>>{
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
    };

    for (final task in tasks) {
      final hour = task.dueTime?.hour ?? 9; // default 9 AM
      if (hour < 12) {
        groups['Morning']!.add(task);
      } else if (hour < 18) {
        groups['Afternoon']!.add(task);
      } else {
        groups['Evening']!.add(task);
      }
    }

    return groups;
  }
}

void main() {
  group('Tab Calendar — Date Calculations', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ===== isSameDay =====
    test('1. isSameDay: same date returns true', () {
      expect(CalendarHelper.isSameDay(today, today), isTrue);
    });

    test('2. isSameDay: different dates return false', () {
      final tomorrow = today.add(const Duration(days: 1));
      expect(CalendarHelper.isSameDay(today, tomorrow), isFalse);
    });

    test('3. isSameDay: ignores time component', () {
      final morning = DateTime(2026, 5, 15, 8, 0);
      final evening = DateTime(2026, 5, 15, 20, 0);
      expect(CalendarHelper.isSameDay(morning, evening), isTrue);
    });

    // ===== isToday / isTomorrow / isPast / isFuture =====
    test('4. isToday works correctly', () {
      expect(CalendarHelper.isToday(now), isTrue);
      expect(CalendarHelper.isToday(today), isTrue);
    });

    test('5. isTomorrow works correctly', () {
      final tomorrow = today.add(const Duration(days: 1));
      expect(CalendarHelper.isTomorrow(tomorrow), isTrue);
    });

    test('6. isPast: yesterday is past', () {
      final yesterday = today.subtract(const Duration(days: 1));
      expect(CalendarHelper.isPast(yesterday), isTrue);
    });

    test('7. isPast: today is NOT past', () {
      expect(CalendarHelper.isPast(today), isFalse);
    });

    test('8. isFuture: tomorrow is future', () {
      final tomorrow = today.add(const Duration(days: 1));
      expect(CalendarHelper.isFuture(tomorrow), isTrue);
    });

    test('9. isFuture: today is NOT future', () {
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      expect(CalendarHelper.isFuture(endOfToday), isFalse);
    });

    // ===== daysInMonth =====
    test('10. daysInMonth: February 2026 (non-leap)', () {
      expect(CalendarHelper.daysInMonth(2026, 2), 28);
    });

    test('11. daysInMonth: February 2028 (leap year)', () {
      expect(CalendarHelper.daysInMonth(2028, 2), 29);
    });

    test('12. daysInMonth: January has 31 days', () {
      expect(CalendarHelper.daysInMonth(2026, 1), 31);
    });

    test('13. daysInMonth: April has 30 days', () {
      expect(CalendarHelper.daysInMonth(2026, 4), 30);
    });

    // ===== firstDayOfMonth =====
    test('14. March 2026 starts on Sunday (7)', () {
      expect(CalendarHelper.firstDayOfMonth(2026, 3), 7);
    });

    test('15. April 2026 starts on Wednesday (3)', () {
      expect(CalendarHelper.firstDayOfMonth(2026, 4), 3);
    });

    // ===== getTasksForDate =====
    test('16. Returns tasks for specific date', () {
      final tasks = [
        Task(id: '1', title: 'A', dueDate: today),
        Task(id: '2', title: 'B', dueDate: today.add(const Duration(days: 1))),
      ];
      final result = CalendarHelper.getTasksForDate(tasks, today);
      expect(result.length, 1);
    });

    test('17. Excludes done tasks', () {
      final tasks = [
        Task(id: '1', title: 'Done', dueDate: today, status: TaskStatus.done),
        Task(id: '2', title: 'Pending', dueDate: today),
      ];
      final result = CalendarHelper.getTasksForDate(tasks, today);
      expect(result.length, 1);
    });

    test('18. Excludes tasks without dueDate', () {
      final tasks = [Task(id: '1', title: 'No date')];
      final result = CalendarHelper.getTasksForDate(tasks, today);
      expect(result, isEmpty);
    });

    // ===== getUpcomingTasks =====
    test('19. Returns tasks in next 7 days', () {
      final tasks = [
        Task(id: '1', title: 'Today', dueDate: today),
        Task(id: '2', title: 'In 3 days', dueDate: today.add(const Duration(days: 3))),
        Task(id: '3', title: 'In 10 days', dueDate: today.add(const Duration(days: 10))),
      ];
      final upcoming = CalendarHelper.getUpcomingTasks(tasks, days: 7);
      expect(upcoming.length, 2);
    });

    test('20. Excludes done tasks from upcoming', () {
      final tasks = [
        Task(id: '1', title: 'Done', dueDate: today.add(const Duration(days: 1)), status: TaskStatus.done),
      ];
      final upcoming = CalendarHelper.getUpcomingTasks(tasks);
      expect(upcoming, isEmpty);
    });

    // ===== groupByTimeSlot =====
    test('21. Morning tasks (hour < 12)', () {
      final tasks = [
        Task(id: '1', title: 'Early', dueTime: DateTime(2000, 1, 1, 8, 0)),
        Task(id: '2', title: 'Late', dueTime: DateTime(2000, 1, 1, 14, 0)),
      ];
      final groups = CalendarHelper.groupByTimeSlot(tasks);
      expect(groups['Morning']!.length, 1);
      expect(groups['Afternoon']!.length, 1);
    });

    test('22. Tasks without time default to Morning (9 AM)', () {
      final tasks = [Task(id: '1', title: 'No time')];
      final groups = CalendarHelper.groupByTimeSlot(tasks);
      expect(groups['Morning']!.length, 1);
    });

    test('23. Evening tasks (hour >= 18)', () {
      final tasks = [Task(id: '1', title: 'Night', dueTime: DateTime(2000, 1, 1, 20, 0))];
      final groups = CalendarHelper.groupByTimeSlot(tasks);
      expect(groups['Evening']!.length, 1);
    });

    test('24. Boundary: 12:00 is Afternoon', () {
      final tasks = [Task(id: '1', title: 'Noon', dueTime: DateTime(2000, 1, 1, 12, 0))];
      final groups = CalendarHelper.groupByTimeSlot(tasks);
      expect(groups['Afternoon']!.length, 1);
    });

    test('25. Boundary: 18:00 is Evening', () {
      final tasks = [Task(id: '1', title: '6PM', dueTime: DateTime(2000, 1, 1, 18, 0))];
      final groups = CalendarHelper.groupByTimeSlot(tasks);
      expect(groups['Evening']!.length, 1);
    });
  });
}
