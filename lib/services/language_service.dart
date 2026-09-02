import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _key = 'language_code';
  static const Locale _defaultLocale = Locale('vi');

  Locale _currentLocale = _defaultLocale;

  Locale get currentLocale => _currentLocale;

  bool get isVietnamese => _currentLocale.languageCode == 'vi';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_key);
    if (langCode != null && (langCode == 'vi' || langCode == 'en')) {
      _currentLocale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (_currentLocale.languageCode == langCode) return;
    _currentLocale = Locale(langCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
  }

  Future<void> toggleLanguage() async {
    final newCode = isVietnamese ? 'en' : 'vi';
    await changeLanguage(newCode);
  }
}
