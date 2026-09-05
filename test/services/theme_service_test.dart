import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_note/services/theme_service.dart';
import 'package:super_note/core/theme/glass_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeService', () {
    // ===== Init =====
    test('1. Default theme is city', () {
      final service = ThemeService();
      expect(service.current.id, 'city');
    });

    test('2. init() loads saved theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'peaceful'});
      final service = ThemeService();
      await service.init();
      expect(service.current.id, 'peaceful');
    });

    test('3. init() defaults to city when no saved theme', () async {
      final service = ThemeService();
      await service.init();
      expect(service.current.id, 'city');
    });

    test('4. detailedBackground defaults to true', () {
      final service = ThemeService();
      expect(service.detailedBackground, isTrue);
    });

    test('5. init() loads saved detailedBackground', () async {
      SharedPreferences.setMockInitialValues({'detailed_background': false});
      final service = ThemeService();
      await service.init();
      expect(service.detailedBackground, isFalse);
    });

    // ===== setTheme =====
    test('6. setTheme changes current theme', () async {
      final service = ThemeService();
      await service.setTheme('peaceful');
      expect(service.current.id, 'peaceful');
    });

    test('7. setTheme persists to SharedPreferences', () async {
      final service = ThemeService();
      await service.setTheme('pink_vibe');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'pink_vibe');
    });

    test('8. setTheme with same id is no-op', () async {
      final service = ThemeService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.setTheme('city');
      expect(notified, isFalse);
    });

    test('9. setTheme notifies listeners', () async {
      final service = ThemeService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.setTheme('dark_oled');
      expect(notified, isTrue);
    });

    test('10. setTheme with unknown id defaults to city', () async {
      final service = ThemeService();
      await service.setTheme('nonexistent');
      expect(service.current.id, 'city');
    });

    // ===== toggleDetailedBackground =====
    test('11. toggleDetailedBackground changes value', () async {
      final service = ThemeService();
      await service.toggleDetailedBackground(false);
      expect(service.detailedBackground, isFalse);
    });

    test('12. toggleDetailedBackground persists', () async {
      final service = ThemeService();
      await service.toggleDetailedBackground(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('detailed_background'), false);
    });

    test('13. toggleDetailedBackground notifies listeners', () async {
      final service = ThemeService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.toggleDetailedBackground(false);
      expect(notified, isTrue);
    });

    // ===== themeChanges stream =====
    test('14. themeChanges emits on setTheme', () async {
      final service = ThemeService();
      final events = <GlassTheme>[];
      service.themeChanges.listen(events.add);
      await service.setTheme('peaceful');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.last.id, 'peaceful');
    });

    test('15. themeChanges emits on init', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'pink_vibe'});
      final service = ThemeService();
      final events = <GlassTheme>[];
      service.themeChanges.listen(events.add);
      await service.init();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.last.id, 'pink_vibe');
    });

    // ===== Multiple themes =====
    test('16. Can switch between all 6 themes', () async {
      final service = ThemeService();
      for (final theme in GlassTheme.all) {
        await service.setTheme(theme.id);
        expect(service.current.id, theme.id);
      }
    });

    test('17. GlassTheme.all has 6 themes', () {
      expect(GlassTheme.all.length, 6);
    });

    test('18. GlassTheme.getById returns correct theme', () {
      expect(GlassTheme.getById('city').name, 'City');
      expect(GlassTheme.getById('peaceful').name, 'Peaceful');
      expect(GlassTheme.getById('pink_vibe').name, 'PinkVibe');
      expect(GlassTheme.getById('dark_oled').name, 'Dark OLED');
      expect(GlassTheme.getById('minimal_slate').name, 'Minimal Slate');
      expect(GlassTheme.getById('sunset_gradient').name, 'Sunset Glow');
    });

    test('19. GlassTheme.getById defaults to city for unknown id', () {
      expect(GlassTheme.getById('unknown').id, 'city');
    });

    test('20. Theme persistence across multiple inits', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark_oled'});
      final s1 = ThemeService();
      await s1.init();
      expect(s1.current.id, 'dark_oled');

      final s2 = ThemeService();
      await s2.init();
      expect(s2.current.id, 'dark_oled');
    });
  });
}
