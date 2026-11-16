import 'package:flutter/material.dart';
import '../jarvis/jarvis_controller.dart';
import '../multi_agent/agent_provider.dart';
import '../multi_agent/multi_agent_models.dart';
import '../multi_agent/multi_agent_storage.dart';
import '../theme/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<AgentProvider, String> _apiKeys = {};
  bool _soundFeedback = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final gemini = await MultiAgentStorage.readKey(MultiAgentKeys.geminiKey);
    final groq = await MultiAgentStorage.readKey(MultiAgentKeys.groqKey);
    final deepseek = await MultiAgentStorage.readKey(MultiAgentKeys.deepseekKey);

    if (mounted) {
      setState(() {
        _apiKeys[AgentProvider.gemini] = gemini;
        _apiKeys[AgentProvider.groq] = groq;
        _apiKeys[AgentProvider.deepseek] = deepseek;
      });
    }
  }

  void _showApiKeyDialog(AgentProvider provider) {
    final controller = TextEditingController(text: _apiKeys[provider] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(provider.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('${provider.label} Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configure your ${provider.label} API Key:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Paste API Key...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await MultiAgentStorage.writeKey(
                provider == AgentProvider.gemini
                    ? MultiAgentKeys.geminiKey
                    : provider == AgentProvider.groq
                        ? MultiAgentKeys.groqKey
                        : MultiAgentKeys.deepseekKey,
                controller.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                _loadKeys();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${provider.label} key saved.')),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentThemeMode = widget.themeNotifier.currentMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Settings & Configuration'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SECTION 1: THEME & DAY/NIGHT COLORS ────────────────────────────
          _buildSectionHeader(context, 'THEME & DAY/NIGHT COLORS', Icons.palette_rounded),
          Card(
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final isSelected = mode == currentThemeMode;

                return ListTile(
                  leading: Icon(
                    mode.icon,
                    size: 22,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    mode.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    mode == AppThemeMode.morning
                        ? 'Morning Mode (Emerald Green & Deep Black styling)'
                        : mode == AppThemeMode.night
                            ? 'Night Mode (Cyber Neon Green & Bright White styling)'
                            : 'Auto Mode (Adapts to mobile device system setting)',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    widget.themeNotifier.setThemeMode(mode);
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── SECTION 2: AI PROVIDER API KEYS ──────────────────────────
          _buildSectionHeader(context, 'AI ENGINE PROVIDER KEYS', Icons.vpn_key_rounded),
          Card(
            child: Column(
              children: AgentProvider.values.map((provider) {
                final key = _apiKeys[provider] ?? '';
                final isConfigured = key.isNotEmpty;

                return ListTile(
                  leading: Text(provider.icon, style: const TextStyle(fontSize: 22)),
                  title: Text('${provider.label} Engine Key'),
                  subtitle: Text(
                    isConfigured ? '••••••••••••${key.characters.takeLast(4)}' : 'Not configured',
                    style: TextStyle(
                      color: isConfigured ? Colors.green : theme.colorScheme.error,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => _showApiKeyDialog(provider),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── SECTION 3: SINRAS PRO OS PREFERENCES ─────────────────────
          _buildSectionHeader(context, 'SINRAS PRO OS FEEDBACK', Icons.graphic_eq_rounded),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Voice & Audio Responses'),
                  subtitle: const Text('Enable speech synthesis for SINRAS PRO OS'),
                  value: _soundFeedback,
                  onChanged: (val) => setState(() => _soundFeedback = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Haptic Vibration Feedback'),
                  subtitle: const Text('Vibrate device on Arc Reactor HUD tap'),
                  value: _hapticFeedback,
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── SECTION 4: SYSTEM ACTIONS & EXIT ─────────────────────────
          _buildSectionHeader(context, 'SYSTEM CONTROLLER & EXIT', Icons.power_settings_new_rounded),
          Card(
            child: ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              title: const Text('Exit SINRAS PRO Application', style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text('Safely terminate and exit mobile app'),
              onTap: () => JarvisController.exitApp(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
