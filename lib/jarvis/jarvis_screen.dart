import 'package:flutter/material.dart';
import '../multi_agent/agent_provider.dart';
import '../multi_agent/multi_agent_models.dart';
import '../multi_agent/multi_agent_storage.dart';
import 'jarvis_agent_service.dart';
import 'jarvis_controller.dart';
import 'jarvis_hud.dart';

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> {
  AgentProvider _selectedProvider = AgentProvider.groq; // Default to fast Groq SINRAS engine
  final TextEditingController _commandController = TextEditingController();

  bool _isListening = false;
  bool _isThinking = false;

  String _statusText = 'SINRAS PRO OS ONLINE · AWAITING COMMAND';
  String _lastSpeechResponse = 'Good day, sir. SINRAS PRO Mobile Controller is active.';

  final List<Map<String, dynamic>> _logs = [];
  final Map<AgentProvider, String> _apiKeys = {};

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKeys() async {
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

  void _toggleVoiceListening() {
    setState(() {
      _isListening = !_isListening;
      _statusText = _isListening ? 'VOICE MATRIX ACTIVE · LISTENING...' : 'SINRAS PRO OS STANDBY';
    });

    if (_isListening) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || !_isListening) return;
        setState(() => _isListening = false);
        _processCommand('Run complete automated system diagnostics suite');
      });
    }
  }

  Future<void> _runAutoTestSequence() async {
    _commandController.text = 'Run automated mobile system auto-test';
    await _processCommand('Run complete automated system diagnostics suite');
  }

  Future<void> _processCommand(String commandText) async {
    final cmd = commandText.trim();
    if (cmd.isEmpty) return;

    final apiKey = _apiKeys[_selectedProvider] ?? '';
    if (apiKey.isEmpty) {
      _showKeyRequiredDialog();
      return;
    }

    setState(() {
      _isThinking = true;
      _statusText = 'PROCESSING COMMAND VIA ${_selectedProvider.label.toUpperCase()}...';
      _commandController.clear();
      _logs.insert(0, {
        'type': 'user',
        'text': cmd,
        'time': DateTime.now(),
      });
    });

    final service = JarvisAgentService(
      provider: _selectedProvider,
      apiKey: apiKey,
    );

    final response = await service.processVoiceCommand(cmd);

    if (mounted) {
      setState(() {
        _isThinking = false;
        _statusText = 'SINRAS PRO OPERATIONAL · READY';
        _lastSpeechResponse = response.speechText;

        _logs.insert(0, {
          'type': 'jarvis',
          'text': response.speechText,
          'action': response.executedAction,
          'provider': response.provider,
          'time': DateTime.now(),
        });
      });
    }
  }

  Future<void> _confirmExitApp() async {
    final exitConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Exit SINRAS PRO OS', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to close and exit the SINRAS PRO application?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit App'),
          ),
        ],
      ),
    );

    if (exitConfirmed == true) {
      await JarvisController.exitApp();
    }
  }

  void _showKeyRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Required'),
        content: Text(
          'Please enter your ${_selectedProvider.label} API key to enable SINRAS PRO voice engine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060913),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00E5FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF00E5FF), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SINRAS PRO OS',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed_rounded, color: Color(0xFF00E5FF)),
            tooltip: 'Run Auto-Test Suite',
            onPressed: _runAutoTestSequence,
          ),
          PopupMenuButton<AgentProvider>(
            initialValue: _selectedProvider,
            tooltip: 'Select AI Engine Core',
            icon: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF00E5FF)),
            onSelected: (p) => setState(() => _selectedProvider = p),
            itemBuilder: (context) => AgentProvider.values.map((p) {
              return PopupMenuItem(
                value: p,
                child: Row(
                  children: [
                    Text(p.icon),
                    const SizedBox(width: 8),
                    Text('${p.label} Core'),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            tooltip: 'Exit Application',
            onPressed: _confirmExitApp,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── System Status & Diagnostics Bar ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 14, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 4),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF00E5FF), width: 0.5),
                  ),
                  child: Text(
                    _selectedProvider.label.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Arc Reactor HUD Voice Core ───────────────────────────────
          const SizedBox(height: 16),
          JarvisHudWidget(
            isListening: _isListening,
            isSpeaking: false,
            isThinking: _isThinking,
            onTap: _toggleVoiceListening,
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? 'TAP TO STOP LISTENING' : 'TAP HUD FOR VOICE COMMAND',
            style: TextStyle(
              color: const Color(0xFF00E5FF).withAlpha(180),
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // ── Speech Bubble ─────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131C31),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E5FF).withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up_rounded, color: Color(0xFF00E5FF), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastSpeechResponse,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Mobile Direct Control Quick Actions ────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildActionChip('⚙️ Settings', () {
                  JarvisController.executeAction('open_settings', {});
                }),
                _buildActionChip('📸 Camera', () {
                  JarvisController.executeAction('open_camera', {});
                }),
                _buildActionChip('📱 Launch Any App', () {
                  _processCommand('Open Chrome browser app');
                }),
                _buildActionChip('📍 Maps', () {
                  _processCommand('Open maps for nearby locations');
                }),
                _buildActionChip('📞 Phone Dialer', () {
                  JarvisController.executeAction('open_dialer', {});
                }),
                _buildActionChip('✉️ SMS Composer', () {
                  JarvisController.executeAction('send_sms', {});
                }),
                _buildActionChip('⏰ Clock & Alarm', () {
                  JarvisController.executeAction('open_alarm', {});
                }),
                _buildActionChip('⚡ Auto-Test Suite', _runAutoTestSequence),
                _buildActionChip('🚪 Exit App', _confirmExitApp),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // ── SINRAS PRO Terminal Execution Log ──────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isUser = log['type'] == 'user';
                final action = log['action'] as JarvisActionResult?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUser
                          ? Colors.white.withAlpha(20)
                          : const Color(0xFF00E5FF).withAlpha(50),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isUser ? 'USER COMMAND' : 'SINRAS PRO RESPONSE',
                            style: TextStyle(
                              color: isUser ? Colors.white70 : const Color(0xFF00E5FF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (action != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: action.success ? Colors.green.withAlpha(40) : Colors.red.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTION: ${action.actionName}',
                                style: TextStyle(
                                  color: action.success ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        log['text'].toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      if (action != null && action.message.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '📱 Mobile OS Execution: ${action.message}',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Text Command Input Bar ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF060913),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter command for SINRAS PRO...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _processCommand,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () => _processCommand(_commandController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 0.8),
        label: Text(
          label,
          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12),
        ),
        onPressed: onTap,
      ),
    );
  }
}
