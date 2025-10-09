// lib/views/pages/home/service/evaluations_service.dart (Fixed with lang params)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:VarXPro/views/connexion/service/auth_service.dart';

const String baseUrl = 'https://varxpro.com';

class EvaluationsService {
  static String _truncate(String str, int maxLen) {
    if (str.length <= maxLen) return str;
    return str.substring(0, maxLen) + '...';
  }

  static Future<Map<String, dynamic>> fetchMeta(String lang) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found - Login again 🔑'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/evaluations/meta?lang=$lang'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Meta response: ${response.statusCode} - ${_truncate(response.body, 200)}'); // Safe truncate

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Meta error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

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

      print('List evals response: ${response.statusCode} - ${_truncate(response.body, 200)}'); // Safe truncate

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

      print('Create response: ${response.statusCode} - ${_truncate(response.body, 200)}'); // Safe truncate

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Unwrap the 'data' wrapper if present
        final createData = jsonData['data'] ?? (jsonData is Map<String, dynamic> ? jsonData : {});
        return {'success': true, 'data': createData};
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        final allowedTypes = errorBody['allowed_types'] ?? [];
        String errorMsg = errorBody['message'] ?? 'Validation failed - Check fields (e.g., date format YYYY-MM-DD) ❌';
        if (allowedTypes.isNotEmpty) {
          errorMsg += ' Allowed types: ${allowedTypes.join(', ')}';
        }
        return {
          'success': false,
          'error': errorMsg,
        };
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Create error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> getEvaluation(String id, String lang) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found 🔑'};
    }

    try {
      final uri = Uri.parse('$baseUrl/api/evaluations/$id?lang=$lang');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Get eval response: ${response.statusCode} - ${_truncate(response.body, 200)}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final evalData = jsonData['data'] ?? (jsonData is Map<String, dynamic> ? jsonData : {});
        return {'success': true, 'data': evalData};
      } else {
        return _parseErrorResponse(response);
      }
    } catch (e) {
      print('Get eval error: $e');
      return {'success': false, 'error': 'Network error: $e 🌐'};
    }
  }

  static Future<Map<String, dynamic>> updateEvaluation(int id, Map<String, dynamic> data, String lang) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token found 🔑'};
    }

    try {
      print('Updating eval data: $data'); // Debug
      final response = await http.put(
        Uri.parse('$baseUrl/api/evaluations/$id?lang=$lang'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      print('Update response: ${response.statusCode} - ${_truncate(response.body, 200)}'); // Safe truncate

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Unwrap the 'data' wrapper if present
        final updateData = jsonData['data'] ?? (jsonData is Map<String, dynamic> ? jsonData : {});
        return {'success': true, 'data': updateData};
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
      print('Deleting eval ID: $id'); // Added debug
      final response = await http.delete(
        Uri.parse('$baseUrl/api/evaluations/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Delete response: ${response.statusCode} - ${_truncate(response.body, 200)}'); // Safe truncate

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

  static Future<Map<String, dynamic>> listRefereeEvaluations(String refereeId, String lang) async {
    if (refereeId.isEmpty) {
      return {'success': false, 'error': 'Invalid referee ID 👨‍⚖️'};
    }
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'No token - Login as supervisor 🔑'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/external-referees/$refereeId/evaluations?lang=$lang'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Referee evals response: ${response.statusCode} - ${_truncate(response.body, 200)}'); // Safe truncate

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
        errorMsg += ': ${_truncate(response.body, 100)}'; // Safe truncate, no extra ...
      }
    }
    return {'success': false, 'error': errorMsg};
  }
}