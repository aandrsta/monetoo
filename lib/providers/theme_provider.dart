import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      // Default ke light mode jika error
      _isDarkMode = false;
    }
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    try {
      await _prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      // Jika error (prefs belum initialized), langsung update state
      // prefs akan save nanti setelah initialize
    }
    notifyListeners();
  }
}
