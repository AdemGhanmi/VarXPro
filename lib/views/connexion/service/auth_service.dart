// lib/views/connexion/service/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://varxpro.com';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role, // Can be 'user', 'supervisor'
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
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendEmailOtp({
    required String email,
  }) async {
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
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Failed to send OTP',
        };
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
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Verification failed',
        };
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

      print('Login response: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user_role', data['user']['role'] ?? 'visitor'); // Store role
          return {'success': true, 'data': data};
        }
      } else {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: $e'); // Debug
      return {'success': false, 'error': 'Network error: $e'};
    }
    return {'success': false, 'error': 'Unknown error'};
  }

  static Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      return {'success': false, 'error': 'No token found'};
    }

    try {
      print('Logout with token: $token'); // Debug
      final response = await http.post(
        Uri.parse('$baseUrl/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await prefs.remove('token');
      await prefs.remove('user_role'); // Clean role too

      print('Logout response: ${response.statusCode} - ${response.body}'); // Debug

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      await prefs.remove('token');
      await prefs.remove('user_role');
      print('Logout error: $e'); // Debug
      return {'success': true, 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> sendForgotPasswordOtp({
    required String email,
  }) async {
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
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Failed to send OTP',
        };
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
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Reset failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Failed to fetch user profile',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'visitor';
  }
}
