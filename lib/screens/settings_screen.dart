import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../jarvis/jarvis_controller.dart';
import '../multi_agent/agent_provider.dart';
import '../multi_agent/multi_agent_models.dart';
import '../multi_agent/multi_agent_storage.dart';
import '../services/agent_auth_service.dart';
import '../theme/theme_notifier.dart';
import '../utils/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import 'allowed_apps_screen.dart';
import 'entrance_gate_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<AgentProvider, String> _apiKeys = {};

  final TextEditingController _serverUrlController = TextEditingController();
  bool _isPinging = false;
  String? _pingResult;
  bool _pingSuccess = false;

  String? _activeAgentId;
  bool _isSessionActive = false;

  bool _soundFeedback = true;
  bool _hapticFeedback = true;
  bool _privacyPaymentLock = true;
  bool _safetyOverlayActive = false;
  bool _smartCallTimerActive = true;

  static const _overlayChannel = MethodChannel('sinras/overlay');
  static const _hardwareChannel = MethodChannel('sinras/hardware');

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    final serverUrl = await AppConfig.getBackendBaseUrl();
    _serverUrlController.text = serverUrl;

    final agentId = await AgentAuthService.getSavedAgentId();
    final isValid = await AgentAuthService.isSessionValidForToday();

    final gemini = await MultiAgentStorage.readKey(MultiAgentKeys.geminiKey);
    final groq = await MultiAgentStorage.readKey(MultiAgentKeys.groqKey);
    final deepseek = await MultiAgentStorage.readKey(MultiAgentKeys.deepseekKey);

    final prefs = await SharedPreferences.getInstance();
    final lockState = prefs.getBool('privacy_payment_lock') ?? true;
    final callState = prefs.getBool('smart_call_timer_active') ?? true;

    if (mounted) {
      setState(() {
        _activeAgentId = agentId;
        _isSessionActive = isValid;
        _apiKeys[AgentProvider.gemini] = gemini;
        _apiKeys[AgentProvider.groq] = groq;
        _apiKeys[AgentProvider.deepseek] = deepseek;
        _privacyPaymentLock = lockState;
        _smartCallTimerActive = callState;
      });
    }
  }

  Future<void> _pingServer() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isPinging = true;
      _pingResult = 'Testing connection...';
      _pingSuccess = false;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final uri = Uri.parse('$cleanUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] ?? 'ok';
        setState(() {
          _pingSuccess = true;
          _pingResult = 'ONLINE (${stopwatch.elapsedMilliseconds}ms) — Status: $status';
        });
        await AppConfig.setBackendBaseUrl(cleanUrl);
      } else {
        setState(() {
          _pingSuccess = false;
          _pingResult = 'HTTP ${response.statusCode}: Server responded with error';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _pingSuccess = false;
        _pingResult = 'OFFLINE: Unable to connect ($e)';
      });
    } finally {
      setState(() => _isPinging = false);
    }
  }

  Future<void> _saveServerUrl() async {
    final url = _serverUrlController.text.trim();
    if (url.isNotEmpty) {
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      await AppConfig.setBackendBaseUrl(cleanUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server URL set to: $cleanUrl'),
            backgroundColor: CyberPalette.nightPrimary,
          ),
        );
      }
    }
  }

  Future<void> _lockSessionNow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lock Agent Session?'),
        content: const Text(
          'This will terminate your current session on this device. You will need to re-authenticate with your 12-Digit Agent ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lock Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AgentAuthService.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EntranceGateScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _togglePrivacyLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_payment_lock', value);
    setState(() => _privacyPaymentLock = value);
  }

  Future<void> _toggleSafetyOverlay(bool value) async {
    try {
      if (value) {
        await _overlayChannel.invokeMethod('startSafetyOverlay');
      } else {
        await _overlayChannel.invokeMethod('stopSafetyOverlay');
      }
      setState(() => _safetyOverlayActive = value);
    } catch (e) {
      debugPrint('Overlay toggle error: $e');
    }
  }

  Future<void> _toggleCallTimerBubble(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_call_timer_active', value);
    setState(() => _smartCallTimerActive = value);
    try {
      if (value) {
        await _overlayChannel.invokeMethod('startCallBubble');
      }
    } catch (e) {
      debugPrint('Call bubble error: $e');
    }
  }

  Future<void> _openDefaultVoiceAssistantSettings() async {
    try {
      await _hardwareChannel.invokeMethod('openVoiceInputSettings');
    } catch (e) {
      debugPrint('Voice settings error: $e');
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
                _loadAllSettings();
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
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final primary = isNight ? CyberPalette.nightPrimary : CyberPalette.morningPrimary;
    final secondary = isNight ? CyberPalette.nightSecondary : CyberPalette.morningSecondary;
    final cardBg = isNight ? CyberPalette.nightCard : CyberPalette.morningCard;
    final borderCol = isNight ? CyberPalette.nightBorder : CyberPalette.morningBorder;
    final textPri = isNight ? CyberPalette.nightTextPrimary : CyberPalette.morningTextPrimary;
    final textSec = isNight ? CyberPalette.nightTextSecondary : CyberPalette.morningTextSecondary;
    final currentThemeMode = widget.themeNotifier.currentMode;

    return ResponsiveLayout.screenScaffold(
      context: context,
      backgroundColor: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'SETTINGS & SECURITY HUB',
          style: TextStyle(
            fontSize: ResponsiveLayout.scale(context, 14),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: ResponsiveLayout.pagePadding(context),
        children: [
          // ── SECTION 1: FASTAPI BACKEND SERVER CONNECTION ─────────────
          _buildHeader('BACKEND SERVER CONNECTION (FASTAPI :8000)', Icons.router_rounded, primary),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Physical Device / LAN Server URL:',
                  style: TextStyle(color: textPri, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _serverUrlController,
                  style: TextStyle(color: textPri, fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://10.189.101.145:8000',
                    hintStyle: TextStyle(color: textSec.withAlpha(100)),
                    filled: true,
                    fillColor: isNight ? CyberPalette.nightInput : CyberPalette.morningInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderCol),
                    ),
                    prefixIcon: Icon(Icons.link_rounded, color: primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _saveServerUrl,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save URL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: isNight ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isPinging ? null : _pingServer,
                        icon: _isPinging
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.wifi_tethering_rounded, size: 16),
                        label: const Text('Ping / Test'),
                      ),
                    ),
                  ],
                ),
                if (_pingResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _pingSuccess
                          ? Colors.green.withAlpha(isNight ? 40 : 25)
                          : Colors.red.withAlpha(isNight ? 40 : 25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _pingSuccess ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _pingSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: _pingSuccess ? Colors.green : Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pingResult!,
                            style: TextStyle(
                              color: _pingSuccess ? Colors.green : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── SECTION 2: AGENT AUTH & ZERO-TRUST SESSION ────────────────
          _buildHeader('ZERO-TRUST AGENT AUTHENTICATION', Icons.badge_rounded, primary),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isSessionActive ? Icons.verified_user_rounded : Icons.lock_clock_rounded,
                      color: _isSessionActive ? primary : Colors.amberAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeAgentId != null ? 'AGENT: $_activeAgentId' : 'STATUS: NOT SIGNED IN',
                            style: TextStyle(
                              color: textPri,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _isSessionActive ? 'Active Today · Session resets at 11:59 PM' : 'Session Expired or Inactive',
                            style: TextStyle(color: textSec, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _lockSessionNow,
                    icon: const Icon(Icons.lock_rounded, size: 16),
                    label: const Text('Lock Session Now (Requires Re-Auth)'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── SECTION 3: CENTRALIZED SECURITY HUB & OS PATCHES ─────────
          _buildHeader('CENTRALIZED SECURITY HUB & OS PATCHES', Icons.shield_rounded, primary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.apps_outage_rounded, color: secondary),
                  title: Text('Allowed Apps Whitelist', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('Zero-trust whitelisting: toggle which apps SINRAS can automate.', style: TextStyle(color: textSec, fontSize: 11)),
                  trailing: Icon(Icons.chevron_right_rounded, color: secondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllowedAppsScreen()),
                    );
                  },
                ),
                Divider(color: borderCol, height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_rounded, color: Colors.redAccent),
                  title: Text('Privacy & Payment Lock', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('Strictly block access to Banking & UPI apps (GPay, PhonePe, Paytm)', style: TextStyle(color: textSec, fontSize: 11)),
                  value: _privacyPaymentLock,
                  activeThumbColor: Colors.redAccent,
                  onChanged: _togglePrivacyLock,
                ),
                Divider(color: borderCol, height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.picture_in_picture_alt_rounded, color: secondary),
                  title: Text('Floating Safety Overlay', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('Persistent EXIT / STOP / PAUSE controls over all mobile screens', style: TextStyle(color: textSec, fontSize: 11)),
                  value: _safetyOverlayActive,
                  activeThumbColor: secondary,
                  onChanged: _toggleSafetyOverlay,
                ),
                Divider(color: borderCol, height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.phone_callback_rounded, color: Colors.amberAccent),
                  title: Text('Smart Call Timer Bubble', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('DND/Silent 5s auto-attend & voice message recording', style: TextStyle(color: textSec, fontSize: 11)),
                  value: _smartCallTimerActive,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: _toggleCallTimerBubble,
                ),
                Divider(color: borderCol, height: 1),
                ListTile(
                  leading: Icon(Icons.power_settings_new_rounded, color: secondary),
                  title: Text('Default Voice Assistant (Power Button)', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('Set SINRAS PRO AI as default assistant on Power Button long-press', style: TextStyle(color: textSec, fontSize: 11)),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondary,
                      side: BorderSide(color: secondary),
                    ),
                    onPressed: _openDefaultVoiceAssistantSettings,
                    child: const Text('Configure'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── SECTION 4: THEME & COLOR PALETTE ──────────────────────────
          _buildHeader('CYBER THEME PALETTE', Icons.palette_rounded, primary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final isSelected = mode == currentThemeMode;
                return ListTile(
                  leading: Icon(
                    mode.icon,
                    size: 22,
                    color: isSelected ? primary : textSec,
                  ),
                  title: Text(
                    mode.label,
                    style: TextStyle(
                      color: textPri,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    mode == AppThemeMode.morning
                        ? 'Morning Mode (Ice-Blue Mist White & Emerald Green)'
                        : mode == AppThemeMode.night
                            ? 'Night Mode (Soft Obsidian Charcoal & Neon Green)'
                            : 'Auto Mode (Adapts to system dark/light setting)',
                    style: TextStyle(color: textSec, fontSize: 11),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle_rounded, color: primary) : null,
                  onTap: () {
                    widget.themeNotifier.setThemeMode(mode);
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // ── SECTION 5: AI ENGINE PROVIDER KEYS ────────────────────────
          _buildHeader('AI ENGINE PROVIDER KEYS', Icons.vpn_key_rounded, primary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: AgentProvider.values.map((provider) {
                final key = _apiKeys[provider] ?? '';
                final isConfigured = key.isNotEmpty;

                return ListTile(
                  leading: Text(provider.icon, style: const TextStyle(fontSize: 22)),
                  title: Text('${provider.label} Engine Key', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isConfigured ? '••••••••••••${key.characters.takeLast(4)}' : 'Not configured',
                    style: TextStyle(
                      color: isConfigured ? Colors.green : Colors.redAccent,
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.edit_rounded, color: secondary),
                    onPressed: () => _showApiKeyDialog(provider),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // ── SECTION 6: OS FEEDBACK PREFERENCES ────────────────────────
          _buildHeader('SINRAS PRO OS FEEDBACK', Icons.graphic_eq_rounded, primary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.volume_up_rounded, color: primary),
                  title: Text('Voice & Audio Responses', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('Enable Cute Female speech synthesis for SINRAS PRO OS', style: TextStyle(color: textSec, fontSize: 11)),
                  value: _soundFeedback,
                  activeThumbColor: primary,
                  onChanged: (val) => setState(() => _soundFeedback = val),
                ),
                Divider(color: borderCol, height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.vibration_rounded, color: primary),
                  title: Text('Haptic Vibration Feedback', style: TextStyle(color: textPri, fontWeight: FontWeight.bold)),
                  subtitle: Text('Vibrate device on HUD tap and voice events', style: TextStyle(color: textSec, fontSize: 11)),
                  value: _hapticFeedback,
                  activeThumbColor: primary,
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── SECTION 7: SYSTEM EXIT ───────────────────────────────────
          _buildHeader('SYSTEM CONTROLLER & EXIT', Icons.power_settings_new_rounded, primary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              title: const Text('Exit SINRAS PRO Application', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              subtitle: Text('Safely terminate background services and exit app', style: TextStyle(color: textSec, fontSize: 11)),
              onTap: () => JarvisController.exitApp(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
