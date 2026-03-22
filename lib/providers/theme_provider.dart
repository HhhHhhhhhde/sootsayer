import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, highSaturation }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppTheme _appTheme = AppTheme.light;
  bool _isInitialized = true;

  ThemeMode get themeMode => _themeMode;
  AppTheme get appTheme => _appTheme;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    final appThemeString = prefs.getString('appTheme') ?? 'light';
    
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );
    
    _appTheme = AppTheme.values.firstWhere(
      (e) => e.toString() == 'AppTheme.$appThemeString',
      orElse: () => AppTheme.light,
    );
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString().split('.').last);
  }

  Future<void> setAppTheme(AppTheme theme) async {
    _appTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTheme', theme.toString().split('.').last);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
