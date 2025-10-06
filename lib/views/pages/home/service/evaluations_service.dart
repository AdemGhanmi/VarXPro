// lib/views/pages/home/service/evaluations_service.dart (fixed: delete now uses http.delete, improved error parsing for 403/405, better debug logs)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:VarXPro/views/connexion/service/auth_service.dart';

const String baseUrl = 'https://varxpro.com';

class EvaluationsService {
  static Future<Map<String, dynamic>> listEvaluations() async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found - Login again 🔑'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evaluations'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('List evals response: ${response.statusCode} - ${response.body.substring(0, 200)}...'); // Truncated debug

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<dynamic> rawData = [];
        if (jsonData is List) {
          rawData = jsonData;
        } else {
          final paginationData = jsonData['data'] as Map<String, dynamic>? ?? {};
          rawData = paginationData['data'] ?? [];
        }
        final List<Map<String, dynamic>> evaluations = rawData
            .where((item) => item is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
        return {'success': true, 'data': evaluations};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('List evals error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> createEvaluation(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token - Login as supervisor 🔑'};
    }

    if (data['match']?.isEmpty ?? true || data['total_score'] == null) {
      return {'success': false, 'error': 'Match and total score required ⚽⭐'};
    }

    if ((data['external_ref_id'] as String).isEmpty) {
      return {'success': false, 'error': 'External ref ID required 👨‍⚖️'};
    }

    data['external_ref_id'] = data['external_ref_id'].toString();
    if (data['final_score'] != null) {
      data['final_score'] = data['final_score'].toString();
    }

    try {
      print('Creating eval data: $data'); // Debug
      final response = await http.post(
        Uri.parse('$baseUrl/api/evaluations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      print('Create response: ${response.statusCode} - ${response.body.substring(0, 200)}...'); // Truncated

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Validation failed - Check fields (e.g., date format YYYY-MM-DD) ❌',
        };
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Create error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> getEvaluation(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found 🔑'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evaluations/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Get eval response: ${response.statusCode} - ${response.body.substring(0, 200)}...'); // Truncated

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Get eval error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> updateEvaluation(int id, Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found 🔑'};
    }

    try {
      print('Updating eval data: $data'); // Debug
      final response = await http.put(
        Uri.parse('$baseUrl/api/evaluations/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      print('Update response: ${response.statusCode} - ${response.body.substring(0, 200)}...'); // Truncated

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Update error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> deleteEvaluation(int id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found 🔑'};
    }

    try {
      // Fixed: Use http.delete instead of POST spoofing
      final response = await http.delete(
        Uri.parse('$baseUrl/api/evaluations/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Delete response: ${response.statusCode} - ${response.body.substring(0, 200)}...'); // Truncated

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Delete error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> listRefereeEvaluations(String refereeId) async {
    if (refereeId.isEmpty) {
      return {'success': false, 'error': 'Invalid referee ID 👨‍⚖️'};
    }
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token - Login as supervisor 🔑'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/external-referees/$refereeId/evaluations'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Referee evals response: ${response.statusCode} - ${response.body.substring(0, 200)}...'); // Truncated

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<dynamic> rawData = [];
        if (jsonData is List) {
          rawData = jsonData;
        } else {
          final paginationData = jsonData['data'] as Map<String, dynamic>? ?? {};
          rawData = paginationData['data'] ?? [];
        }
        final List<Map<String, dynamic>> evaluations = rawData
            .where((item) => item is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
        print('Parsed evals count: ${evaluations.length}'); // Debug count
        return {'success': true, 'data': evaluations};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Referee evals error: $e');
      return {'success': false, 'error': 'Network error: $e - Check referee ID: $refereeId 🌐'};
    }
  }

  static Map<String, dynamic> _parseErrorResponse(http.Response response) {
    String errorMsg = 'Failed (Status: ${response.statusCode})';
    if (response.statusCode == 403) {
      errorMsg = 'Forbidden - Check permissions or role 🔒';
    } else if (response.statusCode == 405) {
      errorMsg = 'Method not allowed - API may not support this action ❌';
    } else if (response.statusCode == 401) {
      errorMsg = 'Unauthorized - Token expired, login again 🔑';
    }

    try {
      final errorBody = json.decode(response.body);
      errorMsg = errorBody['message'] ?? errorMsg;
    } catch (_) {
      if (response.body.startsWith('<!DOCTYPE html>')) {
        errorMsg = 'Server error - Check API endpoint 🌐';
      } else {
        errorMsg += ': ${response.body.substring(0, 100)}...';
      }
    }
    return {'success': false, 'error': errorMsg};
  }
}