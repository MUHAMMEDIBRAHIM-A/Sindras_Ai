import 'dart:convert';
import 'api_client.dart';

/// Authentication service for register/login with the backend.
class AuthService {
  /// Register a new account. Returns null on success, error string on failure.
  static Future<String?> register(String email, String password) async {
    try {
      final response = await ApiClient.post(
        '/auth/register',
        body: {'email': email, 'password': password},
        auth: false,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['detail'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Login with existing account. Returns null on success, error string on failure.
  static Future<String?> login(String email, String password) async {
    try {
      final response = await ApiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
        auth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        return data['detail'] ?? 'Login failed';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Logout: clear stored token.
  static Future<void> logout() async {
    await ApiClient.clearToken();
  }

  /// Check if user is currently logged in.
  static Future<bool> isLoggedIn() async {
    return ApiClient.hasToken();
  }
}
