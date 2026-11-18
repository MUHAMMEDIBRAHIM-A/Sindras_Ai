import 'package:flutter/material.dart';
import '../jarvis/jarvis_screen.dart';
import '../multi_agent/multi_agent_screen.dart';
import '../services/auth_service.dart';
import '../theme/theme_notifier.dart';
import '../widgets/app_drawer.dart';
import 'documents_screen.dart';
import 'login_screen.dart';
import 'rag_chat_screen.dart';
import 'settings_screen.dart';

/// Home screen with bottom navigation.
/// Tab 0: SINRAS PRO OS (Voice HUD & Mobile Device Controller)
/// Tab 1: Multi-Agent Engine (Gemini, Groq/SINRAS/FRIDAY, DeepSeek)
/// Tab 2: RAG Chat (document Q&A with citations)
/// Tab 3: Documents (upload & manage knowledge base)
/// Tab 4: Settings & Configuration
class HomeScreen extends StatefulWidget {
  final ThemeNotifier? themeNotifier;

  const HomeScreen({super.key, this.themeNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final ThemeNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.themeNotifier ?? ThemeNotifier();
  }

  List<Widget> get _screens => [
        const JarvisScreen(), // Flagship SINRAS PRO Mobile Voice & OS Controller
        const MultiAgentScreen(), // Multi-Provider Agent System
        const RagChatScreen(),
        const DocumentsScreen(),
        SettingsScreen(themeNotifier: _notifier), // Settings & Day/Night Theme Switcher
      ];

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(themeNotifier: _notifier),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 5) {
            _logout();
            return;
          }
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_outlined),
            selectedIcon: Icon(Icons.graphic_eq_rounded),
            label: 'SINRAS PRO',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology_rounded),
            label: 'Multi-Agent',
          ),
          NavigationDestination(
            icon: Icon(Icons.question_answer_outlined),
            selectedIcon: Icon(Icons.question_answer_rounded),
            label: 'RAG Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout_rounded),
            label: 'Sign Out',
          ),
        ],
      ),
    );
  }
}
