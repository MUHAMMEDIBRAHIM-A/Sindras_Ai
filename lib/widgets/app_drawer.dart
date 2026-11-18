import 'package:flutter/material.dart';
import '../jarvis/jarvis_screen.dart';
import '../multi_agent/multi_agent_screen.dart';
import '../screens/chat_history_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/theme_notifier.dart';

class AppDrawer extends StatelessWidget {
  final ThemeNotifier? themeNotifier;

  const AppDrawer({super.key, this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0B101D),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF060913),
              border: Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SINRAS PRO AI',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Autonomous OS Assistant',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Navigation Items ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.mic_rounded,
                  title: 'New Chat / Voice HUD',
                  color: const Color(0xFF00E5FF),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JarvisScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.hub_rounded,
                  title: 'Multi-Agent Matrix (17 Cores)',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiAgentScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Chat History',
                  color: Colors.amberAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatHistoryScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_special_rounded,
                  title: 'Media & Documents / Tools',
                  color: Colors.greenAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                  },
                ),
                const Divider(color: Color(0xFF1E293B), height: 24),
                _buildMenuItem(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Settings & Security Hub',
                  color: const Color(0xFF00E5FF),
                  onTap: () {
                    Navigator.pop(context);
                    if (themeNotifier != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(themeNotifier: themeNotifier!)));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF060913),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('VERSION 1.0.0+1', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                Text('SINRAS PRO OS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }
}
