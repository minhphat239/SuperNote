import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/glass_theme.dart';
import '../core/theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _key = 'app_theme_mode';
  static const String _keyDetailedBg = 'detailed_background';
  GlassTheme _current = GlassTheme.city;
  bool _detailedBackground = true;
  final _themeStreamController = StreamController<GlassTheme>.broadcast();

  GlassTheme get current => _current;
  bool get detailedBackground => _detailedBackground;
  Stream<GlassTheme> get themeChanges => _themeStreamController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _current = GlassTheme.getById(saved);
    }
    _detailedBackground = prefs.getBool(_keyDetailedBg) ?? true;
    AppColors.setTheme(_current);
    _themeStreamController.add(_current);
    notifyListeners();
  }

  Future<void> setTheme(String themeId) async {
    final theme = GlassTheme.getById(themeId);
    if (theme.id == _current.id) return;

    _current = theme;
    AppColors.setTheme(_current);
    _themeStreamController.add(_current);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeId);
  }

  Future<void> toggleDetailedBackground(bool enabled) async {
    _detailedBackground = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDetailedBg, enabled);
  }

  @override
  void dispose() {
    _themeStreamController.close();
    super.dispose();
  }
}
