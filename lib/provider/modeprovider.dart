import 'package:flutter/material.dart';

class ModeProvider extends ChangeNotifier {
  int _currentMode = 1;
  int get currentMode => _currentMode;

  void changeMode(int newMode) {
    if (newMode >= 1 && newMode <= 5) {
      _currentMode = newMode;
      notifyListeners();
    }
  }
}
