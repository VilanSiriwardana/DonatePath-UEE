import 'package:flutter/material.dart';

class LanguageNotifier extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  void changeLanguage(String newLanguage) {
    _currentLanguage = newLanguage;
    notifyListeners();
  }
}
