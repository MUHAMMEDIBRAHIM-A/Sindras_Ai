import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'multi_agent_models.dart';

/// Secure Storage helper for Multi-Agent API keys & credentials.
/// Uses hardware-backed FlutterSecureStorage (Keychain on iOS, KeyStore on Android),
/// with a safe fallback to SharedPreferences and memory cache.
class MultiAgentStorage {
  static const _secureStorage = FlutterSecureStorage();
  static final Map<String, String> _memoryCache = {};

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
}
