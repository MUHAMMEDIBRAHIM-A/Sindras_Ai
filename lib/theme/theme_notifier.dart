import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system(label: 'Auto (Follow Mobile System)', icon: Icons.brightness_auto_rounded),
  morning(label: 'Morning Mode (Ice-Blue Mist)', icon: Icons.wb_sunny_rounded),
  night(label: 'Night Mode (Soft Charcoal Cyber)', icon: Icons.nights_stay_rounded);

  final String label;
  final IconData icon;

  const AppThemeMode({required this.label, required this.icon});
}

class CyberPalette {
  // Night Mode (Soft Charcoal / Light-Black)
  static const Color nightScaffold = Color(0xFF12161C);
  static const Color nightCard = Color(0xFF1A2029);
  static const Color nightInput = Color(0xFF0E1217);
  static const Color nightPrimary = Color(0xFF39FF14); // Cyber-Cat Neon Green
  static const Color nightSecondary = Color(0xFF00E5FF); // Electric Cyan
  static const Color nightTextPrimary = Color(0xFFF1F5F9);
  static const Color nightTextSecondary = Color(0xFF94A3B8);
  static const Color nightBorder = Color(0xFF283240);

  // Morning Mode (Ice-Blue Tinted Soft White)
  static const Color morningScaffold = Color(0xFFEEF4FA);
  static const Color morningCard = Color(0xFFF7FAFD);
  static const Color morningInput = Color(0xFFE2ECF5);
  static const Color morningPrimary = Color(0xFF059669); // Deep Emerald Cyber Green
  static const Color morningSecondary = Color(0xFF0284C7); // Ocean Blue
  static const Color morningTextPrimary = Color(0xFF0F172A);
  static const Color morningTextSecondary = Color(0xFF475569);
  static const Color morningBorder = Color(0xFFCBD5E1);
}

class ThemeNotifier extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  AppThemeMode _currentMode = AppThemeMode.night;

  AppThemeMode get currentMode => _currentMode;
  bool get isNight => _currentMode == AppThemeMode.night || _currentMode == AppThemeMode.system;

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
          orElse: () => AppThemeMode.night,
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

  void toggleTheme() {
    if (_currentMode == AppThemeMode.night) {
      setThemeMode(AppThemeMode.morning);
    } else {
      setThemeMode(AppThemeMode.night);
    }
  }

  /// Morning Theme Data (Ice-Blue Tinted Soft White — Never Harsh Pure White)
  static ThemeData get morningTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CyberPalette.morningScaffold,
      cardColor: CyberPalette.morningCard,
      dividerColor: CyberPalette.morningBorder,
      colorScheme: const ColorScheme.light(
        primary: CyberPalette.morningPrimary,
        secondary: CyberPalette.morningSecondary,
        surface: CyberPalette.morningCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: CyberPalette.morningTextPrimary,
        outline: CyberPalette.morningBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CyberPalette.morningScaffold,
        foregroundColor: CyberPalette.morningTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberPalette.morningInput,
        hintStyle: const TextStyle(color: CyberPalette.morningTextSecondary, fontSize: 13),
        labelStyle: const TextStyle(color: CyberPalette.morningTextPrimary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberPalette.morningBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberPalette.morningBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberPalette.morningPrimary, width: 1.5),
        ),
      ),
    );
  }

  /// Night Theme Data (Soft Obsidian Charcoal — Never Harsh Pure Black)
  static ThemeData get nightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CyberPalette.nightScaffold,
      cardColor: CyberPalette.nightCard,
      dividerColor: CyberPalette.nightBorder,
      colorScheme: const ColorScheme.dark(
        primary: CyberPalette.nightPrimary,
        secondary: CyberPalette.nightSecondary,
        surface: CyberPalette.nightCard,
        onPrimary: Color(0xFF0E1217),
        onSecondary: Color(0xFF0E1217),
        onSurface: CyberPalette.nightTextPrimary,
        outline: CyberPalette.nightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CyberPalette.nightScaffold,
        foregroundColor: CyberPalette.nightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberPalette.nightInput,
        hintStyle: const TextStyle(color: CyberPalette.nightTextSecondary, fontSize: 13),
        labelStyle: const TextStyle(color: CyberPalette.nightTextPrimary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberPalette.nightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberPalette.nightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CyberPalette.nightPrimary, width: 1.5),
        ),
      ),
    );
  }
}
