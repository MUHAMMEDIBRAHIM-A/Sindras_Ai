import 'package:flutter/material.dart';
import '../services/agent_auth_service.dart';
import '../theme/theme_notifier.dart';
import '../utils/responsive_layout.dart';
import 'agent_auth_screen.dart';
import 'dashboard_screen.dart';

class EntranceGateScreen extends StatefulWidget {
  const EntranceGateScreen({super.key});

  @override
  State<EntranceGateScreen> createState() => _EntranceGateScreenState();
}

class _EntranceGateScreenState extends State<EntranceGateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.repeat(reverse: true);
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    final isValid = await AgentAuthService.isSessionValidForToday();

    if (!mounted) return;
    if (isValid) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AgentAuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;
    final orbSize = ResponsiveLayout.orbSize(context) * 1.1;

    return ResponsiveLayout.screenScaffold(
      context: context,
      scrollable: false,
      backgroundColor: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isNight ? CyberPalette.nightPrimary : CyberPalette.morningPrimary)
                              .withValues(alpha: _opacityAnimation.value * 0.4),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/sinras_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'SINRAS PRO AI',
              style: TextStyle(
                fontSize: ResponsiveLayout.scale(context, 24),
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: isNight ? CyberPalette.nightPrimary : CyberPalette.morningPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CYBER-CAT NEURAL OPERATING SYSTEM',
              style: TextStyle(
                fontSize: ResponsiveLayout.scale(context, 11),
                letterSpacing: 1.5,
                color: isNight ? CyberPalette.nightTextSecondary : CyberPalette.morningTextSecondary,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isNight ? CyberPalette.nightSecondary : CyberPalette.morningSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
