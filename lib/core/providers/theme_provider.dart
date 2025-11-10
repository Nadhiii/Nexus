import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _materialYouKey = 'material_you';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterialYou = true;
  
  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  
  ThemeProvider() {
    _loadPreferences();
  }
  
  void toggleTheme(bool useMaterialYou) {
    _useMaterialYou = useMaterialYou;
    _savePreferences();
    notifyListeners();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _useMaterialYou = prefs.getBool(_materialYouKey) ?? true;
    final themeModeIndex = prefs.getInt(_themeKey) ?? 0; // Default to system
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }
  
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_materialYouKey, _useMaterialYou);
    await prefs.setInt(_themeKey, _themeMode.index);
  }
}
