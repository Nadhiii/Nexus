import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadPreferences();
  }

  void toggleTheme() {
    // Kept for source compatibility with older callers; appearance is intentionally dark-only.
  }

  Future<void> _loadPreferences() async {
    await SharedPreferences.getInstance();
    // Nexus uses one appearance: dark mode. Ignore any legacy light/system preference.
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }
}
