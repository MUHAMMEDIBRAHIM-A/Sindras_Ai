import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../jarvis/jarvis_screen.dart';
import '../multi_agent/multi_agent_screen.dart';
import '../services/agent_auth_service.dart';
import '../theme/theme_notifier.dart';
import '../utils/responsive_layout.dart';
import '../widgets/app_drawer.dart';
import 'allowed_apps_screen.dart';
import 'weekly_data_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final TextEditingController _cmdController = TextEditingController();
  final TextEditingController _missionController = TextEditingController();

  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _aiSpeakEnabled = true;
  String _activeAgentId = 'LOADING...';
  bool _isOwner = false;
  String _timeLeftStr = 'Expires 11:59 PM';

  final List<String> _terminalLogs = [
    '[SYSTEM] SINRAS PRO Cyber-Cat OS Initialized.',
    '[AUTH] Zero-Trust Session Active (Valid until 11:59 PM).',
    '[OVERLAY] Floating Call Bubble & Safety Services Ready.',
  ];

  List<Map<String, dynamic>> _todayMissions = [
    {'title': 'Verify system accessibility & voice bridge', 'done': true},
    {'title': 'Review weekly agent tasks & sync datasets', 'done': false},
  ];

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadAgentData();
    _loadMissions();
    _startCountdownTimer();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setPitch(1.2); // Cute Female Pitch
      await _flutterTts.setSpeechRate(0.5); // Conversational Speed
    } catch (_) {}
  }

  Future<void> _loadAgentData() async {
    final id = await AgentAuthService.getActiveAgentId();
    final isOwner = await AgentAuthService.isMasterOwner();
    if (mounted) {
      setState(() {
        _activeAgentId = id ?? 'TRIAL DAY 1';
        _isOwner = isOwner;
      });
    }
  }

  Future<void> _loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final missions = prefs.getStringList('today_missions');
    if (missions != null && missions.isNotEmpty) {
      setState(() {
        _todayMissions = missions.map((m) {
          final parts = m.split('::');
          return {
            'title': parts[0],
            'done': parts.length > 1 && parts[1] == '1',
          };
        }).toList();
      });
    }
  }

  Future<void> _saveMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _todayMissions.map((m) => '${m['title']}::${m['done'] ? '1' : '0'}').toList();
    await prefs.setStringList('today_missions', list);
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final diff = midnight.difference(now);
      if (mounted) {
        setState(() {
          _timeLeftStr = '${diff.inHours}h ${diff.inMinutes % 60}m Left';
        });
      }
    });
  }

  Future<void> _speakText(String text) async {
    if (!_aiSpeakEnabled) return;
    try {
      final isTamil = text.codeUnits.any((c) => c >= 0x0B80 && c <= 0x0BFF);
      await _flutterTts.setLanguage(isTamil ? 'ta-IN' : 'en-US');
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (_) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _cmdController.text = val.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _executeCommand() {
    final cmd = _cmdController.text.trim();
    if (cmd.isEmpty) return;

    setState(() {
      _terminalLogs.insert(0, '[CMD] $cmd');
      _terminalLogs.insert(0, '[STATUS] Routing instruction to Neural Agent Cores...');
    });

    _speakText('Executing command: $cmd');
    _cmdController.clear();
  }

  void _addMission() {
    final title = _missionController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _todayMissions.add({'title': title, 'done': false});
      _terminalLogs.insert(0, '[MISSION] New task assigned: $title');
    });
    _missionController.clear();
    _saveMissions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _cmdController.dispose();
    _missionController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
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
    final inputBg = isNight ? CyberPalette.nightInput : CyberPalette.morningInput;

    final completedCount = _todayMissions.where((m) => m['done'] == true).length;
    final progress = _todayMissions.isEmpty ? 0.0 : (completedCount / _todayMissions.length);

    return ResponsiveLayout.screenScaffold(
      context: context,
      backgroundColor: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: primary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/sinras_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'SINRAS PRO',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: ResponsiveLayout.scale(context, 16),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: textPri,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            tooltip: 'Toggle Morning / Night Mode',
            icon: Icon(
              isNight ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
              color: secondary,
              size: 20,
            ),
            onPressed: () {
              // Trigger theme toggle through ThemeNotifier via SharedPreferences
              final themeNotifier = ThemeNotifier();
              themeNotifier.toggleTheme();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isOwner ? Icons.workspace_premium_rounded : Icons.badge_rounded, size: 12, color: primary),
                    const SizedBox(width: 5),
                    Text(
                      _isOwner ? '$_activeAgentId [OWNER]' : _activeAgentId,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: secondary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: secondary),
                    const SizedBox(width: 5),
                    Text(
                      _timeLeftStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Cyber-Cat Center HUD Orb
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JarvisScreen()),
                );
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final orbSize = ResponsiveLayout.orbSize(context);
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: orbSize,
                      height: orbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: secondary.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
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
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'VIGILANT / ONLINE (Tap Orb for HUD)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CMD Command & Voice Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cmdController,
                        onSubmitted: (_) => _executeCommand(),
                        style: TextStyle(color: textPri, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'CMD: Enter or speak new task...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: Icon(Icons.terminal_rounded, color: secondary, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.redAccent : primary,
                      ),
                      onPressed: _toggleListening,
                      tooltip: 'Voice STT',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('AI Voice:', style: TextStyle(fontSize: 11, color: textSec)),
                        Switch(
                          value: _aiSpeakEnabled,
                          activeThumbColor: primary,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) => setState(() => _aiSpeakEnabled = val),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _executeCommand,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('EXECUTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: isNight ? const Color(0xFF0E1217) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Today's Task Assigner & Matrix
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TODAY'S MISSION MATRIX",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: primary,
                      ),
                    ),
                    Text(
                      '$completedCount/${_todayMissions.length} Complete',
                      style: TextStyle(fontSize: 11, color: textSec),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: borderCol,
                  color: primary,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _missionController,
                        onSubmitted: (_) => _addMission(),
                        style: TextStyle(color: textPri, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: '+ Assign Today\'s Mission...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.add_circle_rounded, color: primary),
                      onPressed: _addMission,
                      tooltip: 'Assign Mission',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._todayMissions.map((mission) {
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: primary,
                    title: Text(
                      mission['title'],
                      style: TextStyle(
                        fontSize: 12,
                        color: mission['done'] ? textSec : textPri,
                        decoration: mission['done'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    value: mission['done'],
                    onChanged: (val) {
                      setState(() {
                        mission['done'] = val ?? false;
                      });
                      _saveMissions();
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Live Terminal Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, size: 14, color: secondary),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE TERMINAL STREAM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._terminalLogs.take(4).map((log) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: log.contains('[CMD]') ? primary : textSec,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Quick Action Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _buildNavCard(
                context,
                title: 'Weekly Board',
                icon: Icons.calendar_month_rounded,
                color: secondary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeeklyDataScreen()),
                ),
              ),
              _buildNavCard(
                context,
                title: 'Voice HUD',
                icon: Icons.graphic_eq_rounded,
                color: primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JarvisScreen()),
                ),
              ),
              _buildNavCard(
                context,
                title: '17 AI Agents',
                icon: Icons.hub_rounded,
                color: Colors.purpleAccent,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MultiAgentScreen()),
                ),
              ),
              _buildNavCard(
                context,
                title: 'Allowed Apps',
                icon: Icons.lock_clock_rounded,
                color: Colors.amberAccent,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllowedAppsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isNight ? CyberPalette.nightCard : CyberPalette.morningCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
