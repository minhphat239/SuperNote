import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/glass_theme.dart';
import '../core/theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _key = 'app_theme_mode';
  GlassTheme _current = GlassTheme.cyberpunk;
  final _themeStreamController = StreamController<GlassTheme>.broadcast();

  GlassTheme get current => _current;
  Stream<GlassTheme> get themeChanges => _themeStreamController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _current = GlassTheme.getById(saved);
    }
    // Sync AppColors with current theme
    AppColors.setTheme(_current);
    _themeStreamController.add(_current);
    notifyListeners();
  }

  Future<void> setTheme(String themeId) async {
    final theme = GlassTheme.getById(themeId);
    if (theme.id == _current.id) return;

    _current = theme;
    // Sync AppColors with new theme — all widgets using AppColors will rebuild
    AppColors.setTheme(_current);
    _themeStreamController.add(_current);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeId);
  }

  @override
  void dispose() {
    _themeStreamController.close();
    super.dispose();
  }
}
