import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
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
  AgentProvider _selectedProvider = AgentProvider.groq;
  final TextEditingController _commandController = TextEditingController();

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  bool _showTextInput = false;
  bool _safetyOverlayActive = false;

  String _statusText = 'SINRAS PRO OS ONLINE · AWAITING VOICE';
  String _lastSpeechResponse = 'Hello! I am SINRAS, your cute AI assistant. Tap the Arc Reactor to speak to me!';

  final List<Map<String, dynamic>> _logs = [];
  final Map<AgentProvider, String> _apiKeys = {};

  static const _overlayChannel = MethodChannel('sinras/overlay');

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _loadApiKeys();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5); // Sweet, friendly, natural rate
    await _flutterTts.setPitch(1.2);      // Cute female voice pitch

    try {
      await _flutterTts.setLanguage("en-US");
    } catch (_) {}
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;
    setState(() => _isSpeaking = true);

    final isTamil = text.codeUnits.any((code) => code >= 0x0B80 && code <= 0x0BFF);
    if (isTamil) {
      await _flutterTts.setLanguage("ta-IN");
    } else {
      await _flutterTts.setLanguage("en-US");
    }

    await _flutterTts.speak(text);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
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

  Future<void> _toggleVoiceListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _statusText = 'SINRAS PRO OS STANDBY';
      });
      return;
    }

    final available = await _speech.initialize(
      onError: (val) => setState(() {
        _isListening = false;
        _statusText = 'SPEECH ERROR: ${val.errorMsg}';
      }),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _statusText = 'VOICE MATRIX ACTIVE · LISTENING...';
      });

      _speech.listen(
        onResult: (val) {
          if (val.finalResult && val.recognizedWords.isNotEmpty) {
            setState(() => _isListening = false);
            _processCommand(val.recognizedWords);
          }
        },
      );
    } else {
      setState(() {
        _isListening = true;
        _statusText = 'SIMULATED SPEECH LISTENER ACTIVE...';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || !_isListening) return;
        setState(() => _isListening = false);
        _processCommand('Run complete automated system diagnostics suite');
      });
    }
  }

  Future<void> _toggleSafetyOverlay() async {
    try {
      if (_safetyOverlayActive) {
        await _overlayChannel.invokeMethod('stopSafetyOverlay');
        setState(() => _safetyOverlayActive = false);
      } else {
        await _overlayChannel.invokeMethod('startSafetyOverlay');
        setState(() => _safetyOverlayActive = true);
      }
    } catch (e) {
      debugPrint('Overlay error: $e');
    }
  }

  Future<void> _runAutoTestSequence() async {
    _commandController.text = 'Run automated mobile system auto-test';
    await _processCommand('Run complete automated system diagnostics suite');
  }

  Future<void> _processCommand(String commandText) async {
    final cmd = commandText.trim();
    if (cmd.isEmpty) return;

    // Check for explicit WhatsApp send commitment command
    if (cmd.toLowerCase().contains('send') && cmd.toLowerCase().contains('whatsapp')) {
      _showConfirmBeforeSendGateDialog('WhatsApp', 'Contact', cmd);
      return;
    }

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

      _speakText(response.speechText);
    }
  }

  Future<void> _showConfirmBeforeSendGateDialog(String appName, String recipient, String messageContent) async {
    final promptText = 'Should I send this message to $recipient on $appName?';
    _speakText(promptText);

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF00E5FF)),
            SizedBox(width: 8),
            Text('Confirm Before Send', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promptText,
              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Content: "$messageContent"',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel / வேண்டாம்', style: TextStyle(color: Colors.redAccent)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send / சரி அனுப்பு'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await JarvisController.confirmAndSendClick();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent with human confirmation.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action cancelled.')),
        );
      }
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
            icon: Icon(
              _safetyOverlayActive ? Icons.shield_rounded : Icons.shield_outlined,
              color: _safetyOverlayActive ? Colors.greenAccent : const Color(0xFF00E5FF),
            ),
            tooltip: 'Toggle Persistent Safety Overlay',
            onPressed: _toggleSafetyOverlay,
          ),
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
            isSpeaking: _isSpeaking,
            isThinking: _isThinking,
            onTap: _toggleVoiceListening,
          ),
          const SizedBox(height: 8),
          Text(
            _isListening ? 'TAP TO STOP LISTENING' : 'TAP HUD TO SPEAK (PRIMARY VOICE MODE)',
            style: TextStyle(
              color: const Color(0xFF00E5FF).withAlpha(180),
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // ── Speech Output Bubble ──────────────────────────────────────
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
                Icon(
                  _isSpeaking ? Icons.record_voice_over_rounded : Icons.volume_up_rounded,
                  color: _isSpeaking ? Colors.pinkAccent : const Color(0xFF00E5FF),
                  size: 18,
                ),
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
                _buildActionChip('🛡️ Safety Overlay', _toggleSafetyOverlay),
                _buildActionChip('⚙️ Settings', () {
                  JarvisController.executeAction('open_settings', {});
                }),
                _buildActionChip('📸 Camera', () {
                  JarvisController.executeAction('open_camera', {});
                }),
                _buildActionChip('📱 Launch App', () {
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
                _buildActionChip('⚡ Auto-Test Suite', _runAutoTestSequence),
                _buildActionChip('🚪 Exit App', _confirmExitApp),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'TERMINAL LOG',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              TextButton.icon(
                icon: Icon(
                  _showTextInput ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                  size: 16,
                  color: const Color(0xFF00E5FF),
                ),
                label: Text(
                  _showTextInput ? 'Hide Text Input' : 'Optional Text Input',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11),
                ),
                onPressed: () => setState(() => _showTextInput = !_showTextInput),
              ),
            ],
          ),
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
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Collapsible Optional Text Command Input Bar ─────────────────
          if (_showTextInput)
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
                        hintText: 'Type text command for SINRAS PRO...',
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
