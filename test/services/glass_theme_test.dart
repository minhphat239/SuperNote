import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/core/theme/glass_theme.dart';

void main() {
  group('GlassTheme', () {
    test('1. GlassTheme.all has 6 themes', () {
      expect(GlassTheme.all.length, 6);
    });

    test('2. Each theme has a unique id', () {
      final ids = GlassTheme.all.map((t) => t.id).toSet();
      expect(ids.length, 6);
    });

    test('3. Each theme has a non-empty name', () {
      for (final theme in GlassTheme.all) {
        expect(theme.name.isNotEmpty, isTrue);
      }
    });

    test('4. Each theme has a non-empty emoji', () {
      for (final theme in GlassTheme.all) {
        expect(theme.emoji.isNotEmpty, isTrue);
      }
    });

    test('5. City theme has videoPath', () {
      expect(GlassTheme.city.videoPath, isNotNull);
      expect(GlassTheme.city.videoPath, contains('.mp4'));
    });

    test('6. Dark OLED has hasDetailedOrbs false', () {
      expect(GlassTheme.darkOled.hasDetailedOrbs, isFalse);
    });

    test('7. Minimal Slate has hasDetailedOrbs false', () {
      expect(GlassTheme.minimalSlate.hasDetailedOrbs, isFalse);
    });

    test('8. Sunset Gradient has hasDetailedOrbs false', () {
      expect(GlassTheme.sunsetGradient.hasDetailedOrbs, isFalse);
    });

    test('9. City has hasDetailedOrbs true (default)', () {
      expect(GlassTheme.city.hasDetailedOrbs, isTrue);
    });

    test('10. GlassTheme.getById returns city for unknown id', () {
      expect(GlassTheme.getById('xxx').id, 'city');
    });

    test('11. All themes have non-null accent colors', () {
      for (final theme in GlassTheme.all) {
        expect(theme.accent, isNotNull);
        expect(theme.secondary, isNotNull);
      }
    });

    test('12. All themes have accentGradient with 2 colors', () {
      for (final theme in GlassTheme.all) {
        expect(theme.accentGradient.length, 2);
      }
    });

    test('13. All themes have orbColors with 2 colors', () {
      for (final theme in GlassTheme.all) {
        expect(theme.orbColors.length, 2);
      }
    });

    test('14. All themes have glassOpacity between 0 and 1', () {
      for (final theme in GlassTheme.all) {
        expect(theme.glassOpacity, greaterThanOrEqualTo(0.0));
        expect(theme.glassOpacity, lessThanOrEqualTo(1.0));
      }
    });

    test('15. All themes have orbOpacity between 0 and 1', () {
      for (final theme in GlassTheme.all) {
        expect(theme.orbOpacity, greaterThanOrEqualTo(0.0));
        expect(theme.orbOpacity, lessThanOrEqualTo(1.0));
      }
    });

    test('16. All themes have unique ids', () {
      final ids = GlassTheme.all.map((t) => t.id).toSet();
      expect(ids.length, 6);
    });

    test('17. Peaceful theme uses onAccent for dark text', () {
      expect(GlassTheme.peaceful.onAccent, const Color(0xFF1A1A1A));
    });

    test('18. Dark OLED theme uses onAccent for dark text', () {
      expect(GlassTheme.darkOled.onAccent, const Color(0xFF000000));
    });

    test('19. GlassTheme.getById for each known id', () {
      expect(GlassTheme.getById('city').id, 'city');
      expect(GlassTheme.getById('peaceful').id, 'peaceful');
      expect(GlassTheme.getById('pink_vibe').id, 'pink_vibe');
      expect(GlassTheme.getById('dark_oled').id, 'dark_oled');
      expect(GlassTheme.getById('minimal_slate').id, 'minimal_slate');
      expect(GlassTheme.getById('sunset_gradient').id, 'sunset_gradient');
    });

    test('20. All themes have glassBorderColor', () {
      for (final theme in GlassTheme.all) {
        expect(theme.glassBorderColor, isNotNull);
      }
    });
  });
}
