import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check initial authentication state
  final loggedIn = await AuthService.isLoggedIn();

  runApp(SinrasAiApp(initialLoggedIn: loggedIn));
}

class SinrasAiApp extends StatefulWidget {
  final bool initialLoggedIn;
  final ThemeNotifier? themeNotifier;

  const SinrasAiApp({
    super.key,
    required this.initialLoggedIn,
    this.themeNotifier,
  });

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
      // System Auto-Mode: Check system brightness or default to night
      final platformBrightness = MediaQuery.platformBrightnessOf(context);
      activeTheme = platformBrightness == Brightness.light
          ? ThemeNotifier.morningTheme
          : ThemeNotifier.nightTheme;
    }

    return MaterialApp(
      title: 'SINRAS AI',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      home: widget.initialLoggedIn
          ? HomeScreen(themeNotifier: _themeNotifier)
          : const LoginScreen(),
    );
  }
}
