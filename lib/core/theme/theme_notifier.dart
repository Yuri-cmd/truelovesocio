import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const String _themeKey = 'themeMode'; // Usando la misma llave que ya tiene socio
  
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            value = ThemeMode.light;
            break;
          case 'dark':
            value = ThemeMode.dark;
            break;
          case 'system':
          default:
            value = ThemeMode.system;
            break;
        }
      }
    } catch (e) {
      value = ThemeMode.system;
    }
  }

  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (theme) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
    }
  }

  void setTheme(ThemeMode theme) {
    value = theme;
    _saveTheme(theme);
  }

  void toggleTheme() {
    final newTheme = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(newTheme);
  }
}
