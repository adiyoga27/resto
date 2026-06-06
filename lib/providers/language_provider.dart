import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('id');

  Locale get locale => _locale;
  bool get isIndonesian => _locale.languageCode == 'id';

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'id'
        ? const Locale('en')
        : const Locale('id');
    notifyListeners();
  }
}
