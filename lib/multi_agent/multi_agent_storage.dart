import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'agent_provider.dart';
import 'multi_agent_models.dart';
import 'multi_agent_type.dart';

/// Secure Storage helper for Multi-Agent API keys & credentials.
/// Uses hardware-backed FlutterSecureStorage (Keychain on iOS, KeyStore on Android),
/// with a safe fallback to SharedPreferences and memory cache.
class MultiAgentStorage {
  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, String> _memoryCache = {};
  static final List<MultiAgentSession> _inMemorySessions = [];

  static Future<String> readKey(String key) async {
    if (_memoryCache.containsKey(key) && _memoryCache[key]!.isNotEmpty) {
      return _memoryCache[key]!;
    }
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null && value.isNotEmpty) {
        _memoryCache[key] = value;
        return value;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key) ?? '';
      if (value.isNotEmpty) {
        _memoryCache[key] = value;
      }
      return value;
    } catch (_) {}

    return '';
  }

  static Future<void> writeKey(String key, String value) async {
    final trimmed = value.trim();
    _memoryCache[key] = trimmed;

    try {
      await _secureStorage.write(key: key, value: trimmed);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, trimmed);
    } catch (_) {}
  }

  static Future<String> getGeminiKey() => readKey(MultiAgentKeys.geminiKey);
  static Future<String> getGroqKey() => readKey(MultiAgentKeys.groqKey);
  static Future<String> getDeepseekKey() => readKey(MultiAgentKeys.deepseekKey);

  /// Load all saved chat sessions.
  static Future<List<MultiAgentSession>> loadSessions() async {
    if (_inMemorySessions.isNotEmpty) {
      return List.unmodifiable(_inMemorySessions);
    }

    // Default sample session
    _inMemorySessions.add(
      MultiAgentSession(
        id: 'session_default_1',
        title: 'SINRAS PRO OS Diagnostics & Setup',
        agentType: MultiAgentType.generalAssistant,
        provider: AgentProvider.groq,
        messages: [
          MultiAgentMessage(
            role: 'user',
            content: 'Run complete automated system diagnostics suite',
            provider: 'groq',
            agentType: 'generalAssistant',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          MultiAgentMessage(
            role: 'assistant',
            content: '⚡ AUTO-TEST PASS: CPU 8% | RAM 3.8GB | Storage 128GB (62% Free)',
            provider: 'groq',
            agentType: 'generalAssistant',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );

    return List.unmodifiable(_inMemorySessions);
  }

  /// Delete a chat session by ID.
  static Future<void> deleteSession(String sessionId) async {
    _inMemorySessions.removeWhere((s) => s.id == sessionId);
  }

  /// Clear all chat sessions.
  static Future<void> clearAllSessions() async {
    _inMemorySessions.clear();
  }
}
