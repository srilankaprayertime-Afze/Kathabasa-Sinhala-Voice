import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'isDarkMode';
  ThemeMode _themeMode = ThemeMode.light; // User explicitly wants original blue default

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    const storage = FlutterSecureStorage();
    final isDarkStr = await storage.read(key: _themePrefKey);
    final isDark = isDarkStr == 'true';
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    const storage = FlutterSecureStorage();
    await storage.write(key: _themePrefKey, value: isDark.toString());
    notifyListeners();
  }
}
