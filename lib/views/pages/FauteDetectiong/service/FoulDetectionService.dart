import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../model/foul_detection.dart';

class FoulDetectionService {
  static const String _host = 'https://offsidev4.varxpro.com';
  static const String _baseApi = '$_host/api';

  Future<Map<String, dynamic>> ping() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseApi/health'))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> getVersion() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseApi/version'))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to get version: $e');
    }
  }

  Future<AnalysisResult> analyzeVideo({
    File? videoFile,
    String? videoPath,
    String? refereeDecision,
  }) async {
    if (videoFile == null && videoPath == null) {
      throw Exception('Either videoFile or videoPath must be provided');
    }

    try {
      if (videoFile != null) {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseApi/analyze'))
          ..files.add(await http.MultipartFile.fromPath('video', videoFile.path!));
        if (refereeDecision != null && refereeDecision.isNotEmpty) {
          request.fields['referee_decision'] = refereeDecision;
        }

        final streamed = await request.send().timeout(const Duration(minutes: 10));
        final response = await http.Response.fromStream(streamed);
        return AnalysisResult.fromJson(_handleResponse(response));
      } else {
        // Fallback for path-based, but new API doesn't support; throw or adapt
        throw Exception('Path-based analysis not supported in new API');
      }
    } catch (e) {
      throw Exception('Analysis request failed: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed: ${response.statusCode} - ${response.body}');
  }
}