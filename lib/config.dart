import 'package:shared_preferences/shared_preferences.dart';

/// Backend configuration for Synras AI system.
class AppConfig {
  /// Default base URL for Android emulator
  static const String defaultBackendBaseUrl = 'http://10.0.2.2:8000';
  static const String _serverUrlKey = 'custom_server_base_url';

  /// Get the current backend base URL from persistent storage, or default.
  static Future<String> getBackendBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_serverUrlKey);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    return defaultBackendBaseUrl;
  }

  /// Update and persist the physical device / LAN server base URL.
  static Future<void> setBackendBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trim());
  }

  /// Reset to default emulator backend URL.
  static Future<void> resetBackendBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverUrlKey);
  }
}
