// views/pages/RefereeTraking/service/referee_api_service.dart
import 'dart:io';
import 'package:VarXPro/views/pages/RefereeTraking/model/referee_analysis.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class RefereeService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://evalrefereemax.varxpro.com',
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

  Future<AnalyzeResponse> analyzeVideo({
    required File video,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'video': await MultipartFile.fromFile(
          video.path,
          filename: 'match.mp4',
        ),
        'players': 'true',
        'goalkeepers': 'true',
        'referees': 'true',
        'ball': 'true',
        'stats': 'true',
        'ref_eval': 'true',
      };
      final formData = FormData.fromMap(formMap);
      final response = await _dio.post('/analyze', data: formData);
      final data = response.data;
      if (data is Map<String, dynamic> && !data['ok']) {
        throw Exception(data['error'] ?? 'Analysis failed');
      }
      return AnalyzeResponse.fromJson(data);
    } catch (e) {
      throw Exception('analysis_failed: $e');
    }
  }

  Future<String> downloadFile(String remotePath) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = remotePath.split('/').last;
      final localPath = '${dir.path}/$fileName';
      await _dio.download(remotePath, localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      return localPath;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}