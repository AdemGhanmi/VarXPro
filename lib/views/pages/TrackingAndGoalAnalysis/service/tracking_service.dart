// lib/views/pages/TrackingAndGoalAnalysis/service/tracking_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:VarXPro/views/pages/TrackingAndGoalAnalysis/model/analysis_result.dart'; 

class TrackingService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://tracking.varxpro.com')); 

  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return HealthResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Debug Error in checkHealth: $e');
      debugPrint('Debug StackTrace: ${StackTrace.current}');
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
    bool? offsideEnabled,
    String? attackDirection,
    String? attackingTeam,
    List<int>? lineStart,
    List<int>? lineEnd,
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
        if (offsideEnabled == true) 'offside_enabled': '1',
        if (attackDirection != null) 'attack_direction': attackDirection,
        if (attackingTeam != null) 'attacking_team': attackingTeam,
        if (lineStart != null) ...{
          'line_start_x': lineStart[0],
          'line_start_y': lineStart[1],
        },
        if (lineEnd != null) ...{
          'line_end_x': lineEnd[0],
          'line_end_y': lineEnd[1],
        },
      });
      final response = await _dio.post('/analyze', data: formData);
      return AnalyzeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Debug Error in analyzeVideo: $e');
      debugPrint('Debug StackTrace: ${StackTrace.current}');
      throw Exception('Failed to analyze video: $e');
    }
  }

  Future<CleanResponse> cleanArtifacts() async {
    try {
      final response = await _dio.post('/clean');
      return CleanResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Debug Error in cleanArtifacts: $e');
      debugPrint('Debug StackTrace: ${StackTrace.current}');
      throw Exception('Failed to clean artifacts: $e');
    }
  }
}