import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/services/nlp_service.dart';
import 'package:super_note/models/task.dart';

void main() {
  group('NlpService.parse', () {
    // ===== Basic title extraction =====
    test('1. Plain text returns as-is title', () {
      final result = NlpService.parse('Buy groceries');
      expect(result.title, 'Buy groceries');
      expect(result.hasDate, isFalse);
      expect(result.hasTime, isFalse);
      expect(result.hasCategory, isFalse);
    });

    test('2. Empty input returns Untitled Task', () {
      final result = NlpService.parse('');
      expect(result.title, 'Untitled Task');
    });

    // ===== Due date extraction =====
    test('3. "tomorrow" extracts tomorrow date', () {
      final result = NlpService.parse('Meeting tomorrow');
      expect(result.hasDate, isTrue);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result.dueDate!.year, tomorrow.year);
      expect(result.dueDate!.month, tomorrow.month);
      expect(result.dueDate!.day, tomorrow.day);
    });

    test('4. "today" extracts today date', () {
      final result = NlpService.parse('Do laundry today');
      expect(result.hasDate, isTrue);
      final now = DateTime.now();
      expect(result.dueDate!.year, now.year);
      expect(result.dueDate!.month, now.month);
      expect(result.dueDate!.day, now.day);
    });

    test('5. "ngày mai" (Vietnamese) extracts tomorrow', () {
      final result = NlpService.parse('Họp nhóm ngày mai');
      expect(result.hasDate, isTrue);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result.dueDate!.day, tomorrow.day);
    });

    test('6. "next week" extracts next Monday', () {
      final result = NlpService.parse('Submit report next week');
      expect(result.hasDate, isTrue);
      expect(result.dueDate!.weekday, 1); // Monday
    });

    test('7. Specific date "12/25" extracts December 25', () {
      final result = NlpService.parse('Christmas party 12/25');
      expect(result.hasDate, isTrue);
      expect(result.dueDate!.month, 12);
      expect(result.dueDate!.day, 25);
    });

    test('8. ISO date "2026-09-15" extracts correctly', () {
      final result = NlpService.parse('Deadline 2026-09-15');
      expect(result.hasDate, isTrue);
      expect(result.dueDate!.year, 2026);
      expect(result.dueDate!.month, 9);
      expect(result.dueDate!.day, 15);
    });

    test('9. "in 3 days" extracts 3 days from now', () {
      final result = NlpService.parse('Submit in 3 days');
      expect(result.hasDate, isTrue);
      final expected = DateTime.now().add(const Duration(days: 3));
      expect(result.dueDate!.day, expected.day);
    });

    test('10. "3 ngày nữa" (Vietnamese) extracts 3 days from now', () {
      final result = NlpService.parse('Nộp bài 3 ngày nữa');
      expect(result.hasDate, isTrue);
    });

    // ===== Due time extraction =====
    test('11. "6 PM" extracts 18:00', () {
      final result = NlpService.parse('Call at 6 PM');
      expect(result.hasTime, isTrue);
      expect(result.dueTime!.hour, 18);
      expect(result.dueTime!.minute, 0);
    });

    test('12. "14:30" extracts 14:30', () {
      final result = NlpService.parse('Meeting at 14:30');
      expect(result.hasTime, isTrue);
      expect(result.dueTime!.hour, 14);
      expect(result.dueTime!.minute, 30);
    });

    test('13. "9am" extracts 9:00', () {
      final result = NlpService.parse('Wake up at 9am');
      expect(result.hasTime, isTrue);
      expect(result.dueTime!.hour, 9);
    });

    test('14. "12:30" (24h format) extracts 12:30', () {
      final result = NlpService.parse('Ăn trưa lúc 12:30');
      expect(result.hasTime, isTrue);
      expect(result.dueTime!.hour, 12);
      expect(result.dueTime!.minute, 30);
    });

    // ===== Category extraction =====
    test('15. "exam" keyword extracts exam category', () {
      final result = NlpService.parse('Math exam tomorrow');
      expect(result.hasCategory, isTrue);
      expect(result.category, TaskCategory.exam);
    });

    test('16. "homework" keyword extracts assignment category', () {
      final result = NlpService.parse('Do homework tonight');
      expect(result.hasCategory, isTrue);
      expect(result.category, TaskCategory.assignment);
    });

    test('17. "class" keyword extracts class_ category', () {
      final result = NlpService.parse('Attend class tomorrow');
      expect(result.hasCategory, isTrue);
      expect(result.category, TaskCategory.class_);
    });

    test('18. "#exam" tag extracts exam category', () {
      final result = NlpService.parse('Study #exam finals');
      expect(result.hasCategory, isTrue);
      expect(result.category, TaskCategory.exam);
    });

    test('19. "#class" tag extracts class_ category', () {
      final result = NlpService.parse('Review #class notes');
      expect(result.hasCategory, isTrue);
      expect(result.category, TaskCategory.class_);
    });

    // ===== Repeat rule extraction =====
    test('20. "daily" extracts daily repeat', () {
      final result = NlpService.parse('Exercise daily');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'daily');
    });

    test('21. "hàng ngày" (Vietnamese) extracts daily repeat', () {
      final result = NlpService.parse('Thiền hàng ngày');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'daily');
    });

    test('22. "weekly" extracts weekly repeat', () {
      final result = NlpService.parse('Team meeting weekly');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'weekly');
    });

    test('23. "every Monday" extracts weekly:1', () {
      final result = NlpService.parse('Class every Monday');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'weekly:1');
    });

    test('24. "every Monday, Wednesday, Friday" extracts weekly:1,3,5', () {
      final result = NlpService.parse('Class every Monday, Wednesday, Friday');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'weekly:1,3,5');
    });

    test('25. "monthly" extracts monthly repeat', () {
      final result = NlpService.parse('Report monthly');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'monthly');
    });

    // ===== Tag extraction =====
    test('26. Hashtags are extracted as tags', () {
      final result = NlpService.parse('Study math #exam #important');
      expect(result.tags, contains('exam'));
      expect(result.tags, contains('important'));
    });

    test('27. Tags are removed from title', () {
      final result = NlpService.parse('Study math #exam');
      expect(result.title, isNot(contains('#exam')));
    });

    // ===== Combined =====
    test('28. Complex input: title + date + time + category', () {
      final result = NlpService.parse('Math exam tomorrow at 2 PM');
      expect(result.title, isNotEmpty);
      expect(result.hasDate, isTrue);
      expect(result.hasTime, isTrue);
      expect(result.category, TaskCategory.exam);
    });

    test('29. Vietnamese: "bài tập về nhà" extracts assignment', () {
      final result = NlpService.parse('Làm bài tập về nhà ngày mai');
      expect(result.hasCategory, isTrue);
      expect(result.category, TaskCategory.assignment);
    });

    test('30. NlpPreview toMap produces correct map', () {
      final result = NlpService.parse('Test task');
      final m = result.toMap();
      expect(m['title'], isNotNull);
      expect(m.containsKey('dueDate'), isTrue);
      expect(m.containsKey('dueTime'), isTrue);
      expect(m.containsKey('category'), isTrue);
    });
  });
}
