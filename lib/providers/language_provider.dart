import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  List<Locale> get supportedLocales => const [
        Locale('en', 'US'),
        Locale('lg', 'UG'),
      ];

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    if (_context != null) {
      changeLocale(_context!, languageCode);
    }
    notifyListeners();
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'lg':
        return 'Luganda';
      default:
        return 'English';
    }
  }
}
