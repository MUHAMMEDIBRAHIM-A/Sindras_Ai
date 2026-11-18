import 'package:flutter/material.dart';
import 'screens/entrance_gate_screen.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SinrasAiApp());
}

class SinrasAiApp extends StatefulWidget {
  final ThemeNotifier? themeNotifier;

  const SinrasAiApp({super.key, this.themeNotifier});

  @override
  State<SinrasAiApp> createState() => _SinrasAiAppState();
}

class _SinrasAiAppState extends State<SinrasAiApp> {
  late final ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = widget.themeNotifier ?? ThemeNotifier();
    _themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ThemeData activeTheme;
    final currentMode = _themeNotifier.currentMode;

    if (currentMode == AppThemeMode.morning) {
      activeTheme = ThemeNotifier.morningTheme;
    } else if (currentMode == AppThemeMode.night) {
      activeTheme = ThemeNotifier.nightTheme;
    } else {
      // System Auto-Mode: Follow system or soft charcoal
      final platformBrightness = MediaQuery.platformBrightnessOf(context);
      activeTheme = platformBrightness == Brightness.light
          ? ThemeNotifier.morningTheme
          : ThemeNotifier.nightTheme;
    }

    return MaterialApp(
      title: 'SINRAS PRO AI',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      home: const EntranceGateScreen(),
    );
  }
}
