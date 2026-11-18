import 'package:flutter/material.dart';
import '../services/agent_auth_service.dart';
import '../theme/theme_notifier.dart';
import '../utils/responsive_layout.dart';
import 'dashboard_screen.dart';

class AgentAuthScreen extends StatefulWidget {
  const AgentAuthScreen({super.key});

  @override
  State<AgentAuthScreen> createState() => _AgentAuthScreenState();
}

class _AgentAuthScreenState extends State<AgentAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _agentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _agentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleIdLogin() async {
    final text = _agentIdController.text.trim();
    if (text.isEmpty) {
      _showMessage('Please enter your 12-Digit Agent ID', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final result = await AgentAuthService.loginWithAgentId(text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showMessage(result.message, isError: false);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showMessage(result.message, isError: true);
    }
  }

  Future<void> _handleTrialRegister() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid Email ID', isError: true);
      return;
    }
    if (phone.isEmpty || phone.length < 8) {
      _showMessage('Please enter a valid Phone Number', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final result = await AgentAuthService.createTrial(email: email, phone: phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showMessage(result.message, isError: false);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showMessage(result.message, isError: true);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    setState(() {
      _statusMessage = msg;
      _isError = isError;
    });
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

    return ResponsiveLayout.screenScaffold(
      context: context,
      backgroundColor: isNight ? CyberPalette.nightScaffold : CyberPalette.morningScaffold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Logo & Header
          Hero(
            tag: 'cyber_cat_logo',
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2),
                boxShadow: [
                  BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 18),
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
          ),
          const SizedBox(height: 14),
          Text(
            'SINRAS PRO AI',
            style: TextStyle(
              fontSize: ResponsiveLayout.scale(context, 20),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: textPri,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Zero-Trust Dual-Stage Authentication',
            style: TextStyle(fontSize: 12, color: textSec),
          ),
          const SizedBox(height: 24),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: primary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              labelColor: primary,
              unselectedLabelColor: textSec,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: '12-Digit Agent ID'),
                Tab(text: '1-Day Trial Pass'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 12-Digit Agent ID Login
                _buildAgentIdTab(isNight, primary, secondary, cardBg, borderCol, textPri, textSec),
                // Tab 2: First-time Trial Pass
                _buildTrialTab(isNight, primary, secondary, cardBg, borderCol, textPri, textSec),
              ],
            ),
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isError ? Colors.red.withValues(alpha: 0.12) : primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isError ? Colors.redAccent : primary),
              ),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _isError ? Colors.redAccent : primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 14, color: secondary),
              const SizedBox(width: 6),
              Text(
                'Master Owner: ibu2007ava@gmail.com',
                style: TextStyle(fontSize: 11, color: textSec),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentIdTab(
    bool isNight,
    Color primary,
    Color secondary,
    Color cardBg,
    Color borderCol,
    Color textPri,
    Color textSec,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your approved 12-Digit Agent ID:',
          style: TextStyle(fontSize: 12, color: textSec),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _agentIdController,
          inputFormatters: [AgentIdFormatter()],
          style: TextStyle(
            color: primary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: '742 IBBU 07 PRO',
            prefixIcon: Icon(Icons.badge_rounded, color: secondary),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: textSec, size: 18),
              onPressed: () => _agentIdController.clear(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Format: 3 Digits + 4 Letters + 2 Digits + 3 Letters',
          style: TextStyle(fontSize: 11, color: textSec.withValues(alpha: 0.8)),
        ),
        const Spacer(),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleIdLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: isNight ? const Color(0xFF0E1217) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text(
                    'AUTHENTICATE AGENT ID',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialTab(
    bool isNight,
    Color primary,
    Color secondary,
    Color cardBg,
    Color borderCol,
    Color textPri,
    Color textSec,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email ID (e.g. user@gmail.com)',
            prefixIcon: Icon(Icons.email_rounded, color: secondary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Phone Number (e.g. +91 9442895971)',
            prefixIcon: Icon(Icons.phone_android_rounded, color: secondary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Grants 1-Day Trial Pass. Owner review link sent to ibu2007ava@gmail.com.',
          style: TextStyle(fontSize: 11, color: textSec.withValues(alpha: 0.8)),
        ),
        const Spacer(),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleTrialRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: isNight ? const Color(0xFF0E1217) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text(
                    'ACTIVATE 1-DAY TRIAL',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ),
      ],
    );
  }
}
