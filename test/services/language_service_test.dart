import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_note/services/language_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageService', () {
    // ===== Init =====
    test('1. Default locale is Vietnamese', () async {
      final service = LanguageService();
      expect(service.currentLocale, const Locale('vi'));
    });

    test('2. init() loads saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      final service = LanguageService();
      await service.init();
      expect(service.currentLocale, const Locale('en'));
    });

    test('3. init() keeps default when no saved locale', () async {
      final service = LanguageService();
      await service.init();
      expect(service.currentLocale, const Locale('vi'));
    });

    test('4. init() ignores invalid locale codes', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'fr'});
      final service = LanguageService();
      await service.init();
      expect(service.currentLocale, const Locale('vi'));
    });

    // ===== changeLanguage =====
    test('5. changeLanguage switches to English', () async {
      final service = LanguageService();
      await service.changeLanguage('en');
      expect(service.currentLocale, const Locale('en'));
    });

    test('6. changeLanguage switches to Vietnamese', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      final service = LanguageService();
      await service.init();
      await service.changeLanguage('vi');
      expect(service.currentLocale, const Locale('vi'));
    });

    test('7. changeLanguage persists to SharedPreferences', () async {
      final service = LanguageService();
      await service.changeLanguage('en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_code'), 'en');
    });

    test('8. changeLanguage with same code is no-op', () async {
      final service = LanguageService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.changeLanguage('vi'); // same as default
      expect(notified, isFalse);
    });

    test('9. changeLanguage notifies listeners', () async {
      final service = LanguageService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.changeLanguage('en');
      expect(notified, isTrue);
    });

    // ===== toggleLanguage =====
    test('10. toggleLanguage switches from Vietnamese to English', () async {
      final service = LanguageService();
      await service.toggleLanguage();
      expect(service.currentLocale, const Locale('en'));
    });

    test('11. toggleLanguage switches from English to Vietnamese', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      final service = LanguageService();
      await service.init();
      await service.toggleLanguage();
      expect(service.currentLocale, const Locale('vi'));
    });

    test('12. toggleLanguage persists the change', () async {
      final service = LanguageService();
      await service.toggleLanguage();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_code'), 'en');
    });

    // ===== isVietnamese =====
    test('13. isVietnamese returns true for Vietnamese', () {
      final service = LanguageService();
      expect(service.isVietnamese, isTrue);
    });

    test('14. isVietnamese returns false for English', () async {
      final service = LanguageService();
      await service.changeLanguage('en');
      expect(service.isVietnamese, isFalse);
    });

    // ===== Multiple changes =====
    test('15. Multiple rapid changes work correctly', () async {
      final service = LanguageService();
      await service.toggleLanguage(); // en
      await service.toggleLanguage(); // vi
      await service.toggleLanguage(); // en
      expect(service.currentLocale, const Locale('en'));
    });

    test('16. Full cycle returns to default', () async {
      final service = LanguageService();
      await service.changeLanguage('en');
      await service.changeLanguage('vi');
      expect(service.currentLocale, const Locale('vi'));
    });

    test('17. Locale persists across multiple inits', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      final service1 = LanguageService();
      await service1.init();
      expect(service1.currentLocale, const Locale('en'));

      final service2 = LanguageService();
      await service2.init();
      expect(service2.currentLocale, const Locale('en'));
    });

    test('18. changeLanguage notifies multiple listeners', () async {
      final service = LanguageService();
      int count = 0;
      service.addListener(() => count++);
      service.addListener(() => count++);
      await service.changeLanguage('en');
      expect(count, 2);
    });

    test('19. init does not notify when loading default', () async {
      final service = LanguageService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.init();
      expect(notified, isFalse);
    });

    test('20. init notifies when loading non-default locale', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      final service = LanguageService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.init();
      expect(notified, isTrue);
    });
  });
}
