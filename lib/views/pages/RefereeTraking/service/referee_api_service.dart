// lib/services/referee_service.dart
import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:dio/dio.dart';

class RefereeService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.18:8000')); // Update IP if needed

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to check health: $e');
    }
  }

  Future<AnalyzeResponse> analyzeVideo({
    required File video,
    double confThreshold = 0.3,
  }) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path, filename: 'video.mp4'),
        'conf_threshold': confThreshold,
      });
      final response = await _dio.post('/analyze', data: formData);
      return AnalyzeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to analyze video: $e');
    }
  }

  Future<CleanResponse> clean() async {
    try {
      final response = await _dio.post('/clean');
      return CleanResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to clean files: $e');
    }
  }
}