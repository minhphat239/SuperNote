import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_note/services/theme_service.dart';
import 'package:super_note/services/language_service.dart';
import 'package:super_note/services/user_feedback_service.dart';
import 'package:super_note/core/theme/glass_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tab Settings — Persistence & State', () {
    // ===== Theme persistence =====
    test('1. Theme change persists across app restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final s1 = ThemeService();
      await s1.setTheme('dark_oled');
      expect(s1.current.id, 'dark_oled');

      // Simulate app restart
      final s2 = ThemeService();
      await s2.init();
      expect(s2.current.id, 'dark_oled');
    });

    test('2. Theme persists after multiple changes (final state)', () async {
      final s = ThemeService();
      await s.setTheme('peaceful');
      await s.setTheme('pink_vibe');
      await s.setTheme('sunset_gradient');

      final s2 = ThemeService();
      await s2.init();
      expect(s2.current.id, 'sunset_gradient');
    });

    test('3. Detailed background toggle persists', () async {
      final s = ThemeService();
      await s.toggleDetailedBackground(false);

      final s2 = ThemeService();
      await s2.init();
      expect(s2.detailedBackground, isFalse);
    });

    test('4. Theme + detailed background independent persistence', () async {
      final s = ThemeService();
      await s.setTheme('peaceful');
      await s.toggleDetailedBackground(false);

      final s2 = ThemeService();
      await s2.init();
      expect(s2.current.id, 'peaceful');
      expect(s2.detailedBackground, isFalse);
    });

    test('5. Default theme when no saved value', () async {
      final s = ThemeService();
      await s.init();
      expect(s.current.id, 'city');
    });

    // ===== Language persistence =====
    test('6. Language change persists across app restarts', () async {
      final s1 = LanguageService();
      await s1.changeLanguage('en');
      expect(s1.isVietnamese, isFalse);

      final s2 = LanguageService();
      await s2.init();
      expect(s2.isVietnamese, isFalse);
    });

    test('7. Language toggle persists', () async {
      final s = LanguageService();
      await s.toggleLanguage(); // vi → en
      final s2 = LanguageService();
      await s2.init();
      expect(s2.currentLocale.languageCode, 'en');
    });

    test('8. Default language is Vietnamese', () async {
      final s = LanguageService();
      await s.init();
      expect(s.isVietnamese, isTrue);
    });

    test('9. Invalid language code in prefs keeps default', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'fr'});
      final s = LanguageService();
      await s.init();
      expect(s.currentLocale.languageCode, 'vi');
    });

    // ===== Feedback URL persistence =====
    test('10. Feedback URL persists across instances', () async {
      final s1 = UserFeedbackService();
      await s1.setFeedbackUrl('https://script.google.com/abc');

      final s2 = UserFeedbackService();
      final url = await s2.getFeedbackUrl();
      expect(url, 'https://script.google.com/abc');
    });

    test('11. Feedback URL overwrite persists', () async {
      final s = UserFeedbackService();
      await s.setFeedbackUrl('https://old.com');
      await s.setFeedbackUrl('https://new.com');

      final s2 = UserFeedbackService();
      final url = await s2.getFeedbackUrl();
      expect(url, 'https://new.com');
    });

    test('12. Feedback URL null when not set', () async {
      final s = UserFeedbackService();
      final url = await s.getFeedbackUrl();
      expect(url, isNull);
    });

    // ===== Cross-service state =====
    test('13. Theme and language persist independently', () async {
      final theme = ThemeService();
      final lang = LanguageService();
      await theme.setTheme('pink_vibe');
      await lang.changeLanguage('en');

      final theme2 = ThemeService();
      final lang2 = LanguageService();
      await theme2.init();
      await lang2.init();
      expect(theme2.current.id, 'pink_vibe');
      expect(lang2.isVietnamese, isFalse);
    });

    test('14. Theme change does not affect language', () async {
      final lang = LanguageService();
      await lang.changeLanguage('en');

      final theme = ThemeService();
      await theme.setTheme('dark_oled');

      final lang2 = LanguageService();
      await lang2.init();
      expect(lang2.isVietnamese, isFalse); // still English
    });

    // ===== Notification-like settings =====
    test('15. Pre-reminder default persists via SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('default_pre_reminder', 30);

      final saved = prefs.getInt('default_pre_reminder');
      expect(saved, 30);
    });

    test('16. Quiet hours persist via SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quiet_start_hour', 22);
      await prefs.setInt('quiet_end_hour', 7);

      expect(prefs.getInt('quiet_start_hour'), 22);
      expect(prefs.getInt('quiet_end_hour'), 7);
    });

    test('17. Sound/haptic toggle persists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('feedback_sound', false);
      await prefs.setBool('feedback_haptic', false);

      expect(prefs.getBool('feedback_sound'), false);
      expect(prefs.getBool('feedback_haptic'), false);
    });

    // ===== Edge cases =====
    test('18. Setting same theme twice is no-op (no notification)', () async {
      final s = ThemeService();
      var notified = 0;
      s.addListener(() => notified++);
      await s.setTheme('city'); // same as default
      expect(notified, 0);
    });

    test('19. Setting same language is no-op', () async {
      final s = LanguageService();
      var notified = 0;
      s.addListener(() => notified++);
      await s.changeLanguage('vi'); // same as default
      expect(notified, 0);
    });

    test('20. SharedPreferences empty → all defaults', () async {
      final theme = ThemeService();
      final lang = LanguageService();
      await theme.init();
      await lang.init();
      expect(theme.current.id, 'city');
      expect(theme.detailedBackground, true);
      expect(lang.isVietnamese, isTrue);
    });
  });
}
