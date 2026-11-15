import 'package:flutter/material.dart';
import '../agent_screen.dart';
import '../jarvis/jarvis_screen.dart';
import '../multi_agent/multi_agent_screen.dart';
import '../services/auth_service.dart';
import 'documents_screen.dart';
import 'login_screen.dart';
import 'rag_chat_screen.dart';

/// Home screen with bottom navigation.
/// Tab 0: SINRAS PRO OS (Voice HUD & Mobile Device Controller)
/// Tab 1: Multi-Agent Engine (Gemini, Groq/SINRAS/FRIDAY, DeepSeek)
/// Tab 2: Classic Agent Screen
/// Tab 3: RAG Chat (document Q&A with citations)
/// Tab 4: Documents (upload & manage knowledge base)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    JarvisScreen(), // Flagship SINRAS PRO Mobile Voice & OS Controller
    MultiAgentScreen(), // Multi-Provider Agent System
    AgentScreen(apiKey: 'YOUR_GEMINI_API_KEY'), // Classic Agent
    RagChatScreen(),
    DocumentsScreen(),
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
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'Agent',
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
            icon: Icon(Icons.logout_rounded),
            label: 'Sign Out',
          ),
        ],
      ),
    );
  }
}
