import 'package:flutter/material.dart';

class GlassTheme {
  final String id;
  final String name;
  final String emoji;

  // Backgrounds
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color card;

  // Glass tint
  final Color glassTint;
  final double glassOpacity;

  // Glass border gradient
  final Color borderStart;
  final Color borderEnd;

  // Accent
  final Color accent;
  final Color accentLight;
  final Color secondary;
  final List<Color> accentGradient;

  // Neon orbs / Ambient mesh glow
  final List<Color> orbColors;
  final double orbOpacity;
  final Color primaryGlowColor;
  final Color accentGlowColor;

  // Glass border override
  final Color glassBorderColor;

  // Text/icon color used on accent surfaces (buttons, gradient bubbles)
  final Color onAccent;

  // Bundled video asset path
  final String? videoPath;

  /// Whether this theme uses detailed orb animations (Cyberpunk, Peaceful, PinkVibe).
  /// Minimalist themes (Dark OLED, Minimal Slate, Sunset) set this to false for performance.
  final bool hasDetailedOrbs;

  const GlassTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.card,
    required this.glassTint,
    required this.glassOpacity,
    required this.borderStart,
    required this.borderEnd,
    required this.accent,
    required this.accentLight,
    required this.secondary,
    required this.accentGradient,
    required this.orbColors,
    this.orbOpacity = 0.25,
    this.primaryGlowColor = const Color(0xFFFF9F0A),
    this.accentGlowColor = const Color(0xFFFFD60A),
    this.glassBorderColor = const Color(0x1AFFFFFF),
    this.onAccent = Colors.white,
    this.videoPath,
    this.hasDetailedOrbs = true,
  });

  // ===== PRESET GLOW PALETTES =====
  static const Color glowAmberGoldPrimary = Color(0xFFFF9F0A);
  static const Color glowAmberGoldAccent = Color(0xFFFFD60A);

  static const Color glowCyberCyanPrimary = Color(0xFF00F5D4);
  static const Color glowCyberCyanAccent = Color(0xFF00BBF9);

  static const Color glowNeonVioletPrimary = Color(0xFF7B2CBF);
  static const Color glowNeonVioletAccent = Color(0xFFE0AFA0);

  static const Color glowEmeraldFocusPrimary = Color(0xFF30D158);
  static const Color glowEmeraldFocusAccent = Color(0xFF34C759);

  static const Color glowSunsetCrimsonPrimary = Color(0xFFFF375F);
  static const Color glowSunsetCrimsonAccent = Color(0xFFFF7A00);

  // ===== 1. CITY (Neon Cyberpunk - Cyber Cyan Glow) =====
  static const city = GlassTheme(
    id: 'city',
    name: 'City',
    emoji: '\u{1F3D9}',
    background: Color(0xFF0B0E14),
    surface: Color(0xFF111827),
    surfaceLight: Color(0xFF1E293B),
    card: Color(0xFF111827),
    glassTint: Color(0xFF00F5FF),
    glassOpacity: 0.06,
    borderStart: Color(0xFF00F5FF),
    borderEnd: Color(0xFFFF007F),
    accent: Color(0xFF00F5FF),
    accentLight: Color(0xFF67F5FF),
    secondary: Color(0xFFFF007F),
    accentGradient: [Color(0xFF00F5FF), Color(0xFFFF007F)],
    orbColors: [Color(0xFF00F5FF), Color(0xFFFF007F)],
    orbOpacity: 0.20,
    primaryGlowColor: glowCyberCyanPrimary,
    accentGlowColor: glowCyberCyanAccent,
    glassBorderColor: Color(0x1A00F5FF),
    videoPath: 'assets/videos/city.mp4',
  );

  // ===== 2. PEACEFUL (Matrix Green - Emerald Focus Glow) =====
  static const peaceful = GlassTheme(
    id: 'peaceful',
    name: 'Peaceful',
    emoji: '\u{1F54A}',
    background: Color(0xFF000000),
    surface: Color(0xFF0A0F0A),
    surfaceLight: Color(0xFF112211),
    card: Color(0xFF0A0F0A),
    glassTint: Color(0xFF00FF66),
    glassOpacity: 0.05,
    borderStart: Color(0xFF00FF66),
    borderEnd: Color(0xFF003B00),
    accent: Color(0xFF00FF66),
    accentLight: Color(0xFF66FF99),
    secondary: Color(0xFF00CC52),
    accentGradient: [Color(0xFF00FF66), Color(0xFF00CC52)],
    orbColors: [Color(0xFF00FF66), Color(0xFF003B00)],
    orbOpacity: 0.18,
    primaryGlowColor: glowEmeraldFocusPrimary,
    accentGlowColor: glowEmeraldFocusAccent,
    glassBorderColor: Color(0x1A00FF66),
    onAccent: Color(0xFF1A1A1A),
    videoPath: 'assets/videos/yenbinh.mp4',
  );

  // ===== 3. PINKVIBE (Sunset Vaporwave - Neon Violet Glow) =====
  static const pinkVibe = GlassTheme(
    id: 'pink_vibe',
    name: 'PinkVibe',
    emoji: '\u{1F49C}',
    background: Color(0xFF120826),
    surface: Color(0xFF1A0E30),
    surfaceLight: Color(0xFF261845),
    card: Color(0xFF1A0E30),
    glassTint: Color(0xFFFF5E00),
    glassOpacity: 0.06,
    borderStart: Color(0xFFFF5E00),
    borderEnd: Color(0xFF8A2BE2),
    accent: Color(0xFFFF5E00),
    accentLight: Color(0xFFFF8C42),
    secondary: Color(0xFF8A2BE2),
    accentGradient: [Color(0xFFFF5E00), Color(0xFF8A2BE2)],
    orbColors: [Color(0xFFFF5E00), Color(0xFF8A2BE2)],
    orbOpacity: 0.22,
    primaryGlowColor: glowNeonVioletPrimary,
    accentGlowColor: glowNeonVioletAccent,
    glassBorderColor: Color(0x1AFF5E00),
    videoPath: 'assets/videos/pink_vibe.mp4',
  );

  // ===== 4. DARK OLED (Minimal Solid - Emerald / Mint Glow) =====
  static const darkOled = GlassTheme(
    id: 'dark_oled',
    name: 'Dark OLED',
    emoji: '\u{1F576}',
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceLight: Color(0xFF1A1A1A),
    card: Color(0xFF121212),
    glassTint: Color(0xFF38EF7D),
    glassOpacity: 0.03,
    borderStart: Color(0xFF38EF7D),
    borderEnd: Color(0xFF11998E),
    accent: Color(0xFF38EF7D),
    accentLight: Color(0xFF6BFF9E),
    secondary: Color(0xFF11998E),
    accentGradient: [Color(0xFF38EF7D), Color(0xFF11998E)],
    orbColors: [Color(0xFF38EF7D), Color(0xFF11998E)],
    orbOpacity: 0.15,
    primaryGlowColor: Color(0xFF38EF7D),
    accentGlowColor: Color(0xFF11998E),
    glassBorderColor: Color(0x1A38EF7D),
    onAccent: Color(0xFF000000),
    hasDetailedOrbs: false,
  );

  // ===== 5. MINIMAL SLATE (Slate Blue Glow) =====
  static const minimalSlate = GlassTheme(
    id: 'minimal_slate',
    name: 'Minimal Slate',
    emoji: '\u{1F30A}',
    background: Color(0xFF0B132B),
    surface: Color(0xFF1C2541),
    surfaceLight: Color(0xFF3A506B),
    card: Color(0xFF1C2541),
    glassTint: Color(0xFF3A86FF),
    glassOpacity: 0.04,
    borderStart: Color(0xFF3A86FF),
    borderEnd: Color(0xFF8338EC),
    accent: Color(0xFF3A86FF),
    accentLight: Color(0xFF6DA9FF),
    secondary: Color(0xFF8338EC),
    accentGradient: [Color(0xFF3A86FF), Color(0xFF8338EC)],
    orbColors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
    orbOpacity: 0.16,
    primaryGlowColor: Color(0xFF3A86FF),
    accentGlowColor: Color(0xFF8338EC),
    glassBorderColor: Color(0x1A3A86FF),
    hasDetailedOrbs: false,
  );

  // ===== 6. SUNSET GRADIENT (Amber Gold Glow) =====
  static const sunsetGradient = GlassTheme(
    id: 'sunset_gradient',
    name: 'Sunset Glow',
    emoji: '\u{1F305}',
    background: Color(0xFF0F0A06),
    surface: Color(0xFF1A1008),
    surfaceLight: Color(0xFF2D1810),
    card: Color(0xFF1A1008),
    glassTint: Color(0xFFFF9E00),
    glassOpacity: 0.04,
    borderStart: Color(0xFFFF9E00),
    borderEnd: Color(0xFFE85D04),
    accent: Color(0xFFFF9E00),
    accentLight: Color(0xFFFFB733),
    secondary: Color(0xFFE85D04),
    accentGradient: [Color(0xFFFF9E00), Color(0xFFE85D04)],
    orbColors: [Color(0xFFFF9E00), Color(0xFFE85D04)],
    orbOpacity: 0.18,
    primaryGlowColor: glowAmberGoldPrimary,
    accentGlowColor: glowAmberGoldAccent,
    glassBorderColor: Color(0x1AFF9E00),
    hasDetailedOrbs: false,
  );

  static const all = [city, peaceful, pinkVibe, darkOled, minimalSlate, sunsetGradient];

  static GlassTheme getById(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => city,
    );
  }
}
