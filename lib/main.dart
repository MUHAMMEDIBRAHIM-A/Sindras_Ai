import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check initial authentication state
  final loggedIn = await AuthService.isLoggedIn();

  runApp(SinrasAiApp(initialLoggedIn: loggedIn));
}

class SinrasAiApp extends StatelessWidget {
  final bool initialLoggedIn;

  const SinrasAiApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SINRAS AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: initialLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
