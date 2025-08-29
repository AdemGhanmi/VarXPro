import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  void changeLanguage(String newLanguage) {
    if (['en', 'fr', 'ar'].contains(newLanguage)) {
      _currentLanguage = newLanguage;
      notifyListeners();
    }
  }
}
