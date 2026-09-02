import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_theme.dart';

// Global theme reference — updated by ThemeService
GlassTheme _activeTheme = GlassTheme.cyberpunk;

// ===== COLORS =====
class AppColors {
  AppColors._();

  // — Dynamic backgrounds (read from active theme) —
  static Color get background => _activeTheme.background;
  static Color get surface => _activeTheme.surface;
  static Color get surfaceLight => _activeTheme.surfaceLight;
  static Color get card => _activeTheme.card;
  static Color get cardElevated => _activeTheme.surfaceLight;

  // — Cyber-Luxe Text Palette —
  static const Color textPrimary = Color(0xFFF8FAFC);   // Text Cream Main
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);     // Text Muted Silver
  static const Color textTertiary = Color(0xFF64748B);

  // — Dynamic accent (from active theme) —
  static Color get primary => _activeTheme.accent;
  static Color get primaryLight => _activeTheme.accentLight;
  static Color get primaryDark => _activeTheme.accent;
  static List<Color> get primaryGradient => _activeTheme.accentGradient;

  // — Cyber-Luxe Accent Colors —
  static const Color cyberBlueViolet = Color(0xFF6366F1);  // Primary actions
  static const Color magentaPink = Color(0xFFEC4899);      // Badges, notifications
  static const Color warmCreamGold = Color(0xFFF59E0B);    // Event dots, AI icons

  // — Categories —
  static const Color blue = Color(0xFF60A5FA);
  static const Color red = Color(0xFFEC4899);
  static const Color orange = Color(0xFFF59E0B);
  static const Color green = Color(0xFF34D399);
  static const Color purple = Color(0xFFA78BFA);
  static const Color teal = Color(0xFF2DD4BF);

  // — Semantic —
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFEC4899);
  static const Color warning = Color(0xFFF59E0B);

  // — Borders & Dividers —
  static Color get border => _activeTheme.surfaceLight;
  static Color get borderLight => _activeTheme.surfaceLight;
  static Color get divider => _activeTheme.surface;

  // — Misc —
  static Color get splash => _activeTheme.accent.withValues(alpha: 0.1);
  static const Color overlay = Color(0x80000000);
  static Color get shimmer => _activeTheme.surfaceLight;

  // — Glass effects —
  static Color get glassTint => _activeTheme.glassTint;
  static double get glassOpacity => _activeTheme.glassOpacity;
  static Color get glassBorderStart => _activeTheme.borderStart;
  static Color get glassBorderEnd => _activeTheme.borderEnd;

  // — Category color map —
  static const Map<String, Color> categoryColors = {
    'Class': blue,
    'Exam': red,
    'Assignment': orange,
    'Personal': green,
  };

  static const Map<String, Color> priorityColors = {
    'high': Color(0xFFEC4899),
    'medium': Color(0xFFF59E0B),
    'low': Color(0xFF34D399),
  };

  // Update the active theme
  static void setTheme(GlassTheme theme) {
    _activeTheme = theme;
  }
}

// ===== SPACING =====
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// ===== RADIUS =====
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}

// ===== SHADOWS (glow style for dark theme) =====
class AppShadow {
  AppShadow._();

  static List<BoxShadow> sm = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> md = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  // Colored glow shadows
  static List<BoxShadow> glowPrimary = [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: -4),
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> glowCategory(Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: -4),
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}

// ===== GRADIENTS =====
class AppGradient {
  AppGradient._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Color(0xFF181A2A), Color(0xFF1E2035)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient categoryGlow(Color color) => LinearGradient(
    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ===== THEME =====
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.background,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        contentTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey[500]);
        }),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: AppColors.divider, thickness: 1),

      // Text
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textMuted),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
