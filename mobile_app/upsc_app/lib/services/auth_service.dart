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
  String _getScheduleUrl() => baseUrl.endsWith('/auth')
      ? baseUrl.replaceAll('/auth', '/schedule')
      : '$baseUrl/schedule';

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_getAuthUrl()}/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );
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

  Future<bool> signup(String name, String email, String password) async {
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
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Signup error: $e');
      return false;
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
      );
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
      );

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
      );

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
      );

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


