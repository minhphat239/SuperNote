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
  final List<Color> accentGradient;

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
    required this.accentGradient,
  });

  // ===== CYBERPUNK CYAN =====
  static const cyberpunk = GlassTheme(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    emoji: '\u{1F30A}',
    background: Color(0xFF0B0F17),
    surface: Color(0xFF111827),
    surfaceLight: Color(0xFF1E293B),
    card: Color(0xFF111827),
    glassTint: Color(0xFF6366F1),
    glassOpacity: 0.08,
    borderStart: Color(0xFF6366F1),
    borderEnd: Color(0xFFEC4899),
    accent: Color(0xFF6366F1),
    accentLight: Color(0xFF818CF8),
    accentGradient: [Color(0xFF6366F1), Color(0xFFEC4899)],
  );

  // ===== OBSIDIAN GOLD =====
  static const gold = GlassTheme(
    id: 'gold',
    name: 'B\u1EA3n Pro',
    emoji: '\u{1F451}',
    background: Color(0xFF0B0F17),
    surface: Color(0xFF141420),
    surfaceLight: Color(0xFF1E1E30),
    card: Color(0xFF141420),
    glassTint: Color(0xFFF59E0B),
    glassOpacity: 0.10,
    borderStart: Color(0xFFF59E0B),
    borderEnd: Color(0xFFD97706),
    accent: Color(0xFFF59E0B),
    accentLight: Color(0xFFFBBF24),
    accentGradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  // ===== MINT SUNSET =====
  static const mint = GlassTheme(
    id: 'mint',
    name: 'Mint D\uECBCh M\u1EAFt',
    emoji: '\u{1F343}',
    background: Color(0xFF0B0F17),
    surface: Color(0xFF0F1A20),
    surfaceLight: Color(0xFF162A30),
    card: Color(0xFF0F1A20),
    glassTint: Color(0xFF2DD4BF),
    glassOpacity: 0.07,
    borderStart: Color(0xFF2DD4BF),
    borderEnd: Color(0xFF34D399),
    accent: Color(0xFF2DD4BF),
    accentLight: Color(0xFF5EEAD4),
    accentGradient: [Color(0xFF2DD4BF), Color(0xFF34D399)],
  );

  static const all = [cyberpunk, gold, mint];

  static GlassTheme getById(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => cyberpunk,
    );
  }
}
