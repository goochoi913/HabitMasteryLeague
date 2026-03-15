import 'package:flutter/material.dart';
import '../utils/prefs_helper.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDark = PrefsHelper.getDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await PrefsHelper.setDarkMode(_isDark);
    notifyListeners();
  }
}