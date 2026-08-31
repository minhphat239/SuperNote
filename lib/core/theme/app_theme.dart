import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== COLORS =====
class AppColors {
  AppColors._();

  // — Backgrounds —
  static const Color background = Color(0xFF0E0F1A);
  static const Color surface = Color(0xFF181A2A);
  static const Color surfaceLight = Color(0xFF1E2035);
  static const Color card = Color(0xFF181A2A);
  static const Color cardElevated = Color(0xFF1E2035);

  // — Text —
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFFB0B3C5);
  static const Color textMuted = Color(0xFF8B8FA3);
  static const Color textTertiary = Color(0xFF6B7094);

  // — Accent gradient —
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF5A4BD1);
  static const List<Color> primaryGradient = [Color(0xFF6C5CE7), Color(0xFFA29BFE)];

  // — Categories (saturated for dark bg) —
  static const Color blue = Color(0xFF4FC3F7);     // Class — electric blue
  static const Color red = Color(0xFFFF5C8A);       // Exam — hot pink
  static const Color orange = Color(0xFFFFB74D);     // Assignment — amber
  static const Color green = Color(0xFF69F0AE);      // Personal — mint green
  static const Color purple = Color(0xFFCE93D8);
  static const Color teal = Color(0xFF4DD0E1);

  // — Semantic —
  static const Color success = Color(0xFF69F0AE);
  static const Color error = Color(0xFFFF5C8A);
  static const Color warning = Color(0xFFFFB74D);

  // — Borders & Dividers —
  static const Color border = Color(0xFF2A2D42);
  static const Color borderLight = Color(0xFF353850);
  static const Color divider = Color(0xFF1E2035);

  // — Misc —
  static const Color splash = Color(0x1A6C5CE7);
  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0xFF1E2035);

  // — Category color map —
  static const Map<String, Color> categoryColors = {
    'Class': blue,
    'Exam': red,
    'Assignment': orange,
    'Personal': green,
  };

  static const Map<String, Color> priorityColors = {
    'high': Color(0xFFFF5C8A),
    'medium': Color(0xFFFFB74D),
    'low': Color(0xFF69F0AE),
  };
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
    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> md = [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  // Colored glow shadows
  static List<BoxShadow> glowPrimary = [
    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: -4),
    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> glowCategory(Color color) => [
    BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, spreadRadius: -4),
    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}

// ===== GRADIENTS =====
class AppGradient {
  AppGradient._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Color(0xFF181A2A), Color(0xFF1E2035)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient categoryGlow(Color color) => LinearGradient(
    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
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
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
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
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
        titleTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        contentTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey[500]);
        }),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),

      // Text
      textTheme: const TextTheme(
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
