import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:dio/dio.dart';

class RefereeService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.18:8000', // Update to your backend IP
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
  ));

  RefereeService() {
    // Add interceptors for logging and retry
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          // Retry once on timeout
          try {
            final response = await _dio.request(
              e.requestOptions.path,
              data: e.requestOptions.data,
              queryParameters: e.requestOptions.queryParameters,
              options: Options(
                method: e.requestOptions.method,
                headers: e.requestOptions.headers,
              ),
            );
            return handler.resolve(response);
          } catch (_) {
            return handler.next(e);
          }
        }
        return handler.next(e);
      },
    ));
  }

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
        'video': await MultipartFile.fromFile(
          video.path,
          filename: 'video.mp4',
        ),
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