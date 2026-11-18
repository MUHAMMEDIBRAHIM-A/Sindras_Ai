import 'package:flutter/material.dart';
import '../jarvis/jarvis_screen.dart';
import '../multi_agent/multi_agent_screen.dart';
import '../screens/agent_auth_screen.dart';
import '../screens/allowed_apps_screen.dart';
import '../screens/chat_history_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/weekly_data_screen.dart';
import '../services/agent_auth_service.dart';
import '../theme/theme_notifier.dart';

class AppDrawer extends StatelessWidget {
  final ThemeNotifier? themeNotifier;

  const AppDrawer({super.key, this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final primary = isNight ? CyberPalette.nightPrimary : CyberPalette.morningPrimary;
    final secondary = isNight ? CyberPalette.nightSecondary : CyberPalette.morningSecondary;
    final bg = isNight ? CyberPalette.nightCard : CyberPalette.morningCard;
    final borderCol = isNight ? CyberPalette.nightBorder : CyberPalette.morningBorder;
    final textPri = isNight ? CyberPalette.nightTextPrimary : CyberPalette.morningTextPrimary;
    final textSec = isNight ? CyberPalette.nightTextSecondary : CyberPalette.morningTextSecondary;

    return Drawer(
      backgroundColor: bg,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
              border: Border(bottom: BorderSide(color: borderCol, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 2),
                    boxShadow: [
                      BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/sinras_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SINRAS PRO AI',
                        style: TextStyle(
                          color: textPri,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cyber-Cat Neural OS',
                        style: TextStyle(color: textSec, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Items ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Command Center',
                  color: primary,
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Weekly Task Matrix',
                  color: secondary,
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyDataScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.graphic_eq_rounded,
                  title: 'New Chat / Voice HUD',
                  color: primary,
                  textPri: textPri,
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
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiAgentScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Chat & Voicemail Logs',
                  color: Colors.amberAccent,
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatHistoryScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_special_rounded,
                  title: 'Media & Documents',
                  color: Colors.greenAccent,
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.lock_clock_rounded,
                  title: 'Allowed Apps Whitelist',
                  color: Colors.orangeAccent,
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllowedAppsScreen()));
                  },
                ),
                Divider(color: borderCol, height: 20),
                _buildMenuItem(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Settings & Security Hub',
                  color: secondary,
                  textPri: textPri,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          themeNotifier: themeNotifier ?? ThemeNotifier(),
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Lock Session Now',
                  color: Colors.redAccent,
                  textPri: textPri,
                  onTap: () async {
                    Navigator.pop(context);
                    await AgentAuthService.clearSession();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AgentAuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
              border: Border(top: BorderSide(color: borderCol, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('v1.0.0+1', style: TextStyle(color: textSec, fontSize: 11, fontFamily: 'monospace')),
                Text('SINRAS PRO OS', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold)),
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
    required Color textPri,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(color: textPri, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}
