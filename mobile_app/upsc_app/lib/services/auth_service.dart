import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';

class AuthService {
  final String baseUrl = AppConfig.apiUrl;

  String _getAuthUrl() => baseUrl.endsWith('/auth') ? baseUrl : '$baseUrl/auth';
  String _getOnboardingUrl() => baseUrl.endsWith('/auth')
      ? baseUrl.replaceAll('/auth', '/onboarding')
      : '$baseUrl/onboarding';

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_getAuthUrl()}/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('refresh_token', refreshToken);
        
        // Fetch profile immediately to get and save user_id
        await getProfile(); 
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRefreshToken = prefs.getString('refresh_token');
      if (currentRefreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${_getAuthUrl()}/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': currentRefreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('jwt_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        return true;
      }
      // If refresh fails, user needs to login again
      await logout();
      return false;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      return false;
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_getAuthUrl()}/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'daily_study_hours': 6
        }),
      ).timeout(const Duration(seconds: 90));
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      // Extract backend error message
      try {
        final data = jsonDecode(response.body);
        return data['detail'] ?? 'Signup failed (${response.statusCode})';
      } catch (_) {
        return 'Signup failed (${response.statusCode})';
      }
    } on Exception catch (e) {
      debugPrint('Signup error: $e');
      if (e.toString().contains('TimeoutException')) {
        return 'Connection timed out. Server is warming up — please try again in 10 seconds.';
      }
      return 'Connection error. Check your internet and try again.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('${_getAuthUrl()}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        if (data['id'] != null) {
          await prefs.setInt('user_id', data['id']);
        }
        return data;
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    }
    return null;
  }

  Future<bool> updateProfile({int? hours, String? name, int? targetYear, List<String>? weakSubjects}) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final Map<String, dynamic> body = {};
      if (hours != null) body['daily_study_hours'] = hours;
      if (name != null) body['name'] = name;
      if (targetYear != null) body['target_year'] = targetYear;
      if (weakSubjects != null) body['weak_subjects'] = weakSubjects;

      final response = await http.put(
        Uri.parse('${_getAuthUrl()}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<bool> completeOnboarding(Map<String, dynamic> payload) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${_getOnboardingUrl()}/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Onboarding complete error: $e');
      return false;
    }
  }

  Future<bool> setupUser(Map<String, dynamic> payload) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${_getOnboardingUrl()}/setup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('User setup error: $e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  Future<bool> clearData() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/clear_data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Clear data error: $e');
      return false;
    }
  }
}


