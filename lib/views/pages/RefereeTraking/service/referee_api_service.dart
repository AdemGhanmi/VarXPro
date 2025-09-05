// views/pages/RefereeTraking/service/referee_api_service.dart
import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:dio/dio.dart';

class RefereeService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://refereetrackingsystem.varxpro.com',
    connectTimeout: const Duration(seconds: 30), // Increased for connection
    sendTimeout: Duration.zero, // No timeout for sending large files
    receiveTimeout: Duration.zero, // No timeout for receiving
  ));

  RefereeService() {
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
        print('Dio error type: ${e.type}, message: ${e.message}'); // More logging
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
          } catch (ex) {
            print('Retry failed: $ex');
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

  Future<String> getArtifactText(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data as String;
    } catch (e) {
      throw Exception('Failed to fetch artifact text: $e');
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

