import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllowedAppsScreen extends StatefulWidget {
  const AllowedAppsScreen({super.key});

  @override
  State<AllowedAppsScreen> createState() => _AllowedAppsScreenState();
}

class _AllowedAppsScreenState extends State<AllowedAppsScreen> {
  static const _appsChannel = MethodChannel('sinras/apps');

  List<Map<String, dynamic>> _installedApps = [];
  Map<String, bool> _allowedState = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppsAndPreferences();
  }

  Future<void> _loadAppsAndPreferences() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final List<dynamic> rawApps = await _appsChannel.invokeMethod('getInstalledApps');
      final List<Map<String, dynamic>> parsedApps = rawApps.map((e) {
        return Map<String, dynamic>.from(e as Map);
      }).toList();

      // Sort alphabetically by app name
      parsedApps.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      final Map<String, bool> states = {};
      for (final app in parsedApps) {
        final pkg = app['package'] as String;
        final isLocked = app['isLocked'] as bool;

        if (isLocked) {
          states[pkg] = false; // Always locked OFF
        } else {
          // Default to true for standard apps unless explicitly turned OFF
          states[pkg] = prefs.getBool('allowed_app_$pkg') ?? true;
        }
      }

      if (mounted) {
        setState(() {
          _installedApps = parsedApps;
          _allowedState = states;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAppPermission(String pkg, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowed_app_$pkg', enabled);
    setState(() {
      _allowedState[pkg] = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060913),
        title: const Text(
          'Allowed Apps (Zero-Trust)',
          style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0F172A),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SINRAS PRO AI will ONLY automate apps toggled ON below. Banking & UPI payment apps are locked for security.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _installedApps.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B), height: 1),
                    itemBuilder: (context, index) {
                      final app = _installedApps[index];
                      final name = app['name'] as String;
                      final pkg = app['package'] as String;
                      final isLocked = app['isLocked'] as bool;
                      final isAllowed = _allowedState[pkg] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLocked ? Colors.red.withAlpha(40) : const Color(0xFF00E5FF).withAlpha(30),
                          child: Icon(
                            isLocked ? Icons.lock_rounded : Icons.android_rounded,
                            color: isLocked ? Colors.redAccent : const Color(0xFF00E5FF),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: isLocked ? Colors.white54 : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isLocked ? '🔒 Locked - Privacy & Payment Protected' : pkg,
                          style: TextStyle(
                            color: isLocked ? Colors.redAccent : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        trailing: isLocked
                            ? const Text('LOCKED', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))
                            : Switch(
                                value: isAllowed,
                                activeThumbColor: const Color(0xFF00E5FF),
                                onChanged: (val) => _toggleAppPermission(pkg, val),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
