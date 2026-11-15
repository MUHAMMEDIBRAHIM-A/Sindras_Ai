import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

/// Centralized HTTP client that auto-injects JWT tokens into every request.
class ApiClient {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Build headers with optional JWT authorization.
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// GET request.
  static Future<http.Response> get(String path, {bool auth = true}) async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final headers = await _headers(auth: auth);
    return http.get(url, headers: headers);
  }

  /// POST request with JSON body.
  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final headers = await _headers(auth: auth);
    return http.post(url, headers: headers, body: jsonEncode(body));
  }

  /// DELETE request.
  static Future<http.Response> delete(String path, {bool auth = true}) async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final headers = await _headers(auth: auth);
    return http.delete(url, headers: headers);
  }

  /// Multipart file upload with auth.
  static Future<http.StreamedResponse> uploadFile(
    String path,
    String filePath,
    String fieldName, {
    String? filename,
  }) async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final request = http.MultipartRequest('POST', url);

    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(fieldName, filePath, filename: filename),
    );

    return request.send();
  }
}
