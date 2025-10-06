// lib/provider/langageprovider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const _kLangKey = 'app_language';

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLangKey);
      if (saved != null && ['en', 'fr', 'ar'].contains(saved) && saved != _currentLanguage) {
        _currentLanguage = saved;
        notifyListeners(); // reconstruit MaterialApp et toute l'UI
      }
    } catch (_) {}
  }

  Future<void> changeLanguage(String newLanguage) async {
    if (!['en', 'fr', 'ar'].contains(newLanguage)) return;
    if (newLanguage == _currentLanguage) return;

    _currentLanguage = newLanguage;
    notifyListeners(); // 🔥 MAJ immédiate de l’UI

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLangKey, newLanguage); // persistance
    } catch (_) {}
  }
}
