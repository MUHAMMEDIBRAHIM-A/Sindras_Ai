import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AgentIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Remove non-alphanumeric and uppercase
    final cleaned = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    // 2. Max length is 12 characters (3 + 4 + 2 + 3)
    final truncated = cleaned.length > 12 ? cleaned.substring(0, 12) : cleaned;

    // 3. Insert spaces dynamically: NNN LLLL NN LLL
    final buffer = StringBuffer();
    for (int i = 0; i < truncated.length; i++) {
      if (i == 3 || i == 7 || i == 9) {
        buffer.write(' ');
      }
      buffer.write(truncated[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AuthResult {
  final bool success;
  final String? agentId;
  final bool isOwner;
  final bool isTrial;
  final String? expiresAt;
  final String message;

  AuthResult({
    required this.success,
    this.agentId,
    this.isOwner = false,
    this.isTrial = false,
    this.expiresAt,
    required this.message,
  });
}

class AgentAuthService {
  static const String _tokenKey = 'sinras_access_token';
  static const String _agentIdKey = 'sinras_agent_id';
  static const String _isOwnerKey = 'sinras_is_owner';
  static const String _sessionDateKey = 'sinras_session_date';
  static const String _sessionExpiresKey = 'sinras_session_expires_at';

  static const String masterOwnerEmail = 'ibu2007ava@gmail.com';
  static const String masterOwnerPhone = '9442895971';
  static const String masterOwnerAgentId = '742 IBBU 07 PRO';

  /// Validates format: 3 Digits + 4 Uppercase Letters + 2 Digits + 3 Uppercase Letters
  static bool isValidAgentId(String id) {
    final cleaned = id.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final regex = RegExp(r'^[0-9]{3}[A-Z]{4}[0-9]{2}[A-Z]{3}$');
    return regex.hasMatch(cleaned);
  }

  /// Check if the stored session is valid for today (auto-expires at midnight 11:59 PM)
  static Future<bool> isSessionValidForToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final sessionDate = prefs.getString(_sessionDateKey);

      if (token == null || sessionDate == null) return false;

      final todayStr = _getTodayString();
      if (sessionDate != todayStr) {
        // Expired from previous day
        await clearSession();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getActiveAgentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_agentIdKey);
  }

  static Future<String?> getSavedAgentId() => getActiveAgentId();

  static Future<bool> isMasterOwner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOwnerKey) ?? false;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Stage 1: First-Time User 1-Day Trial Pass (or Master Owner Instant Login)
  static Future<AuthResult> createTrial({
    required String email,
    required String phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Master Owner Bypass
    if (cleanEmail == masterOwnerEmail.toLowerCase() || cleanPhone.contains(masterOwnerPhone)) {
      await _persistSession(
        token: 'owner_master_token_${DateTime.now().millisecondsSinceEpoch}',
        agentId: masterOwnerAgentId,
        isOwner: true,
        expiresAt: '23:59:59 Today',
      );
      return AuthResult(
        success: true,
        agentId: masterOwnerAgentId,
        isOwner: true,
        isTrial: false,
        message: 'Master Owner Verified. Permanent Clearance Granted.',
      );
    }

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/create-trial');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'phone': cleanPhone}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? 'trial_token';
        final isOwner = data['is_owner'] ?? false;
        final agentId = data['agent_id'] ?? 'TRIAL DAY 1';
        final expiresAt = data['trial_expires_at'] ?? '11:59 PM';

        await _persistSession(
          token: token,
          agentId: agentId,
          isOwner: isOwner,
          expiresAt: expiresAt,
        );

        return AuthResult(
          success: true,
          agentId: agentId,
          isOwner: isOwner,
          isTrial: true,
          expiresAt: expiresAt,
          message: data['message'] ?? '1-Day Trial Pass Activated.',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (_) {
      // Offline fallback: Grant local 1-Day Trial Pass
      await _persistSession(
        token: 'local_trial_${DateTime.now().millisecondsSinceEpoch}',
        agentId: 'TRIAL DAY 1',
        isOwner: false,
        expiresAt: '11:59 PM Today',
      );
      return AuthResult(
        success: true,
        agentId: 'TRIAL DAY 1',
        isOwner: false,
        isTrial: true,
        expiresAt: '11:59 PM Today',
        message: '1-Day Trial Pass Activated locally. Owner verification link queued.',
      );
    }
  }

  /// Stage 3: Second Login & Daily Reset (ID-Only Login: NNN LLLL NN LLL)
  static Future<AuthResult> loginWithAgentId(String rawAgentId) async {
    final cleaned = rawAgentId.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (!isValidAgentId(cleaned)) {
      return AuthResult(
        success: false,
        message: 'Invalid 12-Digit Agent ID format. Expected NNN LLLL NN LLL (e.g. 742 IBBU 07 PRO)',
      );
    }

    final formatted = '${cleaned.substring(0, 3)} ${cleaned.substring(3, 7)} ${cleaned.substring(7, 9)} ${cleaned.substring(9, 12)}';

    // Master Owner Check
    if (formatted == masterOwnerAgentId) {
      await _persistSession(
        token: 'owner_master_token_${DateTime.now().millisecondsSinceEpoch}',
        agentId: masterOwnerAgentId,
        isOwner: true,
        expiresAt: '23:59:59 Today',
      );
      return AuthResult(
        success: true,
        agentId: masterOwnerAgentId,
        isOwner: true,
        isTrial: false,
        message: 'Master Owner Verified.',
      );
    }

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/login-agent-id');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'agent_id': formatted}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? 'agent_token';
        final isOwner = data['is_owner'] ?? false;
        final assignedId = data['agent_id'] ?? formatted;
        final expiresAt = data['trial_expires_at'] ?? '11:59 PM';

        await _persistSession(
          token: token,
          agentId: assignedId,
          isOwner: isOwner,
          expiresAt: expiresAt,
        );

        return AuthResult(
          success: true,
          agentId: assignedId,
          isOwner: isOwner,
          isTrial: false,
          expiresAt: expiresAt,
          message: 'Agent ID $assignedId verified. Session active until 11:59 PM.',
        );
      } else {
        final data = jsonDecode(response.body);
        return AuthResult(
          success: false,
          message: data['detail'] ?? 'Agent ID not recognized or pending owner approval.',
        );
      }
    } catch (_) {
      // Local fallback if previously approved
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString(_agentIdKey);
      if (lastId == formatted) {
        await _persistSession(
          token: 'cached_token',
          agentId: formatted,
          isOwner: false,
          expiresAt: '11:59 PM Today',
        );
        return AuthResult(
          success: true,
          agentId: formatted,
          isOwner: false,
          isTrial: false,
          message: 'Agent ID verified offline.',
        );
      }
      return AuthResult(
        success: false,
        message: 'Cannot reach backend server. Connect to http://10.189.101.145:8000',
      );
    }
  }

  static Future<void> _persistSession({
    required String token,
    required String agentId,
    required bool isOwner,
    required String expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_agentIdKey, agentId);
    await prefs.setBool(_isOwnerKey, isOwner);
    await prefs.setString(_sessionDateKey, _getTodayString());
    await prefs.setString(_sessionExpiresKey, expiresAt);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_sessionDateKey);
    await prefs.remove(_sessionExpiresKey);
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
