// views/pages/RefereeTraking/service/referee_api_service.dart
import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:dio/dio.dart';

class RefereeService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://allvarx.varxpro.com',
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: Duration.zero,
    receiveTimeout: Duration.zero,
  ));

  RefereeService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response: ${response.statusCode}');
        print('Response data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        print('Dio error type: ${e.type}, message: ${e.message}');
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
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
    String attack = 'left',
    String attacking_team = 'team1',
    File? refLog,
    String? decisionsJson,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'video': await MultipartFile.fromFile(
          video.path,
          filename: 'match.mp4',
        ),
        'attack': attack,
        'attacking_team': attacking_team,
      };
      if (refLog != null) {
        formMap['ref_log'] = await MultipartFile.fromFile(
          refLog.path,
          filename: 'referee_log.json',
        );
      }
      if (decisionsJson != null) {
        formMap['decisions_json'] = decisionsJson;
      }
      final formData = FormData.fromMap(formMap);
      final response = await _dio.post('/api/decision/auto/video', data: formData);
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        throw Exception(data['error']);
      }
      return AnalyzeResponse.fromJson(data);
    } catch (e) {
      throw Exception('analysis_failed: $e');
    }
  }
}