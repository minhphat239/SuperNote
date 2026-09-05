import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/services/nlp_service.dart';
import 'package:super_note/models/task.dart';

void main() {
  group('NlpPreview', () {
    test('1. hasDate returns true when dueDate is set', () {
      final preview = NlpPreview(title: 'T', dueDate: DateTime.now());
      expect(preview.hasDate, isTrue);
    });

    test('2. hasDate returns false when dueDate is null', () {
      final preview = NlpPreview(title: 'T');
      expect(preview.hasDate, isFalse);
    });

    test('3. hasTime returns true when dueTime is set', () {
      final preview = NlpPreview(title: 'T', dueTime: DateTime(2000, 1, 1, 10, 0));
      expect(preview.hasTime, isTrue);
    });

    test('4. hasTime returns false when dueTime is null', () {
      final preview = NlpPreview(title: 'T');
      expect(preview.hasTime, isFalse);
    });

    test('5. hasCategory returns true when category is set', () {
      final preview = NlpPreview(title: 'T', category: TaskCategory.exam);
      expect(preview.hasCategory, isTrue);
    });

    test('6. hasCategory returns false when category is null', () {
      final preview = NlpPreview(title: 'T');
      expect(preview.hasCategory, isFalse);
    });

    test('7. hasRepeat returns true when repeatRule is set', () {
      final preview = NlpPreview(title: 'T', repeatRule: 'daily');
      expect(preview.hasRepeat, isTrue);
    });

    test('8. hasRepeat returns false when repeatRule is null', () {
      final preview = NlpPreview(title: 'T');
      expect(preview.hasRepeat, isFalse);
    });

    test('9. hasPreReminder returns true when preReminderOffset is set', () {
      final preview = NlpPreview(title: 'T', preReminderOffset: 30);
      expect(preview.hasPreReminder, isTrue);
    });

    test('10. hasPreReminder returns false when preReminderOffset is null', () {
      final preview = NlpPreview(title: 'T');
      expect(preview.hasPreReminder, isFalse);
    });

    test('11. tags default to empty list', () {
      final preview = NlpPreview(title: 'T');
      expect(preview.tags, isEmpty);
    });

    test('12. tags are stored', () {
      final preview = NlpPreview(title: 'T', tags: ['exam', 'urgent']);
      expect(preview.tags, ['exam', 'urgent']);
    });

    test('13. toMap includes all fields', () {
      final preview = NlpPreview(
        title: 'Test',
        dueDate: DateTime(2026, 5, 1),
        dueTime: DateTime(2000, 1, 1, 10, 0),
        category: TaskCategory.exam,
        repeatRule: 'daily',
        repeatEndDate: DateTime(2026, 12, 31),
        preReminderOffset: 15,
      );
      final m = preview.toMap();
      expect(m['title'], 'Test');
      expect(m['dueDate'], isNotNull);
      expect(m['dueTime'], isNotNull);
      expect(m['category'], 'exam');
      expect(m['repeatRule'], 'daily');
      expect(m['repeatEndDate'], isNotNull);
      expect(m['preReminderOffset'], 15);
    });

    test('14. toMap with null fields', () {
      final preview = NlpPreview(title: 'T');
      final m = preview.toMap();
      expect(m['dueDate'], isNull);
      expect(m['dueTime'], isNull);
      expect(m['category'], isNull);
      expect(m['repeatRule'], isNull);
    });

    test('15. Pre-reminder: "remind me 30 minutes before"', () {
      final result = NlpService.parse('Meeting remind me 30 minutes before');
      expect(result.hasPreReminder, isTrue);
      expect(result.preReminderOffset, 30);
    });

    test('16. Pre-reminder: "remind me 2 hours before"', () {
      final result = NlpService.parse('Meeting remind me 2 hours before');
      expect(result.hasPreReminder, isTrue);
      expect(result.preReminderOffset, 120);
    });

    test('17. Pre-reminder: "nhắc trước 15 phút"', () {
      final result = NlpService.parse('Họp nhắc trước 15 phút');
      expect(result.hasPreReminder, isTrue);
      expect(result.preReminderOffset, 15);
    });

    test('18. Repeat end date: "until end of semester"', () {
      final result = NlpService.parse('Exercise daily until end of semester');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatEndDate, isNotNull);
    });

    test('19. Repeat end date: "until 2026-12-31"', () {
      final result = NlpService.parse('Exercise daily until 2026-12-31');
      expect(result.repeatEndDate, isNotNull);
      expect(result.repeatEndDate!.year, 2026);
      expect(result.repeatEndDate!.month, 12);
      expect(result.repeatEndDate!.day, 31);
    });

    test('20. Custom repeat: "every 2 weeks"', () {
      final result = NlpService.parse('Check email every 2 weeks');
      expect(result.hasRepeat, isTrue);
      expect(result.repeatRule, 'every_2_weeks');
    });
  });
}
