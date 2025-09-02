import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  indonesian('id', 'Bahasa Indonesia');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  
  LanguageService._();

  AppLanguage _currentLanguage = AppLanguage.english; // Default to English

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage.code);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => AppLanguage.english,
      );
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
    notifyListeners(); // Notify listeners about language change
  }

  List<AppLanguage> get availableLanguages => AppLanguage.values;
}
