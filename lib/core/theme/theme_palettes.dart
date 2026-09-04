import 'package:flutter/material.dart';

class ThemePalette {
  final String id;
  final String name;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color buttonBackground;
  final Color buttonText;
  final Color tabActiveBg;
  final Color tabActiveText;
  final Color tabInactiveText;
  final Color cardBackground;
  final Color cardBorder;

  const ThemePalette({
    required this.id,
    required this.name,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.buttonBackground,
    required this.buttonText,
    required this.tabActiveBg,
    required this.tabActiveText,
    required this.tabInactiveText,
    required this.cardBackground,
    required this.cardBorder,
  });
}

class ThemePalettes {
  ThemePalettes._();

  static const cyberpunk = ThemePalette(
    id: 'city',
    name: 'Cyberpunk City',
    primaryAccent: Color(0xFF00F5D4),
    secondaryAccent: Color(0xFF7B2CBF),
    buttonBackground: Color(0xFF1A1423),
    buttonText: Color(0xFFFFFFFF),
    tabActiveBg: Color(0x3300F5D4),
    tabActiveText: Color(0xFF00F5D4),
    tabInactiveText: Color(0xFFA0AAB2),
    cardBackground: Color(0xD9141821),
    cardBorder: Color(0x4000F5D4),
  );

  static const darkOled = ThemePalette(
    id: 'dark_oled',
    name: 'Dark OLED',
    primaryAccent: Color(0xFF38EF7D),
    secondaryAccent: Color(0xFF11998E),
    buttonBackground: Color(0xFF1F1F1F),
    buttonText: Color(0xFFFFFFFF),
    tabActiveBg: Color(0xFF38EF7D),
    tabActiveText: Color(0xFF000000),
    tabInactiveText: Color(0xFF888888),
    cardBackground: Color(0xFF121212),
    cardBorder: Color(0xFF282828),
  );

  static const minimalSlate = ThemePalette(
    id: 'minimal_slate',
    name: 'Minimal Slate',
    primaryAccent: Color(0xFF3A86FF),
    secondaryAccent: Color(0xFF8338EC),
    buttonBackground: Color(0xFF2B2D42),
    buttonText: Color(0xFFFFFFFF),
    tabActiveBg: Color(0xFF3A86FF),
    tabActiveText: Color(0xFFFFFFFF),
    tabInactiveText: Color(0xFF8D99AE),
    cardBackground: Color(0xE62B2D42),
    cardBorder: Color(0x4D8D99AE),
  );

  static const pinkVibe = ThemePalette(
    id: 'pink_vibe',
    name: 'Pink Vibe',
    primaryAccent: Color(0xFFFF007F),
    secondaryAccent: Color(0xFFFF5400),
    buttonBackground: Color(0xFF2A0820),
    buttonText: Color(0xFFFFFFFF),
    tabActiveBg: Color(0x40FF007F),
    tabActiveText: Color(0xFFFF70A6),
    tabInactiveText: Color(0xFFC77DFF),
    cardBackground: Color(0xD9230F1E),
    cardBorder: Color(0x4DFF007F),
  );

  static const sunsetGradient = ThemePalette(
    id: 'sunset_gradient',
    name: 'Sunset Glow',
    primaryAccent: Color(0xFFFF9E00),
    secondaryAccent: Color(0xFFE85D04),
    buttonBackground: Color(0xFF370617),
    buttonText: Color(0xFFFFFFFF),
    tabActiveBg: Color(0xFFFF9E00),
    tabActiveText: Color(0xFF000000),
    tabInactiveText: Color(0xFFDC2F02),
    cardBackground: Color(0xD91E0A14),
    cardBorder: Color(0x4DFF9E00),
  );

  static const all = [cyberpunk, darkOled, minimalSlate, pinkVibe, sunsetGradient];

  static ThemePalette getById(String id) {
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => cyberpunk,
    );
  }
}
