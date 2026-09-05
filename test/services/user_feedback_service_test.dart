import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_note/services/user_feedback_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserFeedbackService', () {
    // ===== Singleton =====
    test('1. UserFeedbackService is singleton', () {
      final s1 = UserFeedbackService();
      final s2 = UserFeedbackService();
      expect(identical(s1, s2), isTrue);
    });

    // ===== URL management =====
    test('2. getFeedbackUrl returns null when not set', () async {
      final service = UserFeedbackService();
      final url = await service.getFeedbackUrl();
      expect(url, isNull);
    });

    test('3. setFeedbackUrl saves URL', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://script.google.com/abc');
      final url = await service.getFeedbackUrl();
      expect(url, 'https://script.google.com/abc');
    });

    test('4. setFeedbackUrl overwrites previous URL', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://old.com');
      await service.setFeedbackUrl('https://new.com');
      final url = await service.getFeedbackUrl();
      expect(url, 'https://new.com');
    });

    // ===== FeedbackResult =====
    test('5. FeedbackResult holds success and message', () {
      final result = FeedbackResult(success: true, message: 'OK');
      expect(result.success, isTrue);
      expect(result.message, 'OK');
    });

    test('6. FeedbackResult failure', () {
      final result = FeedbackResult(success: false, message: 'Error');
      expect(result.success, isFalse);
      expect(result.message, 'Error');
    });

    // ===== Validation =====
    test('7. submitFeedback rejects empty message', () async {
      final service = UserFeedbackService();
      final result = await service.submitFeedback('');
      expect(result.success, isFalse);
      expect(result.message, contains('empty'));
    });

    test('8. submitFeedback rejects whitespace-only message', () async {
      final service = UserFeedbackService();
      final result = await service.submitFeedback('   ');
      expect(result.success, isFalse);
      expect(result.message, contains('empty'));
    });

    test('9. submitFeedback rejects when URL not configured', () async {
      final service = UserFeedbackService();
      final result = await service.submitFeedback('Hello');
      expect(result.success, isFalse);
      expect(result.message, contains('URL not configured'));
    });

    // ===== Cooldown =====
    test('10. First submit is allowed', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://httpbin.org/post');
      // This will fail with network error, but won't hit cooldown
      final result = await service.submitFeedback('Test');
      // Network will fail on test, but it won't say "cooldown"
      expect(result.message, isNot(contains('wait')));
    });

    test('11. Second submit within cooldown is rejected', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://httpbin.org/post');
      // Simulate a recent submit by setting the last time
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('feedback_last_time', now);

      final result = await service.submitFeedback('Test');
      expect(result.success, isFalse);
      expect(result.message, contains('wait'));
    });

    test('12. Submit after cooldown is allowed', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://httpbin.org/post');
      final prefs = await SharedPreferences.getInstance();
      final old = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 120;
      await prefs.setInt('feedback_last_time', old);

      // Won't hit cooldown check
      final result = await service.submitFeedback('Test');
      expect(result.message, isNot(contains('wait')));
    });

    // ===== Edge cases =====
    test('13. getFeedbackUrl returns saved empty string as empty', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('');
      final url = await service.getFeedbackUrl();
      expect(url, '');
    });

    test('14. Cooldown check uses seconds precision', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://test.com');
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('feedback_last_time', now - 59); // 59 sec ago
      final result = await service.submitFeedback('Test');
      expect(result.message, contains('wait')); // still in cooldown
    });

    test('15. Cooldown allows after exactly 60 seconds', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://test.com');
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('feedback_last_time', now - 60);
      final result = await service.submitFeedback('Test');
      expect(result.message, isNot(contains('wait')));
    });

    test('16. Multiple rapid setFeedbackUrl calls work', () async {
      final service = UserFeedbackService();
      for (var i = 0; i < 10; i++) {
        await service.setFeedbackUrl('https://url$i.com');
      }
      final url = await service.getFeedbackUrl();
      expect(url, 'https://url9.com');
    });

    test('17. Cooldown persistence across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt('feedback_last_time', now);

      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://test.com');
      final result = await service.submitFeedback('Test');
      expect(result.message, contains('wait'));
    });

    test('18. URL persistence across instances', () async {
      final s1 = UserFeedbackService();
      await s1.setFeedbackUrl('https://persistent.com');

      final s2 = UserFeedbackService();
      final url = await s2.getFeedbackUrl();
      expect(url, 'https://persistent.com');
    });

    test('19. submitFeedback with very long message', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://test.com');
      final longMsg = 'A' * 5000;
      final result = await service.submitFeedback(longMsg);
      // Will fail network but not crash
      expect(result.success, isFalse);
    });

    test('20. submitFeedback trims message', () async {
      final service = UserFeedbackService();
      await service.setFeedbackUrl('https://test.com');
      // Whitespace only → should be rejected as empty
      final result = await service.submitFeedback('  \n\t  ');
      expect(result.success, isFalse);
    });
  });
}
