import 'package:shared_preferences/shared_preferences.dart';

/// Backend configuration for Synras AI system.
class AppConfig {
  /// Default base URL for physical device / LAN server
  static const String defaultBackendBaseUrl = 'http://10.189.101.145:8000';
  static const String _serverUrlKey = 'custom_server_base_url';

  static String activeBaseUrl = defaultBackendBaseUrl;

  /// Fast synchronous or cached access to active API base URL
  static String get apiBaseUrl => activeBaseUrl;

  /// Get the current backend base URL from persistent storage, or default.
  static Future<String> getBackendBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_serverUrlKey);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      activeBaseUrl = customUrl.trim();
      return activeBaseUrl;
    }
    activeBaseUrl = defaultBackendBaseUrl;
    return defaultBackendBaseUrl;
  }

  /// Update and persist the physical device / LAN server base URL.
  static Future<void> setBackendBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    activeBaseUrl = url.trim();
    await prefs.setString(_serverUrlKey, activeBaseUrl);
  }

  /// Reset to default LAN backend URL.
  static Future<void> resetBackendBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    activeBaseUrl = defaultBackendBaseUrl;
    await prefs.remove(_serverUrlKey);
  }
}
