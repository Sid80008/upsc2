import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _handleResponse(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    
    if (response.statusCode == 401) {
      // Attempt refresh
      final authService = AuthService();
      final success = await authService.refreshToken();
      if (success) {
        // Retry original request with new token
        return await request();
      }
    }
    return response;
  }

  static Future<http.Response> get(String endpoint) async {
    return await _handleResponse(() async {
      final headers = await _getHeaders();
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    });
  }

  static Future<http.Response> post(String endpoint, dynamic body) async {
    return await _handleResponse(() async {
      final headers = await _getHeaders();
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> patch(String endpoint, dynamic body) async {
    return await _handleResponse(() async {
      final headers = await _getHeaders();
      return await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }
}