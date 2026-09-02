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

  // Neon orbs (background glow effects)
  final List<Color> orbColors;
  final double orbOpacity;

  // Glass border override
  final Color glassBorderColor;

  // Text/icon color used on accent surfaces (buttons, gradient bubbles)
  final Color onAccent;

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
    this.glassBorderColor = const Color(0x1AFFFFFF),
    this.onAccent = Colors.white,
  });

  // ===== 1. NEON CYBERPUNK (Default) =====
  static const cyberpunk = GlassTheme(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    emoji: '\u{26A1}',
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
    glassBorderColor: Color(0x1A00F5FF),
  );

  // ===== 2. MATRIX HACKER GREEN =====
  static const matrix = GlassTheme(
    id: 'matrix',
    name: 'Matrix',
    emoji: '\u{1F4BB}',
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
    glassBorderColor: Color(0x1A00FF66),
    onAccent: Color(0xFF1A1A1A),
  );

  // ===== 3. OUTRUN SUNSET VAPORWAVE =====
  static const outrun = GlassTheme(
    id: 'outrun',
    name: 'Outrun',
    emoji: '\u{1F305}',
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
    glassBorderColor: Color(0x1AFF5E00),
  );

  static const all = [cyberpunk, matrix, outrun];

  static GlassTheme getById(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => cyberpunk,
    );
  }
}
