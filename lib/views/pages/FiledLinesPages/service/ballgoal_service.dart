// lib/views/pages/BallGoalPage/service/ballgoal_service.dart
import 'dart:io';
import 'package:VarXPro/views/pages/FiledLinesPages/model/ballgoal_model.dart';
import 'package:dio/dio.dart';

class BallGoalService {
  static const String defaultBaseUrl = 'https://allvarx.varxpro.com';
  final Dio _dio;
  BallGoalService({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status < 500,
        )) {
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }
 
  Future<BallInOutResponse> ballInOut(File image) async {
    try {
      final formData = FormData.fromMap({
        'mock': '1',
        'attack': 'left',
        'image': await MultipartFile.fromFile(image.path, filename: 'frame.jpg'),
      });
      final response = await _dio.post(
        '/api/ball/inout/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return BallInOutResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'ball in/out');
    }
  }
  Future<GoalCheckResponse> goalCheck(File image) async {
    try {
      final formData = FormData.fromMap({
        'mock': '1',
        'attack': 'left',
        'image': await MultipartFile.fromFile(image.path, filename: 'frame.jpg'),
      });
      final response = await _dio.post(
        '/api/goal/check/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return GoalCheckResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleDioError(e, 'goal check');
    }
  }
  Exception _handleDioError(dynamic e, String operation) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Exception('Connection timeout during $operation. Please try again.');
      } else if (e.response?.statusCode == 400) {
        final data = e.response?.data as Map<String, dynamic>?;
        return Exception('Bad request during $operation: ${data?['error'] ?? 'Invalid input'}');
      } else if (e.response?.statusCode == 500) {
        final data = e.response?.data as Map<String, dynamic>?;
        return Exception('Server error during $operation: ${data?['error'] ?? 'Internal server error'}');
      } else if (e.type == DioExceptionType.connectionError) {
        return Exception('Network error during $operation. Please check your connection.');
      }
    }
    return Exception('Failed to $operation: ${e.toString()}');
  }
}