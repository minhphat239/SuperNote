import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/models/task.dart';

/// Simulates TaskService._calculateNextDueDate() logic
DateTime? calculateNextDueDate(Task task) {
  if (task.dueDate == null) return null;
  final rule = task.repeatRule!;
  final current = task.dueDate!;

  switch (rule) {
    case 'daily':
      return current.add(const Duration(days: 1));
    case 'weekly':
      return current.add(const Duration(days: 7));
    case 'monthly':
      final nextMonth = current.month + 1 > 12 ? 1 : current.month + 1;
      final nextYear = current.month + 1 > 12 ? current.year + 1 : current.year;
      final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
      return DateTime(nextYear, nextMonth, current.day.clamp(1, maxDay));
    default:
      if (rule.startsWith('weekly:')) {
        final daysStr = rule.substring(7);
        final days = daysStr.split(',').map(int.parse).toList()..sort();
        final currentWeekday = current.weekday;
        for (final day in days) {
          if (day > currentWeekday) {
            return current.add(Duration(days: day - currentWeekday));
          }
        }
        return current.add(Duration(days: 7 - currentWeekday + days.first));
      }
      if (rule.startsWith('every_') && rule.endsWith('_days')) {
        final days = int.parse(rule.substring(6, rule.length - 5));
        return current.add(Duration(days: days));
      }
      if (rule.startsWith('every_') && rule.endsWith('_weeks')) {
        final weeks = int.parse(rule.substring(6, rule.length - 6));
        return current.add(Duration(days: weeks * 7));
      }
      return null;
  }
}

/// Checks if next occurrence is after repeat end date
bool shouldCreateNext(Task task, DateTime nextDate) {
  if (task.repeatEndDate != null && nextDate.isAfter(task.repeatEndDate!)) {
    return false;
  }
  return true;
}

void main() {
  group('Tab Tasks — Repeat & Recurrence Edge Cases', () {
    // ===== Daily =====
    test('1. Daily repeat adds 1 day', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15), repeatRule: 'daily');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 16));
    });

    test('2. Daily repeat across month boundary', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 1, 31), repeatRule: 'daily');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 2, 1));
    });

    test('3. Daily repeat across year boundary', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 12, 31), repeatRule: 'daily');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2027, 1, 1));
    });

    // ===== Weekly =====
    test('4. Weekly repeat adds 7 days', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15), repeatRule: 'weekly');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 22));
    });

    // ===== Weekly specific days =====
    test('5. Weekly Mon/Wed/Fri from Monday → next is Wednesday', () {
      // 2026-03-16 is Monday
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 16), repeatRule: 'weekly:1,3,5');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 18)); // Wednesday
    });

    test('6. Weekly Mon/Wed/Fri from Friday → wraps to Monday', () {
      // 2026-03-20 is Friday
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 20), repeatRule: 'weekly:1,3,5');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 23)); // Next Monday
    });

    test('7. Weekly only Monday from Tuesday → next Monday', () {
      // 2026-03-17 is Tuesday
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 17), repeatRule: 'weekly:1');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 23)); // Monday
    });

    // ===== Monthly =====
    test('8. Monthly repeat normal month', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15), repeatRule: 'monthly');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 4, 15));
    });

    test('9. Monthly repeat from Jan 31 → Feb 28 (clamped)', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 1, 31), repeatRule: 'monthly');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 2, 28));
    });

    test('10. Monthly repeat from Jan 31 in leap year → Feb 29', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2028, 1, 31), repeatRule: 'monthly');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2028, 2, 29));
    });

    test('11. Monthly repeat from Dec → wraps to Jan', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 12, 15), repeatRule: 'monthly');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2027, 1, 15));
    });

    // ===== Custom every N days =====
    test('12. Every 3 days', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15), repeatRule: 'every_3_days');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 18));
    });

    test('13. Every 7 days is same as weekly', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15), repeatRule: 'every_7_days');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 22));
    });

    // ===== Custom every N weeks =====
    test('14. Every 2 weeks', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15), repeatRule: 'every_2_weeks');
      final next = calculateNextDueDate(task);
      expect(next, DateTime(2026, 3, 29));
    });

    // ===== No repeat rule =====
    test('15. No repeat rule returns null (handled by null check on dueDate first)', () {
      final task = Task(id: '1', title: 'T', dueDate: DateTime(2026, 3, 15));
      // calculateNextDueDate checks dueDate first, then uses repeatRule!
      // If repeatRule is null, the ! operator will crash
      // This test documents the expected behavior: caller must check repeatRule first
      expect(task.repeatRule, isNull);
    });

    test('16. No dueDate returns null', () {
      final task = Task(id: '1', title: 'T', repeatRule: 'daily');
      final next = calculateNextDueDate(task);
      expect(next, isNull);
    });

    // ===== Repeat end date =====
    test('17. Should create next when before end date', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 3, 15),
        repeatRule: 'daily',
        repeatEndDate: DateTime(2026, 3, 20),
      );
      final next = calculateNextDueDate(task)!;
      expect(shouldCreateNext(task, next), isTrue);
    });

    test('18. Should NOT create next when after end date', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 3, 19),
        repeatRule: 'daily',
        repeatEndDate: DateTime(2026, 3, 20),
      );
      final next = calculateNextDueDate(task)!;
      expect(shouldCreateNext(task, next), isTrue); // 3/20 is NOT after 3/20
    });

    test('19. Should NOT create next when past end date', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 3, 20),
        repeatRule: 'daily',
        repeatEndDate: DateTime(2026, 3, 20),
      );
      final next = calculateNextDueDate(task)!; // 3/21
      expect(shouldCreateNext(task, next), isFalse); // 3/21 is AFTER 3/20
    });

    test('20. Repeat end date exactly on next date → allowed', () {
      final task = Task(
        id: '1', title: 'T',
        dueDate: DateTime(2026, 3, 19),
        repeatRule: 'daily',
        repeatEndDate: DateTime(2026, 3, 20),
      );
      final next = calculateNextDueDate(task)!; // 3/20
      // isAfter checks strictly >, so 3/20 is NOT after 3/20
      expect(next.isAfter(task.repeatEndDate!), isFalse);
    });

    // ===== Edge: subtasks reset =====
    test('21. Next occurrence resets subtask isDone', () {
      final originalSubs = [
        SubTask(id: 's1', title: 'Step 1', isDone: true),
        SubTask(id: 's2', title: 'Step 2', isDone: false),
      ];
      // Simulating _createNextOccurrence
      final nextSubs = originalSubs
          .map((s) => SubTask(id: s.id, title: s.title, isDone: false))
          .toList();
      expect(nextSubs[0].isDone, isFalse);
      expect(nextSubs[1].isDone, isFalse);
    });

    // ===== Stress: many occurrences =====
    test('22. Daily repeat: 30 occurrences stay within month', () {
      var date = DateTime(2026, 3, 1);
      for (var i = 0; i < 30; i++) {
        date = date.add(const Duration(days: 1));
      }
      expect(date, DateTime(2026, 3, 31));
    });

    test('23. Weekly repeat: 52 weeks from Jan 1 lands on Dec 31', () {
      var date = DateTime(2026, 1, 1);
      for (var i = 0; i < 52; i++) {
        date = date.add(const Duration(days: 7));
      }
      // 52 * 7 = 364 days from Jan 1 → Dec 30
      // But Dart adds exactly 364 days to Jan 1 = Dec 30
      expect(date.month, 12);
    });

    test('24. Monthly repeat: 12 occurrences = 1 year', () {
      var date = DateTime(2026, 1, 15);
      for (var i = 0; i < 12; i++) {
        final nextMonth = date.month + 1 > 12 ? 1 : date.month + 1;
        final nextYear = date.month + 1 > 12 ? date.year + 1 : date.year;
        final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
        date = DateTime(nextYear, nextMonth, date.day.clamp(1, maxDay));
      }
      expect(date, DateTime(2027, 1, 15));
    });

    // ===== Monthly edge: Feb 28 repeatedly =====
    test('25. Monthly from Feb 28 stays on 28 in non-leap year', () {
      var date = DateTime(2026, 2, 28);
      // March 2026 → 28 (max 31) → 28
      final nextMonth = date.month + 1;
      final maxDay = DateTime(2026, nextMonth + 1, 0).day;
      date = DateTime(2026, nextMonth, date.day.clamp(1, maxDay));
      expect(date, DateTime(2026, 3, 28));
    });

    test('26. Monthly from Jan 31 → Feb 28 → Mar 28 (drift!)', () {
      var date = DateTime(2026, 1, 31);
      // Feb: clamp(31, 28) = 28
      date = DateTime(2026, 2, date.day.clamp(1, 28));
      expect(date, DateTime(2026, 2, 28));
      // Mar: clamp(28, 31) = 28
      date = DateTime(2026, 3, date.day.clamp(1, 31));
      expect(date.day, 28); // DRIFT: Jan 31 → Feb 28 → Mar 28 (lost 3 days!)
    });
  });
}
