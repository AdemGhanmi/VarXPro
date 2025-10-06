// lib/views/connexion/service/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://varxpro.com';

class AuthService {
  /* ======================= Local Cache Helpers ======================= */

  static const _kToken = 'token';
  static const _kUserRole = 'user_role';
  static const _kUserJson = 'user_json';

  static Future<void> _cacheToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
  }

  static Future<void> _cacheRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserRole, role);
  }

  static Future<void> cacheUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserJson, json.encode(user));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserJson);
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserRole);
    await prefs.remove(_kUserJson);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserRole) ?? 'visitor';
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken) != null;
  }

  /* ======================= API Calls ======================= */

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role, // 'user' or 'supervisor'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendEmailOtp({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/email/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/email/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Verification failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      // Debug
      // print('Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final token = data['token'] as String?;
        final user = (data['user'] ?? {}) as Map<String, dynamic>;
        final role = (user['role'] ?? 'visitor') as String;

        if (token != null) {
          await _cacheToken(token);
          await _cacheRole(role);
          await cacheUser(user); // <<<<<< cache full user (name/email/role/id)
          return {'success': true, 'data': data};
        }
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Login failed'};
      }
    } catch (e) {
      // print('Login error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
    return {'success': false, 'error': 'Unknown error'};
  }

  static Future<Map<String, dynamic>> logout() async {
    final token = await getToken();
    if (token == null) {
      await clearCache();
      return {'success': true, 'data': {}};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await clearCache();

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Logout failed'};
      }
    } catch (e) {
      await clearCache();
      return {'success': true, 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> sendForgotPasswordOtp({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password/forgot/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/password/forgot/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Reset failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'error': 'No token found'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // keep cache in sync with server
        await cacheUser(data);
        await _cacheRole((data['role'] ?? 'visitor') as String);
        return {'success': true, 'data': data};
      } else {
        final errorBody = json.decode(response.body);
        return {'success': false, 'error': errorBody['message'] ?? 'Failed to fetch user profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
