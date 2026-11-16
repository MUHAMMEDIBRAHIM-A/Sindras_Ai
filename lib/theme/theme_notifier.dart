import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system(label: 'Auto (Follow Mobile Device Setting)', icon: Icons.brightness_auto_rounded),
  morning(label: 'Morning Mode (Green & Black)', icon: Icons.wb_sunny_rounded),
  night(label: 'Night Mode (Neon Green & White)', icon: Icons.nights_stay_rounded);

  final String label;
  final IconData icon;

  const AppThemeMode({required this.label, required this.icon});
}

class ThemeNotifier extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  AppThemeMode _currentMode = AppThemeMode.system;

  AppThemeMode get currentMode => _currentMode;

  ThemeNotifier() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_prefKey);
      if (savedString != null) {
        _currentMode = AppThemeMode.values.firstWhere(
          (m) => m.name == savedString,
          orElse: () => AppThemeMode.system,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }

  /// Morning Theme Data (Emerald Green & Deep Black)
  static ThemeData get morningTheme {
    const primaryGreen = Color(0xFF10B981); // Emerald Green
    const darkBackground = Color(0xFF0F172A); // Deep Slate / Black

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreen,
        onPrimary: Colors.black,
        secondary: const Color(0xFF059669),
        surface: const Color(0xFF1E293B),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
    );
  }

  /// Night Theme Data (Neon Cyber Green & Bright Contrast)
  static ThemeData get nightTheme {
    const neonGreen = Color(0xFF00FF66); // Cyber Neon Green
    const pureWhite = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF050B14), // Pure Deep Void
      colorScheme: ColorScheme.fromSeed(
        seedColor: neonGreen,
        brightness: Brightness.dark,
        primary: neonGreen,
        onPrimary: Colors.black,
        secondary: const Color(0xFF00E5FF),
        surface: const Color(0xFF0E1A2B),
        onSurface: pureWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF050B14),
        foregroundColor: neonGreen,
        elevation: 0,
      ),
    );
  }
}
