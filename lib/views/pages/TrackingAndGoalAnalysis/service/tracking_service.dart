// lib/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/model/analysis_result.dart'; // Assuming this is the model file

class TrackingService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.18:8002')); // Update IP if needed

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
    double? detectionConfidence,
    bool? showTrails,
    bool? showSkeleton,
    bool? showBoxes,
    bool? showIds,
    int? trailLength,
    List<int>? goalLeft,
    List<int>? goalRight,
  }) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path, filename: 'video.mp4'),
        if (detectionConfidence != null) 'detection_confidence': detectionConfidence,
        if (showTrails != null) 'show_trails': showTrails ? '1' : '0',
        if (showSkeleton != null) 'show_skeleton': showSkeleton ? '1' : '0',
        if (showBoxes != null) 'show_boxes': showBoxes ? '1' : '0',
        if (showIds != null) 'show_ids': showIds ? '1' : '0',
        if (trailLength != null) 'trail_length': trailLength,
        if (goalLeft != null) ...{
          'goal_left_x': goalLeft[0],
          'goal_left_y': goalLeft[1],
        },
        if (goalRight != null) ...{
          'goal_right_x': goalRight[0],
          'goal_right_y': goalRight[1],
        },
      });
      final response = await _dio.post('/analyze', data: formData);
      return AnalyzeResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to analyze video: $e');
    }
  }

  Future<CleanResponse> cleanArtifacts() async {
    try {
      final response = await _dio.post('/clean');
      return CleanResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to clean artifacts: $e');
    }
  }
}
