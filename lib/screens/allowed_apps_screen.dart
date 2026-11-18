import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_notifier.dart';
import '../utils/responsive_layout.dart';

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
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final primary = isNight ? CyberPalette.nightPrimary : CyberPalette.morningPrimary;
    final cardBg = isNight ? CyberPalette.nightCard : CyberPalette.morningCard;
    final borderCol = isNight ? CyberPalette.nightBorder : CyberPalette.morningBorder;
    final textPri = isNight ? CyberPalette.nightTextPrimary : CyberPalette.morningTextPrimary;
    final textSec = isNight ? CyberPalette.nightTextSecondary : CyberPalette.morningTextSecondary;

    return ResponsiveLayout.screenScaffold(
      context: context,
      backgroundColor: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
      appBar: AppBar(
        title: Text(
          'ALLOWED APPS (ZERO-TRUST)',
          style: TextStyle(
            fontSize: ResponsiveLayout.scale(context, 14),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(bottom: BorderSide(color: borderCol)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, color: primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SINRAS PRO AI will ONLY automate apps toggled ON below. Banking, UPI, and payment apps are locked permanently for security.',
                          style: TextStyle(color: textSec, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: ResponsiveLayout.pagePadding(context),
                    itemCount: _installedApps.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final app = _installedApps[index];
                      final name = app['name'] as String;
                      final pkg = app['package'] as String;
                      final isLocked = app['isLocked'] as bool;
                      final isAllowed = _allowedState[pkg] ?? false;

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderCol),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLocked ? Colors.red.withAlpha(30) : primary.withAlpha(25),
                            child: Icon(
                              isLocked ? Icons.lock_rounded : Icons.android_rounded,
                              color: isLocked ? Colors.redAccent : primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: isLocked ? textSec : textPri,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            isLocked ? '🔒 Locked - Privacy & Payment Protected' : pkg,
                            style: TextStyle(
                              color: isLocked ? Colors.redAccent : textSec,
                              fontSize: 11,
                            ),
                          ),
                          trailing: isLocked
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.redAccent),
                                  ),
                                  child: const Text(
                                    'LOCKED',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : Switch(
                                  value: isAllowed,
                                  activeThumbColor: primary,
                                  onChanged: (val) => _toggleAppPermission(pkg, val),
                                ),
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
